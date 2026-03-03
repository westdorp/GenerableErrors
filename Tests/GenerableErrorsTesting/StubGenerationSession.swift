import GenerableErrors
import Synchronization

/// Configurable test double for ``GenerationSession``.
///
/// Tracks method calls and queues responses for assertion.
///
/// ```swift
/// let stub = StubGenerationSession()
/// stub.availability = .available
/// stub.streamToReturn = .immediate(values: [snapshot])
///
/// let stream = stub.generate(for: myError, style: .snarky)
/// #expect(stub.generateCallCount == 1)
/// ```
///
/// Use ``onGenerate`` to inspect the error and style passed to each call:
///
/// ```swift
/// stub.onGenerate = { error, style in
///     #expect(error.code == "404")
/// }
/// ```
public final class StubGenerationSession: GenerationSession, Sendable {
    private let state: Mutex<State>

    struct State: Sendable {
        var generateCallCount: Int = 0
        var availability: ModelAvailability
        var streamToReturn: GenerationStream
        var queuedStreams: [GenerationStream] = []
        var onGenerate: (@Sendable (_ error: any ErrorDescriptor, _ style: any ErrorStyle) -> Void)?
    }

    public init(
        availability: ModelAvailability = .available,
        streamToReturn: GenerationStream = .immediate(values: [])
    ) {
        self.state = Mutex(State(
            availability: availability,
            streamToReturn: streamToReturn
        ))
    }

    public var generateCallCount: Int {
        state.withLock { $0.generateCallCount }
    }

    public var availability: ModelAvailability {
        get { state.withLock { $0.availability } }
        set { state.withLock { $0.availability = newValue } }
    }

    public var streamToReturn: GenerationStream {
        get { state.withLock { $0.streamToReturn } }
        set { state.withLock { $0.streamToReturn = newValue } }
    }

    public var queuedStreams: [GenerationStream] {
        get { state.withLock { $0.queuedStreams } }
        set { state.withLock { $0.queuedStreams = newValue } }
    }

    /// Called on each ``generate(for:style:)`` invocation with the error and style.
    /// Use this to inspect or record the inputs passed by the consumer.
    public var onGenerate: (@Sendable (_ error: any ErrorDescriptor, _ style: any ErrorStyle) -> Void)? {
        get { state.withLock { $0.onGenerate } }
        set { state.withLock { $0.onGenerate = newValue } }
    }

    // MARK: - GenerationSession

    public func generate<E: ErrorDescriptor, S: ErrorStyle>(
        for error: E,
        style: S
    ) -> GenerationStream {
        let (onGenerate, stream): (
            (@Sendable (_ error: any ErrorDescriptor, _ style: any ErrorStyle) -> Void)?,
            GenerationStream
        ) = state.withLock { state in
            state.generateCallCount += 1
            let stream: GenerationStream
            if !state.queuedStreams.isEmpty {
                stream = state.queuedStreams.removeFirst()
            } else {
                stream = state.streamToReturn
            }
            return (state.onGenerate, stream)
        }

        // Invoke callbacks outside the critical section to avoid re-entrant locking.
        onGenerate?(error, style)
        return stream
    }
}

@available(*, deprecated, renamed: "GenerationStream")
public typealias SnapshotStream = GenerationStream

extension GenerationStream {
    /// Creates a stream that immediately yields all values and finishes.
    public static func immediate(values: [GeneratedSnapshot]) -> Self {
        Self { continuation in
            for value in values {
                continuation.yield(value)
            }
            continuation.finish()
        }
    }

    /// Creates a stream that immediately finishes with a generation error.
    public static func immediateFailure(_ error: GenerationError) -> Self {
        Self { continuation in
            continuation.finish(throwing: error)
        }
    }

    /// Creates a stream with an exposed continuation for manual control.
    public static func controlled() -> (stream: Self, continuation: Self.Continuation) {
        var capturedContinuation: Self.Continuation?
        let stream = Self { continuation in
            capturedContinuation = continuation
        }
        guard let continuation = capturedContinuation else {
            preconditionFailure("Failed to create AsyncThrowingStream continuation")
        }
        return (stream, continuation)
    }

    /// Creates a controlled stream with a termination signal for observing cancellation.
    public static func controlledWithTermination() -> (
        stream: Self,
        continuation: Self.Continuation,
        terminationSignal: StreamTerminationSignal
    ) {
        let terminationSignal = StreamTerminationSignal()
        var capturedContinuation: Self.Continuation?
        let stream = Self { continuation in
            continuation.onTermination = { _ in
                Task {
                    await terminationSignal.markTerminated()
                }
            }
            capturedContinuation = continuation
        }
        guard let continuation = capturedContinuation else {
            preconditionFailure("Failed to create AsyncThrowingStream continuation")
        }
        return (stream, continuation, terminationSignal)
    }
}

/// Observable signal for stream termination in tests.
public actor StreamTerminationSignal {
    private var terminated = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init() {}

    public func wait() async {
        if terminated {
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    public func markTerminated() {
        guard !terminated else { return }
        terminated = true
        let continuations = waiters
        waiters.removeAll()
        continuations.forEach { $0.resume() }
    }
}
