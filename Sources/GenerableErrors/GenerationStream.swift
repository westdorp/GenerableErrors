/// Stream returned by ``GenerationSession/generate(for:style:)``.
///
/// Internally wraps `AsyncThrowingStream` but normalizes all failures to
/// ``GenerationError`` values at iteration boundaries. Cancellation is treated
/// as stream termination.
public struct GenerationStream: AsyncSequence, Sendable {
    public typealias Element = GeneratedSnapshot
    public typealias Continuation = AsyncThrowingStream<Element, any Error>.Continuation

    private let base: AsyncThrowingStream<Element, any Error>

    /// Creates a stream backed by `AsyncThrowingStream` using unbounded
    /// buffering.
    public init(_ build: @escaping (Continuation) -> Void) {
        self.init(bufferingPolicy: .unbounded, build)
    }

    /// Creates a stream backed by `AsyncThrowingStream`.
    ///
    /// - Parameters:
    ///   - bufferingPolicy: Backpressure policy for enqueued snapshots.
    ///   - build: Continuation builder closure.
    public init(
        bufferingPolicy: Continuation.BufferingPolicy,
        _ build: @escaping (Continuation) -> Void
    ) {
        self.base = AsyncThrowingStream(
            Element.self,
            bufferingPolicy: bufferingPolicy,
            build
        )
    }

    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<Element, any Error>.Iterator

        fileprivate init(
            iterator: AsyncThrowingStream<Element, any Error>.Iterator
        ) {
            self.iterator = iterator
        }

        public mutating func next() async throws -> Element? {
            do {
                return try await iterator.next()
            } catch let generationError as GenerationError {
                throw generationError
            } catch let availabilityError as AvailabilityError {
                throw GenerationError.unavailable(availabilityError)
            } catch is CancellationError {
                return nil
            } catch {
                throw GenerationError.unknown
            }
        }
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(iterator: base.makeAsyncIterator())
    }
}
