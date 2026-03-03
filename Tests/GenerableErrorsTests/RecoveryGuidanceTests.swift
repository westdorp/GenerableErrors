import Testing
@testable import GenerableErrors

@Suite("RecoveryGuidance")
struct RecoveryGuidanceTests {

    @Test("initializer normalizes title and steps")
    func initializerNormalizesFields() {
        let guidance = RecoveryGuidance(
            title: "  Retry Later  ",
            steps: ["  Step one  ", "", "   ", "\nStep two\n"]
        )

        #expect(guidance.title == "Retry Later")
        #expect(guidance.steps == ["Step one", "Step two"])
    }
}
