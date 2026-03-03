import Foundation
import GenerableErrors

/// Canonical HTTP status metadata used by both UI content and prompt construction.
nonisolated struct HTTPError: Identifiable, Hashable, Sendable {
    nonisolated let id: Int
    nonisolated let name: String
    nonisolated let rfc: String
    /// RFC-grounded semantics injected into prompts to keep generation technically accurate.
    nonisolated let explanation: String

    nonisolated var statusCode: Int { id }

    nonisolated var category: HTTPErrorCategory {
        switch statusCode {
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default:        return .other
        }
    }
}

extension HTTPError: ErrorDescriptor {
    nonisolated var code: String { "\(id)" }
}

enum HTTPErrorCategory: String, CaseIterable, Identifiable, Sendable {
    case clientError = "4xx · Client Errors"
    case serverError = "5xx · Server Errors"
    case other       = "Other"

    nonisolated var id: String { rawValue }
}
