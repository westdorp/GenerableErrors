import GenerableErrors

/// Built-in style shipped with the package.
///
/// Use dot-syntax with the ``ErrorStyle`` protocol:
///
/// ```swift
/// session.generate(for: myError, style: .snarky)
/// ```
public struct CuratedStyle: ErrorStyle, CaseIterable, Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let promptHint: String
    public let temperature: Double

    init(id: String, label: String, promptHint: String, temperature: Double = 1.0) {
        self.id = id
        self.label = label
        self.promptHint = promptHint
        self.temperature = temperature
    }

    public static let allCases: [CuratedStyle] = [
        .snarky,
        .passiveAggressive,
        .haiku,
        .fortuneCookie,
        .pirate,
        .shakespearean,
        .movieTrailer,
        .corporateMemo,
        .deadpan,
        .limerick,
        .sportsCommentary,
        .rosesAreRed,
        .disappointedParent,
        .noirDetective,
        .overenthusiastic,
    ]
}
