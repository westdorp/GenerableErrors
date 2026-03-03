/// Implementations return ``GenerationStream``, which normalizes all
/// failures to ``GenerationError`` values for callers.
public protocol GenerationSession: Sendable {
    var availability: ModelAvailability { get }

    func generate<E: ErrorDescriptor, S: ErrorStyle>(
        for error: E,
        style: S
    ) -> GenerationStream
}
