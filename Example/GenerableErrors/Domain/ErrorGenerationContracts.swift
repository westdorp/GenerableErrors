import Foundation
import GenerableErrors

enum ErrorGeneration {}

extension ErrorGeneration {
    struct FinalResult: Equatable, Sendable {
        nonisolated let meaning: String?
        nonisolated let message: String

        init?(snapshot: GenerableErrors.GeneratedSnapshot) {
            guard
                let normalizedMessage = snapshot.message?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !normalizedMessage.isEmpty
            else {
                return nil
            }

            if let rawMeaning = snapshot.meaning?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !rawMeaning.isEmpty
            {
                self.meaning = rawMeaning
            } else {
                self.meaning = nil
            }
            self.message = normalizedMessage
        }

        nonisolated var snapshot: GenerableErrors.GeneratedSnapshot {
            guard let snapshot = GenerableErrors.GeneratedSnapshot(
                meaning: meaning,
                message: message
            ) else {
                preconditionFailure("FinalResult always contains a non-empty message")
            }
            return snapshot
        }
    }

    struct Selection: Equatable, Sendable {
        nonisolated let error: HTTPError
        nonisolated let style: AppStyle
    }

    struct InFlightState: Equatable, Sendable {
        nonisolated let selection: Selection
        nonisolated let partialResult: GenerableErrors.GeneratedSnapshot?
    }

    struct CompletedState: Equatable, Sendable {
        nonisolated let selection: Selection
        nonisolated let result: FinalResult
    }

    struct FailureState: Equatable, Sendable {
        nonisolated let selection: Selection
        nonisolated let error: GenerableErrors.GenerationError
        nonisolated let partialResult: GenerableErrors.GeneratedSnapshot?
    }
}
