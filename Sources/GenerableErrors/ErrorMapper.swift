import Foundation
import FoundationModels

/// NSError traversal uses bounded depth-first search with cycle detection.
enum ErrorMapper {
    private static let maxErrorTraversalDepth = 32

    static func mapAvailability(
        _ availability: SystemLanguageModel.Availability
    ) -> ModelAvailability {
        switch availability {
        case .available:
            .available
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                .unavailable(.appleIntelligenceNotEnabled)
            case .modelNotReady:
                .unavailable(.modelNotReady)
            case .deviceNotEligible:
                .unavailable(.deviceNotEligible)
            @unknown default:
                mapUnknownUnavailableReason(String(describing: reason))
            }
        @unknown default:
            .unavailable(.unsupportedDevice)
        }
    }

    static func mapGenerationError(
        _ error: LanguageModelSession.GenerationError
    ) -> GenerationError {
        switch error {
        case .guardrailViolation:
            .guardrailViolation
        case .exceededContextWindowSize:
            .exceededContextWindowSize
        case .unsupportedLanguageOrLocale:
            .unsupportedLanguageOrLocale
        case .assetsUnavailable:
            .unavailable(.assetsUnavailable)
        case .rateLimited:
            .rateLimited
        case .concurrentRequests:
            .concurrentRequests
        case .refusal:
            .refusal
        case .decodingFailure:
            .decodingFailure
        case .unsupportedGuide:
            .unsupportedGuide
        @unknown default:
            mapError(error)
        }
    }

    static func mapError(_ error: any Error) -> GenerationError {
        let nsError = error as NSError

        if isModelCatalogUnavailableError(nsError) {
            return .unavailable(.assetsUnavailable)
        }

        return .unknown
    }

    private static func isModelCatalogUnavailableError(_ error: NSError) -> Bool {
        var stack: [NSError] = [error]
        var visited = Set<ObjectIdentifier>()
        var traversedCount = 0

        while !stack.isEmpty, traversedCount < maxErrorTraversalDepth {
            let current = stack.removeLast()
            let identifier = ObjectIdentifier(current)
            guard visited.insert(identifier).inserted else {
                continue
            }

            traversedCount += 1

            if isModelCatalogErrorCode(current) {
                return true
            }

            if let failureReason =
                current.userInfo[NSLocalizedFailureReasonErrorKey] as? String,
                isModelCatalogFailureReason(failureReason)
            {
                return true
            }

            if let underlyingError =
                nestedNSError(from: current.userInfo[NSUnderlyingErrorKey])
            {
                stack.append(underlyingError)
            }

            if let underlyingErrors =
                current.userInfo[NSMultipleUnderlyingErrorsKey] as? [Any]
            {
                for underlying in underlyingErrors {
                    if let nestedError = nestedNSError(from: underlying) {
                        stack.append(nestedError)
                    }

                    if let nestedDescription = underlying as? String,
                        isModelCatalogFailureReason(nestedDescription)
                    {
                        return true
                    }
                }
            }
        }

        return false
    }

    private static func mapUnknownUnavailableReason(
        _ reasonDescription: String
    ) -> ModelAvailability {
        let normalized = reasonDescription.lowercased()
        if normalized.contains("assetsunavailable") {
            return .unavailable(.assetsUnavailable)
        }
        return .unavailable(.unsupportedDevice)
    }

    private static func isModelCatalogErrorCode(_ error: NSError) -> Bool {
        // Observed Apple internal error signatures for missing model catalog
        // assets in current OS releases. Keep these checks narrow and update if
        // Foundation Models changes its underlying domains/codes.
        (error.domain == "com.apple.UnifiedAssetFramework" && error.code == 5000)
            || (error.domain == "ModelManagerServices.ModelManagerError" && error.code == 1026)
    }

    private static func isModelCatalogFailureReason(_ message: String) -> Bool {
        let normalized = message.lowercased()
        return normalized.contains("com.apple.unifiedassetframework code=5000")
            || normalized.contains("modelmanagerservices.modelmanagererror code=1026")
            || normalized.contains("asset set com.apple.modelcatalog")
    }

    private static func nestedNSError(from underlying: Any?) -> NSError? {
        if let nestedNSError = underlying as? NSError {
            return nestedNSError
        }

        if let nestedError = underlying as? any Error {
            return nestedError as NSError
        }

        return nil
    }
}
