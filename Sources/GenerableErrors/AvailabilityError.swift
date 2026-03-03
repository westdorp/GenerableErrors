import Foundation

/// Typed reasons for model unavailability before generation can begin.
public enum AvailabilityError: Error, Equatable, Sendable, LocalizedError, CaseIterable {
    case appleIntelligenceNotEnabled
    case modelNotReady
    case deviceNotEligible
    case unsupportedDevice
    case assetsUnavailable

    public var errorDescription: String? {
        switch self {
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence and Siri are turned off. Enable both in Settings and try again."
        case .modelNotReady:
            "The on-device model is still preparing. Wait for downloads to finish and try again."
        case .deviceNotEligible:
            "This device isn't eligible for Apple Intelligence model downloads."
        case .unsupportedDevice:
            "This device doesn't support on-device generation for this app."
        case .assetsUnavailable:
            "Apple Intelligence model assets aren't available yet. Enable Apple Intelligence and Siri, wait for downloads, then relaunch."
        }
    }

    public var recoveryGuidance: RecoveryGuidance {
        switch self {
        case .appleIntelligenceNotEnabled:
            RecoveryGuidance(
                title: "Apple Intelligence Disabled",
                steps: [
                    "Open Settings > Apple Intelligence & Siri and turn on both Apple Intelligence and Siri.",
                    "Wait for model downloads to complete, then relaunch the app.",
                ]
            )
        case .modelNotReady:
            RecoveryGuidance(
                title: "Model Download In Progress",
                steps: [
                    "Keep the device on Wi-Fi and power while downloads finish.",
                    "Retry generation in a few minutes.",
                ]
            )
        case .deviceNotEligible, .unsupportedDevice:
            RecoveryGuidance(
                title: "Unsupported Environment",
                steps: [
                    "Run on Apple Intelligence-capable hardware.",
                    "If using Simulator, it depends on the host Mac's Apple Intelligence support and downloaded model assets.",
                ]
            )
        case .assetsUnavailable:
            RecoveryGuidance(
                title: "Model Assets Missing",
                steps: [
                    "On the host Mac (for Simulator) or device, open Settings > Apple Intelligence & Siri and enable both.",
                    "Leave the system on Wi-Fi and power until model assets finish downloading.",
                    "Quit and relaunch Simulator and this app, then try generating again.",
                ]
            )
        }
    }
}
