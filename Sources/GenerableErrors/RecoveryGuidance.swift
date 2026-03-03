import Foundation

public struct RecoveryGuidance: Equatable, Sendable {
    public let title: String
    public let steps: [String]

    // Internal by design: guidance values are authored by package error types.
    init(title: String, steps: [String]) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSteps = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        precondition(
            !normalizedTitle.isEmpty,
            "RecoveryGuidance.title must not be empty"
        )
        precondition(
            !normalizedSteps.isEmpty,
            "RecoveryGuidance.steps must not be empty"
        )

        self.title = normalizedTitle
        self.steps = normalizedSteps
    }
}
