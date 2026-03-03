import CuratedStyles
import Foundation
import GenerableErrors
import GenerableErrorsTesting
import Testing
@testable import GenerableErrorsApp

private final class WeakReference<Object: AnyObject> {
    weak var value: Object?

    init(_ value: Object?) {
        self.value = value
    }
}

@MainActor
@Suite("ErrorGeneratorViewModel")
struct ErrorGeneratorViewModelTests {

    @Test("refreshing model availability updates generate eligibility")
    func refreshingModelAvailabilityUpdatesGenerateEligibility() async throws {
        let service = StubGenerationSession()
        try await withSUT(service: service) { viewModel, service in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)
            #expect(viewModel.canGenerate)

            service.availability = .unavailable(.modelNotReady)
            viewModel.refreshModelAvailability()

            #expect(viewModel.modelAvailability == .unavailable(.modelNotReady))
            #expect(viewModel.modelAvailability.unavailabilityMessage?.contains("still preparing") == true)
            #expect(!viewModel.canGenerate)
        }
    }

    @Test("monitoring availability polls with injected clock")
    func monitorModelAvailabilityUsesInjectedClock() async throws {
        let service = StubGenerationSession()
        service.availability = .unavailable(.modelNotReady)

        var sleepCount = 0
        let clock = TestAvailabilityMonitorClock(
            outcomes: [.success(()), .failure(.cancelled)],
            onSleep: {
                if sleepCount == 0 {
                    service.availability = .available
                }
                sleepCount += 1
            }
        )

        try await withSUT(service: service, availabilityMonitorClock: clock) { viewModel, _ in
            await viewModel.monitorModelAvailability()
            #expect(viewModel.modelAvailability == .available)
            #expect(sleepCount == 2)
        }
    }

    @Test("generate without selecting an error is a no-op")
    func generateWithoutSelectedErrorDoesNothing() async throws {
        try await withSUT { viewModel, service in
            await viewModel.generate().value
            #expect(service.generateCallCount == 0)
            #expect(viewModel.generationState == .idle(style: .snarky))
        }
    }

    @Test(
        "generation is blocked when model is unavailable",
        arguments: [
            (AvailabilityError.appleIntelligenceNotEnabled, "Apple Intelligence and Siri are turned off"),
            (AvailabilityError.modelNotReady, "model is still preparing"),
            (AvailabilityError.assetsUnavailable, "assets aren't available"),
        ]
    )
    func generateWhenModelIsUnavailable(
        unavailableError: AvailabilityError,
        expectedMessageFragment: String
    ) async throws {
        let service = StubGenerationSession()
        service.availability = .unavailable(unavailableError)
        try await withSUT(service: service) { viewModel, service in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)

            #expect(!viewModel.canGenerate)
            await viewModel.generate().value

            #expect(service.generateCallCount == 0)
            let failure = try #require(viewModel.generationState.errorFailure)
            #expect(failure.error == .unavailable(unavailableError))
            #expect(failure.selection.error == notFound)
            #expect(failure.selection.style == .snarky)
            let message = failure.error.localizedDescription
            #expect(message.contains(expectedMessageFragment))
        }
    }

    @Test("successful generation streams snapshots and finishes generated")
    func generateStreamsAndCompletes() async throws {
        let service = StubGenerationSession()
        service.streamToReturn = .immediate(values: [
            generatedSnapshot(meaning: "Resource missing", message: nil),
            generatedSnapshot(
                meaning: "Resource missing",
                message: "The page wandered off into the fog."
            ),
        ])
        try await withSUT(service: service) { viewModel, service in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)
            viewModel.selectStyle(.haiku)
            await viewModel.generate().value

            #expect(service.generateCallCount == 1)
            #expect(viewModel.currentResult?.message == "The page wandered off into the fog.")
        }
    }

    @Test(
        "service errors map to user-friendly messages",
        arguments: [
            (GenerationError.guardrailViolation, "safety filters blocked"),
            (GenerationError.rateLimited, "generation limit"),
            (GenerationError.concurrentRequests, "Too many generations"),
            (GenerationError.unavailable(.assetsUnavailable), "assets aren't available"),
        ]
    )
    func serviceErrorsMapToFriendlyMessages(
        serviceError: GenerationError,
        expectedMessageFragment: String
    ) async throws {
        let service = StubGenerationSession()
        service.streamToReturn = .immediateFailure(serviceError)
        try await withSUT(service: service) { viewModel, _ in
            let forbidden = try httpError(403)
            viewModel.selectError(forbidden)
            await viewModel.generate().value

            let failure = try #require(viewModel.generationState.errorFailure)
            #expect(failure.error == serviceError)
            #expect(failure.selection.error == forbidden)
            let message = failure.error.localizedDescription
            #expect(message.contains(expectedMessageFragment))
        }
    }

    @Test("reset cancels in-flight generation without stale updates")
    func resetCancelsInFlightGenerationWithoutStaleUpdates() async throws {
        let service = StubGenerationSession()
        let controlled = GenerationStream.controlled()
        service.streamToReturn = controlled.stream
        try await withSUT(service: service) { viewModel, _ in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)
            let generationTask = viewModel.generate()

            viewModel.reset()
            controlled.continuation.yield(
                generatedSnapshot(meaning: "Resource missing", message: "Should not be applied")
            )
            controlled.continuation.finish()

            await generationTask.value
            #expect(viewModel.generationState == .idle(style: .snarky))
            #expect(viewModel.currentResult == nil)
        }
    }

    @Test("unavailable regeneration cancels in-flight generation and keeps error state")
    func unavailableRegenerationCancelsInFlightGeneration() async throws {
        let service = StubGenerationSession()
        let controlled = GenerationStream.controlledWithTermination()
        service.streamToReturn = controlled.stream
        try await withSUT(service: service) { viewModel, service in
            let conflict = try httpError(409)
            viewModel.selectError(conflict)
            let firstTask = viewModel.generate()

            service.availability = .unavailable(.assetsUnavailable)
            await viewModel.generate().value

            await controlled.terminationSignal.wait()
            controlled.continuation.yield(
                generatedSnapshot(meaning: "Stale meaning", message: "Stale message")
            )
            controlled.continuation.finish()

            await firstTask.value

            #expect(service.generateCallCount == 1)
            let failure = try #require(viewModel.generationState.errorFailure)
            #expect(failure.error == .unavailable(.assetsUnavailable))
            let message = failure.error.localizedDescription
            #expect(message.contains("assets aren't available"))
            #expect(viewModel.currentResult == nil)
        }
    }

    @Test("unavailable generation clears stale prior result")
    func unavailableGenerationClearsStalePriorResult() async throws {
        let service = StubGenerationSession()
        service.streamToReturn = .immediate(values: [
            generatedSnapshot(meaning: "Resource missing", message: "Stale message"),
        ])
        try await withSUT(service: service) { viewModel, service in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)
            await viewModel.generate().value
            #expect(viewModel.currentResult?.message == "Stale message")

            service.availability = .unavailable(.assetsUnavailable)
            await viewModel.generate().value

            let failure = try #require(viewModel.generationState.errorFailure)
            #expect(failure.error == .unavailable(.assetsUnavailable))
            #expect(viewModel.currentResult == nil)
        }
    }

    @Test("reset cancels stream consumption")
    func resetCancelsStreamConsumption() async throws {
        let service = StubGenerationSession()
        let controlled = GenerationStream.controlledWithTermination()
        service.streamToReturn = controlled.stream
        try await withSUT(service: service) { viewModel, _ in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)

            let generationTask = viewModel.generate()
            viewModel.reset()

            await controlled.terminationSignal.wait()
            controlled.continuation.finish()
            await generationTask.value

            #expect(viewModel.generationState == .idle(style: .snarky))
        }
    }

    @Test("selecting a new error cancels in-flight generation")
    func selectErrorCancelsInFlightGeneration() async throws {
        let service = StubGenerationSession()
        let controlled = GenerationStream.controlledWithTermination()
        service.streamToReturn = controlled.stream
        try await withSUT(service: service) { viewModel, _ in
            let badRequest = try httpError(400)
            let notFound = try httpError(404)
            viewModel.selectError(badRequest)

            let generationTask = viewModel.generate()
            viewModel.selectError(notFound)

            await controlled.terminationSignal.wait()
            controlled.continuation.yield(
                generatedSnapshot(meaning: "Stale meaning", message: "Stale message")
            )
            controlled.continuation.finish()
            await generationTask.value

            let selection = try #require(viewModel.generationState.codeSelection)
            #expect(selection.error == notFound)
            #expect(selection.style == .snarky)
            #expect(viewModel.currentResult == nil)
        }
    }

    @Test("selecting style during generation preserves current style")
    func selectStyleDuringGenerationPreservesCurrentStyle() async throws {
        let service = StubGenerationSession()
        let controlled = GenerationStream.controlled()
        service.streamToReturn = controlled.stream
        try await withSUT(service: service) { viewModel, _ in
            let notFound = try httpError(404)
            viewModel.selectStyle(.haiku)
            viewModel.selectError(notFound)
            let generationTask = viewModel.generate()

            viewModel.selectStyle(.pirate)
            #expect(viewModel.selectedStyle == .haiku)

            controlled.continuation.yield(
                generatedSnapshot(meaning: "Not found", message: "Result")
            )
            controlled.continuation.finish()
            await generationTask.value
        }
    }

    @Test("reset after regenerate ignores stale stream completions")
    func resetAfterRegenerateIgnoresStaleStreamCompletions() async throws {
        let service = StubGenerationSession()
        let first = GenerationStream.controlled()
        let second = GenerationStream.controlled()
        service.queuedStreams = [first.stream, second.stream]
        try await withSUT(service: service) { viewModel, service in
            let conflict = try httpError(409)
            viewModel.selectError(conflict)

            let firstTask = viewModel.generate()
            let secondTask = viewModel.generate()

            viewModel.reset()

            first.continuation.yield(
                generatedSnapshot(meaning: "First stream", message: "Old result")
            )
            second.continuation.yield(
                generatedSnapshot(meaning: "Second stream", message: "New result")
            )
            first.continuation.finish()
            second.continuation.finish()

            await firstTask.value
            await secondTask.value

            #expect(service.generateCallCount == 2)
            #expect(viewModel.generationState == .idle(style: .snarky))
            #expect(viewModel.currentResult == nil)
        }
    }

    @Test("select style applies to subsequent selections")
    func selectStyleAppliesToSelectionState() async throws {
        try await withSUT { viewModel, _ in
            let teapot = try httpError(418)
            viewModel.selectStyle(.haiku)
            viewModel.selectError(teapot)

            let selection = try #require(viewModel.generationState.codeSelection)
            #expect(selection.error == teapot)
            #expect(selection.style == .haiku)
            #expect(viewModel.selectedStyle == .haiku)
        }
    }

    @Test("animation phase ignores in-flight payload changes")
    func animationPhaseIgnoresInFlightPayloadChanges() async throws {
        try await withSUT { viewModel, _ in
            let notFound = try httpError(404)
            let selection = ErrorGeneration.Selection(error: notFound, style: .snarky)

            viewModel.generationState = .generating(
                ErrorGeneration.InFlightState(
                    selection: selection,
                    partialResult: generatedSnapshot(meaning: "Meaning", message: nil)
                )
            )
            let firstPhase = viewModel.generationAnimationPhase

            viewModel.generationState = .generating(
                ErrorGeneration.InFlightState(
                    selection: selection,
                    partialResult: generatedSnapshot(
                        meaning: "Meaning",
                        message: "Updated message"
                    )
                )
            )

            #expect(firstPhase == .generating)
            #expect(viewModel.generationAnimationPhase == .generating)
        }
    }

    @Test("empty stream maps to decoding failure")
    func emptyStreamMapsToDecodingFailure() async throws {
        let service = StubGenerationSession()
        service.streamToReturn = .immediate(values: [])
        try await withSUT(service: service) { viewModel, _ in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)

            await viewModel.generate().value

            let failure = try #require(viewModel.generationState.errorFailure)
            #expect(failure.error == .decodingFailure)
            #expect(failure.partialResult == nil)
            #expect(failure.selection.error == notFound)
        }
    }

    @Test("stream without final message maps to decoding failure")
    func streamWithoutFinalMessageMapsToDecodingFailure() async throws {
        let service = StubGenerationSession()
        service.streamToReturn = .immediate(values: [
            generatedSnapshot(meaning: "Only meaning", message: nil),
        ])

        try await withSUT(service: service) { viewModel, _ in
            let notFound = try httpError(404)
            viewModel.selectError(notFound)

            await viewModel.generate().value

            let failure = try #require(viewModel.generationState.errorFailure)
            #expect(failure.error == .decodingFailure)
            #expect(failure.partialResult?.meaning == "Only meaning")
            #expect(failure.partialResult?.message == nil)
        }
    }

    @Test("view model deallocates after canceling in-flight generation")
    func viewModelDeallocatesAfterCancelingInFlightGeneration() async throws {
        let service = StubGenerationSession()
        let controlled = GenerationStream.controlledWithTermination()
        service.streamToReturn = controlled.stream
        try await withSUT(service: service) { viewModel, _ in
            let conflict = try httpError(409)
            viewModel.selectError(conflict)
            let generationTask = viewModel.generate()
            viewModel.reset()
            await controlled.terminationSignal.wait()
            controlled.continuation.finish()
            await generationTask.value
        }
    }

    private func withSUT(
        service: StubGenerationSession = StubGenerationSession(),
        availabilityMonitorClock: (any AvailabilityMonitorClock)? = nil,
        _ body: @MainActor (ErrorGeneratorViewModel, StubGenerationSession) async throws -> Void
    ) async throws {
        var viewModel: ErrorGeneratorViewModel? = ErrorGeneratorViewModel(
            session: service,
            availabilityMonitorClock: availabilityMonitorClock ?? TestAvailabilityMonitorClock()
        )
        let weakViewModel = WeakReference(viewModel)
        defer {
            viewModel = nil
            #expect(weakViewModel.value == nil)
        }
        try await body(try #require(viewModel), service)
    }
}
