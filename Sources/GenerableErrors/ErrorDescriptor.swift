/// Describes any error from any domain for prompt construction.
///
/// Consumers conform their domain error types to this protocol.
/// The generation engine uses these properties to construct prompts
/// without knowledge of the specific error domain.
///
/// ```swift
/// struct HTTPError: ErrorDescriptor {
///     let statusCode: Int
///     var code: String { "\(statusCode)" }
///     var name: String { "Not Found" }
///     var explanation: String { "The target resource could not be found." }
/// }
/// ```
public protocol ErrorDescriptor: Hashable, Sendable {
    /// Display code: `"404"`, `"UNAUTHENTICATED"`, `"E1001"`.
    var code: String { get }
    /// Human-readable name: `"Not Found"`, `"Authentication Required"`.
    var name: String { get }
    /// What this error means technically.
    var explanation: String { get }
}
