import Foundation

/// Constructs prompts from ``ErrorDescriptor`` + ``ErrorStyle``.
///
/// This is the domain knowledge the package encapsulates. Consumers
/// never see the prompt template.
struct RequestBuilder: Sendable {
    private static let temperatureRange = 0.0...1.0

    let instructions: String

    init(instructions: String = Self.defaultInstructions) {
        self.instructions = instructions
    }

    func makeRequest(
        for error: some ErrorDescriptor,
        style: some ErrorStyle
    ) throws(GenerationError) -> GenerationRequest {
        guard
            let code = Self.normalizedNonEmpty(error.code),
            let name = Self.normalizedNonEmpty(error.name),
            let explanation = Self.normalizedNonEmpty(error.explanation)
        else {
            throw .invalidRequest
        }

        let prompt = """
            Error Code: \(code) \(name)
            Technical meaning: \(explanation)

            Rewrite this error in the following style.
            \(style.promptHint)
            """

        return GenerationRequest(
            prompt: prompt,
            instructions: instructions,
            temperature: Self.clampedTemperature(style.temperature)
        )
    }

    static let `default` = RequestBuilder()

    static let defaultInstructions = """
        You are a creative writer who rewrites technical error \
        messages in entertaining styles. You understand error codes \
        thoroughly. Your rewrites should be memorable, concise, \
        and match the requested style perfectly. Never include the \
        error code in your rewrite.
        """

    private static func clampedTemperature(_ value: Double) -> Double {
        min(max(value, temperatureRange.lowerBound), temperatureRange.upperBound)
    }

    private static func normalizedNonEmpty(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }
        return normalized
    }
}
