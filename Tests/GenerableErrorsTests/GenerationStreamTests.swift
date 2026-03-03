import Testing
@testable import GenerableErrors

@Suite("GenerationStream")
struct GenerationStreamTests {

    @Test("cancellation is treated as stream completion")
    func cancellationCompletesStream() async throws {
        let stream = GenerationStream { continuation in
            continuation.finish(throwing: CancellationError())
        }
        var iterator = stream.makeAsyncIterator()

        let next = try await iterator.next()

        #expect(next == nil)
    }

    @Test("unknown errors map to GenerationError.unknown")
    func unknownErrorsMapToUnknown() async {
        enum TestError: Error {
            case boom
        }

        let stream = GenerationStream { continuation in
            continuation.finish(throwing: TestError.boom)
        }
        var iterator = stream.makeAsyncIterator()

        await #expect(throws: GenerationError.unknown) {
            _ = try await iterator.next()
        }
    }
}
