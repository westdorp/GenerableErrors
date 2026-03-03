import Foundation

struct HTTPErrorCatalog: Equatable, Sendable {
    nonisolated let errors: [HTTPError]

    nonisolated var grouped: [(category: HTTPErrorCategory, errors: [HTTPError])] {
        let groupedErrors = Dictionary(grouping: errors, by: \.category)
        return HTTPErrorCategory.allCases.compactMap { category in
            guard let errors = groupedErrors[category], !errors.isEmpty else {
                return nil
            }
            return (category: category, errors: errors)
        }
    }
}

enum HTTPErrorCatalogLoadError: Error, Equatable, Sendable {
    case resourceNotFound
    case unreadableResource
    case decodingFailed(context: String)
    case duplicateCode(Int)
    case emptyField(code: Int, field: Field)

    enum Field: String, Equatable, Sendable {
        case name
        case rfc
        case explanation
    }
}

extension HTTPErrorCatalogLoadError: LocalizedError {
    nonisolated var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "HTTP error catalog file is missing from the app bundle."
        case .unreadableResource:
            return "HTTP error catalog file could not be read."
        case .decodingFailed(let context):
            let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContext.isEmpty else {
                return "HTTP error catalog JSON is malformed."
            }
            let normalizedContext =
                trimmedContext.hasSuffix(".") ? trimmedContext : "\(trimmedContext)."
            return "HTTP error catalog JSON is malformed: \(normalizedContext)"
        case .duplicateCode(let code):
            return "HTTP error catalog has duplicate code \(code)."
        case .emptyField(let code, let field):
            return "HTTP error \(code) has an empty \(field.rawValue) value."
        }
    }
}

/// Loads the bundled HTTP error catalog from JSON into typed domain models.
struct JSONHTTPErrorCatalogLoader: Sendable {
    /// Loads and decodes the HTTP error catalog resource from a bundle.
    /// - Parameter bundle: Bundle containing `HTTPErrorCatalog.json`.
    /// - Returns: Parsed catalog with validated records.
    /// - Throws: `HTTPErrorCatalogLoadError.resourceNotFound`, `.unreadableResource`, or `.decodingFailed(context:)`.
    nonisolated func loadCatalog(
        from bundle: Bundle = .httpErrorCatalogBundle
    ) throws -> HTTPErrorCatalog {
        guard let url = bundle.url(
            forResource: HTTPErrorCatalogResource.name,
            withExtension: HTTPErrorCatalogResource.extension
        ) else {
            throw HTTPErrorCatalogLoadError.resourceNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw HTTPErrorCatalogLoadError.unreadableResource
        }

        return try decodeCatalog(from: data)
    }

    nonisolated func decodeCatalog(from data: Data) throws -> HTTPErrorCatalog {
        let records: [HTTPErrorCatalogRecord]
        do {
            records = try JSONDecoder().decode([HTTPErrorCatalogRecord].self, from: data)
        } catch let decodingError as DecodingError {
            throw HTTPErrorCatalogLoadError.decodingFailed(
                context: String(describing: decodingError)
            )
        } catch {
            throw HTTPErrorCatalogLoadError.decodingFailed(context: error.localizedDescription)
        }

        var seenCodes = Set<Int>()
        var errors: [HTTPError] = []
        errors.reserveCapacity(records.count)

        for record in records {
            guard seenCodes.insert(record.code).inserted else {
                throw HTTPErrorCatalogLoadError.duplicateCode(record.code)
            }
            let normalizedRecord = try record.normalized()
            errors.append(
                HTTPError(
                    id: normalizedRecord.code,
                    name: normalizedRecord.name,
                    rfc: normalizedRecord.rfc,
                    explanation: normalizedRecord.explanation
                )
            )
        }

        return HTTPErrorCatalog(errors: errors)
    }
}

private struct HTTPErrorCatalogResource {
    nonisolated static let name = "HTTPErrorCatalog"
    nonisolated static let `extension` = "json"
}

private struct HTTPErrorCatalogRecord: Decodable, Sendable {
    let code: Int
    let name: String
    let rfc: String
    let explanation: String

    nonisolated func normalized() throws -> NormalizedHTTPErrorCatalogRecord {
        let normalizedName = name.catalogTrimmed
        let normalizedRFC = rfc.catalogTrimmed
        let normalizedExplanation = explanation.catalogTrimmed

        if normalizedName.isEmpty {
            throw HTTPErrorCatalogLoadError.emptyField(code: code, field: .name)
        }
        if normalizedRFC.isEmpty {
            throw HTTPErrorCatalogLoadError.emptyField(code: code, field: .rfc)
        }
        if normalizedExplanation.isEmpty {
            throw HTTPErrorCatalogLoadError.emptyField(code: code, field: .explanation)
        }

        return NormalizedHTTPErrorCatalogRecord(
            code: code,
            name: normalizedName,
            rfc: normalizedRFC,
            explanation: normalizedExplanation
        )
    }
}

private struct NormalizedHTTPErrorCatalogRecord: Sendable {
    let code: Int
    let name: String
    let rfc: String
    let explanation: String
}

private extension String {
    nonisolated var catalogTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private final class HTTPErrorCatalogBundleToken {}

extension Bundle {
    nonisolated static var httpErrorCatalogBundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: HTTPErrorCatalogBundleToken.self)
        #endif
    }
}
