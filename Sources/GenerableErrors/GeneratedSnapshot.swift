/// Streaming output snapshot from a generation session.
///
/// Each field is optional to support incremental generation — early
/// snapshots may have only ``meaning`` while ``message`` is still
/// being produced.
public struct GeneratedSnapshot: Equatable, Sendable {
    public let meaning: String?
    public let message: String?

    public init?(meaning: String?, message: String?) {
        guard meaning != nil || message != nil else {
            return nil
        }
        self.meaning = meaning
        self.message = message
    }
}
