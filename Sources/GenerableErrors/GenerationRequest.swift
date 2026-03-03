struct GenerationRequest: Equatable, Sendable {
    let prompt: String
    let instructions: String
    let temperature: Double
}
