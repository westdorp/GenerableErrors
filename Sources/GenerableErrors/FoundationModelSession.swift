import FoundationModels
import Synchronization

/// Generation session backed by on-device Foundation Models.
public final class FoundationModelSession: GenerationSession, Sendable {
    private let model = SystemLanguageModel.default
    private let requestBuilder: RequestBuilder
    private let prewarmedSession: Mutex<LanguageModelSession?> = Mutex(nil)

    public init() {
        self.requestBuilder = .default
    }

    public var availability: ModelAvailability {
        ErrorMapper.mapAvailability(model.availability)
    }

    /// Not on the ``GenerationSession`` protocol — prewarming is an
    /// implementation detail. Call on the concrete type at app launch.
    public func prewarmModel() {
        guard availability.isAvailable else {
            prewarmedSession.withLock { $0 = nil }
            return
        }

        let session = LanguageModelSession(instructions: requestBuilder.instructions)
        session.prewarm()
        prewarmedSession.withLock { $0 = session }
    }

    public func generate<E: ErrorDescriptor, S: ErrorStyle>(
        for error: E,
        style: S
    ) -> GenerationStream {
        if case .unavailable(let reason) = availability {
            return GenerationStream { continuation in
                continuation.finish(throwing: GenerationError.unavailable(reason))
            }
        }

        let request: GenerationRequest
        do {
            request = try requestBuilder.makeRequest(for: error, style: style)
        } catch let generationError {
            return GenerationStream { continuation in
                continuation.finish(throwing: generationError)
            }
        }

        return streamForAvailableModel(request: request)
    }

    private func streamForAvailableModel(
        request: GenerationRequest
    ) -> GenerationStream {
        GenerationStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let session = self.prewarmedSession.withLock { prewarmed in
                if let session = prewarmed {
                    prewarmed = nil
                    return session
                }
                return LanguageModelSession(instructions: request.instructions)
            }
            let options = GenerationOptions(temperature: request.temperature)
            let responseStream = session.streamResponse(
                to: request.prompt,
                generating: GeneratedError.self,
                options: options
            )

            // Use a detached task so stream consumption doesn't inherit caller
            // actor isolation (often MainActor from SwiftUI view models).
            // Cancellation is still structured through continuation termination.
            let task = Task.detached(priority: Task.currentPriority) {
                do {
                    for try await partialResponse in responseStream {
                        if let snapshot = GeneratedSnapshot(partial: partialResponse.content) {
                            continuation.yield(snapshot)
                        }
                    }
                    continuation.finish()
                } catch let generationError as LanguageModelSession.GenerationError {
                    let mapped = ErrorMapper.mapGenerationError(generationError)
                    continuation.finish(throwing: mapped)
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    let mapped = ErrorMapper.mapError(error)
                    continuation.finish(throwing: mapped)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
