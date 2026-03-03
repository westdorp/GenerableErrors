import GenerableErrors
import Testing

@Suite("GenerationError")
struct GenerationErrorTests {

    @Test("allCases stays in sync with declared cases")
    func allCasesStaysInSync() {
        let expectedCount = AvailabilityError.allCases.count + 10
        #expect(GenerationError.allCases.count == expectedCount)
        for (index, value) in GenerationError.allCases.enumerated() {
            let duplicateCount = GenerationError.allCases.filter { $0 == value }.count
            #expect(
                duplicateCount == 1,
                "Duplicate GenerationError value at index \(index): \(value)"
            )
        }
    }

    @Test("availability errors expose non-empty guidance")
    func availabilityErrorsExposeGuidance() {
        for reason in AvailabilityError.allCases {
            let guidance = reason.recoveryGuidance
            #expect(!guidance.title.isEmpty)
            #expect(!guidance.steps.isEmpty)
            #expect(!reason.localizedDescription.isEmpty)
        }
    }

    @Test("assets unavailable guidance includes simulator-host setup flow")
    func assetsUnavailableGuidance() {
        let guidance = AvailabilityError.assetsUnavailable.recoveryGuidance

        #expect(guidance.title == "Model Assets Missing")
        #expect(guidance.steps.count == 3)
        #expect(guidance.steps[0].contains("Apple Intelligence & Siri"))
        #expect(guidance.steps[0].contains("host Mac"))
        #expect(guidance.steps[2].contains("Quit and relaunch Simulator"))
    }

    @Test("apple intelligence disabled guidance requires siri")
    func appleIntelligenceDisabledGuidance() {
        let guidance = AvailabilityError.appleIntelligenceNotEnabled.recoveryGuidance

        #expect(guidance.title == "Apple Intelligence Disabled")
        #expect(guidance.steps.count == 2)
        #expect(guidance.steps[0].contains("Apple Intelligence"))
        #expect(guidance.steps[0].contains("Siri"))
    }

    @Test("generation errors expose non-empty guidance")
    func generationErrorsExposeGuidance() {
        for error in GenerationError.allCases {
            let guidance = error.recoveryGuidance
            #expect(!guidance.title.isEmpty)
            #expect(!guidance.steps.isEmpty)
            #expect(!error.localizedDescription.isEmpty)
        }
    }

    @Test("unavailable generation error retains reason")
    func unavailableGenerationErrorRetainsReason() {
        let error = GenerationError.unavailable(.modelNotReady)
        #expect(error.availabilityError == .modelNotReady)
    }
}
