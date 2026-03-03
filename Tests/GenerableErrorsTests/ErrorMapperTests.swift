import Foundation
import Testing
@testable import GenerableErrors

@Suite("ErrorMapper")
struct ErrorMapperTests {

    private final class CyclicNSError: NSError, @unchecked Sendable {
        private let storage = NSMutableDictionary()

        init() {
            super.init(domain: "loop.domain", code: 1, userInfo: nil)
            storage[NSUnderlyingErrorKey] = self
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var userInfo: [String: Any] {
            storage as? [String: Any] ?? [:]
        }
    }

    @Test("maps UnifiedAssetFramework missing assets to assetsUnavailable")
    func mapsUnifiedAssetFrameworkError() {
        let error = NSError(
            domain: "com.apple.UnifiedAssetFramework",
            code: 5000,
            userInfo: [NSLocalizedDescriptionKey: "Model catalog unavailable"]
        )

        let mapped = ErrorMapper.mapError(error)
        #expect(mapped == .unavailable(.assetsUnavailable))
    }

    @Test("maps nested model manager error chain to assetsUnavailable")
    func mapsNestedModelCatalogError() {
        let rootError = NSError(
            domain: "com.apple.UnifiedAssetFramework",
            code: 5000,
            userInfo: [NSLocalizedDescriptionKey: "Model catalog unavailable"]
        )
        let intermediateError = NSError(
            domain: "ModelManagerServices.ModelManagerError",
            code: 1026,
            userInfo: [NSUnderlyingErrorKey: rootError]
        )
        let topLevelError = NSError(
            domain: "FoundationModels.LanguageModelSession.GenerationError",
            code: -1,
            userInfo: [NSUnderlyingErrorKey: intermediateError]
        )

        let mapped = ErrorMapper.mapError(topLevelError)
        #expect(mapped == .unavailable(.assetsUnavailable))
    }

    @Test("maps NSMultipleUnderlyingErrorsKey chains to assetsUnavailable")
    func mapsMultipleUnderlyingErrorsChain() {
        let rootError = NSError(
            domain: "com.apple.UnifiedAssetFramework",
            code: 5000,
            userInfo: [NSLocalizedDescriptionKey: "Model catalog unavailable"]
        )
        let topLevelError = NSError(
            domain: "FoundationModels.LanguageModelSession.GenerationError",
            code: -1,
            userInfo: [NSMultipleUnderlyingErrorsKey: [rootError]]
        )

        let mapped = ErrorMapper.mapError(topLevelError)
        #expect(mapped == .unavailable(.assetsUnavailable))
    }

    @Test("maps model catalog failure reason strings to assetsUnavailable")
    func mapsModelCatalogFailureReasonString() {
        let error = NSError(
            domain: "FoundationModels.LanguageModelSession.GenerationError",
            code: -1,
            userInfo: [
                NSLocalizedFailureReasonErrorKey:
                    "There are no underlying assets for asset set com.apple.modelcatalog"
            ]
        )

        let mapped = ErrorMapper.mapError(error)
        #expect(mapped == .unavailable(.assetsUnavailable))
    }

    @Test("handles cyclic underlying error chains")
    func handlesCyclicUnderlyingErrors() {
        let error = CyclicNSError()

        let mapped = ErrorMapper.mapError(error)
        #expect(mapped == .unknown)
    }

    @Test("maps unrelated errors to unknown")
    func mapsUnrelatedErrorToUnknown() {
        let error = NSError(
            domain: "example.domain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "Unrelated failure"]
        )

        let mapped = ErrorMapper.mapError(error)
        #expect(mapped == .unknown)
    }
}
