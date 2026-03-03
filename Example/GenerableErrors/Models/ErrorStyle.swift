import CuratedStyles

typealias AppStyle = CuratedStyle

enum ErrorStyleConfidenceTier: String, CaseIterable, Identifiable, Hashable, Sendable {
    case high = "High Confidence"
    case medium = "Medium Confidence"
    case persona = "Persona / Experimental"

    nonisolated var id: String { rawValue }
}

extension CuratedStyle {
    nonisolated var confidenceTier: ErrorStyleConfidenceTier {
        switch self {
        case .snarky, .passiveAggressive, .haiku, .fortuneCookie, .deadpan:
            .high
        case .corporateMemo, .limerick, .rosesAreRed, .shakespearean, .movieTrailer, .sportsCommentary:
            .medium
        default:
            .persona
        }
    }

    nonisolated static let confidenceTierGroups: [(
        tier: ErrorStyleConfidenceTier,
        styles: [CuratedStyle]
    )] = ErrorStyleConfidenceTier.allCases.compactMap { tier in
        let styles = CuratedStyle.allCases.filter { $0.confidenceTier == tier }
        guard !styles.isEmpty else { return nil }
        return (tier: tier, styles: styles)
    }
}
