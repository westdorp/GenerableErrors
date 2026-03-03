import FoundationModels

@Generable
struct GeneratedError {
    @Guide(description: "A brief, plain-English explanation of what this error means")
    let meaning: String

    @Guide(description: "The error message creatively rewritten in the requested style, keep it concise")
    let message: String
}

extension GeneratedSnapshot {
    init?(partial: GeneratedError.PartiallyGenerated) {
        self.init(meaning: partial.meaning, message: partial.message)
    }
}
