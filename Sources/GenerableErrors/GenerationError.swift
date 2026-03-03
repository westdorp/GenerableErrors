import Foundation

/// Typed error cases for generation-time failures.
public enum GenerationError: Error, Equatable, Sendable, LocalizedError, CaseIterable {
    case unavailable(AvailabilityError)
    case invalidRequest
    case guardrailViolation
    case exceededContextWindowSize
    case unsupportedLanguageOrLocale
    case rateLimited
    case concurrentRequests
    case refusal
    case decodingFailure
    case unsupportedGuide
    case unknown

    public static var allCases: [GenerationError] {
        AvailabilityError.allCases.map(Self.unavailable) + [
            .invalidRequest,
            .guardrailViolation,
            .exceededContextWindowSize,
            .unsupportedLanguageOrLocale,
            .rateLimited,
            .concurrentRequests,
            .refusal,
            .decodingFailure,
            .unsupportedGuide,
            .unknown,
        ]
    }

    public var availabilityError: AvailabilityError? {
        guard case .unavailable(let reason) = self else {
            return nil
        }
        return reason
    }

    public var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            reason.localizedDescription
        case .invalidRequest:
            "The selected error metadata is incomplete. Choose a different error code and try again."
        case .guardrailViolation:
            "Apple's safety filters blocked this combination. Try a different error code or style."
        case .exceededContextWindowSize:
            "The prompt was too long for the on-device model. Try a simpler error code."
        case .unsupportedLanguageOrLocale:
            "Your device language isn't supported by the on-device model."
        case .rateLimited:
            "You've reached the current generation limit. Wait a moment and try again."
        case .concurrentRequests:
            "Too many generations are running at once. Let one finish before starting another."
        case .refusal:
            "The model refused this request. Try a different style or error code."
        case .decodingFailure:
            "Couldn't decode the generated result. Try again."
        case .unsupportedGuide:
            "This prompt guide isn't supported on this device."
        case .unknown:
            "An unknown generation error occurred. Please try again."
        }
    }

    public var recoveryGuidance: RecoveryGuidance {
        switch self {
        case .unavailable(let reason):
            reason.recoveryGuidance
        case .invalidRequest:
            RecoveryGuidance(
                title: "Invalid Error Metadata",
                steps: [
                    "Pick a different error code from the catalog.",
                    "If the issue persists, verify the error catalog content and relaunch the app.",
                ]
            )
        case .unsupportedLanguageOrLocale:
            RecoveryGuidance(
                title: "Unsupported Language",
                steps: [
                    "Switch to a supported system language/locale for Apple Intelligence.",
                    "Relaunch the app and retry generation.",
                ]
            )
        case .guardrailViolation:
            RecoveryGuidance(
                title: "Blocked by Safety Filters",
                steps: [
                    "Try a different error code and style combination.",
                ]
            )
        case .exceededContextWindowSize:
            RecoveryGuidance(
                title: "Prompt Too Large",
                steps: [
                    "Use a shorter prompt context and retry.",
                ]
            )
        case .rateLimited:
            RecoveryGuidance(
                title: "Rate Limited",
                steps: [
                    "Wait a moment before trying again.",
                ]
            )
        case .concurrentRequests:
            RecoveryGuidance(
                title: "Too Many Requests",
                steps: [
                    "Let the current generation complete before starting another.",
                ]
            )
        case .refusal, .decodingFailure, .unsupportedGuide, .unknown:
            RecoveryGuidance(
                title: "Generation Unavailable",
                steps: [
                    "Retry generation. If the issue persists, relaunch the app.",
                ]
            )
        }
    }
}
