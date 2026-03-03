import Foundation
import Testing
@testable import GenerableErrorsApp

@Suite("HTTPErrorCatalogLoader")
struct HTTPErrorCatalogLoaderTests {
    private let loader = JSONHTTPErrorCatalogLoader()
    private let fileManager = FileManager.default

    @Test("bundled catalog loads expected ordering")
    func bundledCatalogLoadsExpectedOrdering() throws {
        // Arrange
        let expectedCategories: [HTTPErrorCategory] = [.clientError, .serverError]

        // Act
        let catalog = try loader.loadCatalog()
        let grouped = catalog.grouped
        let groupedCategories = grouped.map(\.category)
        let firstGroup = try #require(grouped.first)
        let secondGroup = try #require(grouped.dropFirst().first)
        let allCodes = catalog.errors.map(\.statusCode)

        // Assert
        #expect(!catalog.errors.isEmpty)
        #expect(allCodes == allCodes.sorted())
        #expect(Set(allCodes).count == allCodes.count)
        #expect(groupedCategories == expectedCategories)
        #expect(!firstGroup.errors.isEmpty)
        #expect(firstGroup.category == .clientError)
        #expect(firstGroup.errors.allSatisfy { (400...499).contains($0.statusCode) })
        #expect(!secondGroup.errors.isEmpty)
        #expect(secondGroup.category == .serverError)
        #expect(secondGroup.errors.allSatisfy { (500...599).contains($0.statusCode) })
    }

    @Test("missing catalog resource fails with resource-not-found")
    func missingResourceFailsWithResourceNotFound() throws {
        let temporaryBundle = try makeTemporaryBundle()
        defer { removeItemIfPresent(at: temporaryBundle.url) }

        #expect(throws: HTTPErrorCatalogLoadError.resourceNotFound) {
            _ = try loader.loadCatalog(from: temporaryBundle.bundle)
        }
    }

    @Test("unreadable catalog resource fails with unreadable-resource")
    func unreadableResourceFailsWithUnreadableResource() throws {
        let temporaryBundle = try makeTemporaryBundle { bundleURL in
            let resourceURL = bundleURL.appendingPathComponent("HTTPErrorCatalog.json")
            try fileManager.createDirectory(at: resourceURL, withIntermediateDirectories: false)
        }
        defer { removeItemIfPresent(at: temporaryBundle.url) }

        #expect(throws: HTTPErrorCatalogLoadError.unreadableResource) {
            _ = try loader.loadCatalog(from: temporaryBundle.bundle)
        }
    }

    @Test("malformed JSON fails with decoding error")
    func malformedJSONFailsWithDecodingError() throws {
        // Arrange
        let malformedData = try #require("not-json".data(using: .utf8))

        let caughtError = #expect(throws: HTTPErrorCatalogLoadError.self) {
            _ = try loader.decodeCatalog(from: malformedData)
        }
        let error = try #require(caughtError)

        guard case .decodingFailed(let context) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(!context.isEmpty)
    }

    @Test("duplicate code fails with typed error")
    func duplicateCodeFailsWithTypedError() throws {
        // Arrange
        let duplicatedCodeJSON = """
        [
          { "code": 400, "name": "Bad Request", "rfc": "RFC 9110", "explanation": "Malformed." },
          { "code": 400, "name": "Duplicate", "rfc": "RFC 9110", "explanation": "Duplicate code." }
        ]
        """
        let duplicatedCodeData = try #require(duplicatedCodeJSON.data(using: .utf8))

        // Act / Assert
        #expect(throws: HTTPErrorCatalogLoadError.duplicateCode(400)) {
            _ = try loader.decodeCatalog(from: duplicatedCodeData)
        }
    }

    @Test(
        "empty fields fail with typed errors",
        arguments: [
            (name: " ", rfc: "RFC 9110", explanation: "Explanation", field: HTTPErrorCatalogLoadError.Field.name),
            (name: "Bad Request", rfc: " ", explanation: "Explanation", field: HTTPErrorCatalogLoadError.Field.rfc),
            (name: "Bad Request", rfc: "RFC 9110", explanation: " ", field: HTTPErrorCatalogLoadError.Field.explanation),
        ]
    )
    func emptyFieldFailsWithTypedError(
        name: String,
        rfc: String,
        explanation: String,
        field: HTTPErrorCatalogLoadError.Field
    ) throws {
        // Arrange
        let invalidJSON = """
        [
          {
            "code": 400,
            "name": "\(name)",
            "rfc": "\(rfc)",
            "explanation": "\(explanation)"
          }
        ]
        """
        let invalidData = try #require(invalidJSON.data(using: .utf8))

        // Act / Assert
        #expect(throws: HTTPErrorCatalogLoadError.emptyField(code: 400, field: field)) {
            _ = try loader.decodeCatalog(from: invalidData)
        }
    }

    private func makeTemporaryBundle(
        setup: (URL) throws -> Void = { _ in }
    ) throws -> (url: URL, bundle: Bundle) {
        let bundleURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("bundle")
        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": "com.test.GenerableErrorsTests.\(UUID().uuidString)",
            "CFBundleName": "GenerableErrorsTests",
            "CFBundlePackageType": "BNDL",
            "CFBundleVersion": "1",
            "CFBundleShortVersionString": "1.0",
        ]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlist,
            format: .xml,
            options: 0
        )
        try plistData.write(to: bundleURL.appendingPathComponent("Info.plist"))
        try setup(bundleURL)

        guard let bundle = Bundle(url: bundleURL) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return (bundleURL, bundle)
    }

    private func removeItemIfPresent(at url: URL) {
        try? fileManager.removeItem(at: url)
    }
}
