import GenerableErrors

// Adding a style requires 3 updates:
// 1) Define a `static let` in this file.
// 2) Append it to `CuratedStyle.allCases` in CuratedStyle.swift.
// 3) Add dot-syntax support in the `ErrorStyle where Self == CuratedStyle` extension below.
extension CuratedStyle {
    public static let snarky = CuratedStyle(
        id: "snarky",
        label: "Snarky",
        promptHint: "Write a short, witty, sarcastic one-liner. Maximum one sentence."
    )

    public static let passiveAggressive = CuratedStyle(
        id: "passiveAggressive",
        label: "Passive-Aggressive",
        promptHint: "Write a passive-aggressive message, the kind that says 'it's fine' when it clearly isn't. One to two sentences."
    )

    public static let haiku = CuratedStyle(
        id: "haiku",
        label: "Haiku",
        promptHint: "Write a haiku (three lines: roughly 5 syllables, 7 syllables, 5 syllables)."
    )

    public static let fortuneCookie = CuratedStyle(
        id: "fortuneCookie",
        label: "Fortune Cookie",
        promptHint: "Write a fortune cookie message — short, cryptic wisdom. One sentence."
    )

    public static let pirate = CuratedStyle(
        id: "pirate",
        label: "Pirate",
        promptHint: "Write it as a pirate would say it, with pirate vocabulary and speech patterns. One to two sentences."
    )

    public static let shakespearean = CuratedStyle(
        id: "shakespearean",
        label: "Shakespearean",
        promptHint: "Write it in Shakespearean English with dramatic flair. Two sentences maximum."
    )

    public static let movieTrailer = CuratedStyle(
        id: "movieTrailer",
        label: "Movie Trailer",
        promptHint: "Write it as a dramatic movie trailer voiceover. Start with 'In a world where...' One to two sentences."
    )

    public static let corporateMemo = CuratedStyle(
        id: "corporateMemo",
        label: "Corporate Memo",
        promptHint: "Write it as an overly formal corporate memo. Use business jargon. Two to three sentences."
    )

    public static let deadpan = CuratedStyle(
        id: "deadpan",
        label: "Deadpan",
        promptHint: "Write it with completely flat, deadpan delivery. No emotion whatsoever. One sentence."
    )

    public static let limerick = CuratedStyle(
        id: "limerick",
        label: "Limerick",
        promptHint: "Write a limerick (five lines, AABBA rhyme scheme)."
    )

    public static let sportsCommentary = CuratedStyle(
        id: "sportsCommentary",
        label: "Sports Commentary",
        promptHint: "Write it as a live sports play-by-play announcer calling the action. Two sentences maximum."
    )

    public static let rosesAreRed = CuratedStyle(
        id: "rosesAreRed",
        label: "Roses Are Red",
        promptHint: "Write it as a 'Roses are red, violets are blue' style poem. Four lines."
    )

    public static let disappointedParent = CuratedStyle(
        id: "disappointedParent",
        label: "Disappointed Parent",
        promptHint: "Write it as a disappointed parent who isn't angry, just disappointed. Two sentences maximum."
    )

    public static let noirDetective = CuratedStyle(
        id: "noirDetective",
        label: "Noir Detective",
        promptHint: "Write it in the style of a 1940s film noir detective narration. Two sentences maximum."
    )

    public static let overenthusiastic = CuratedStyle(
        id: "overenthusiastic",
        label: "Enthusiastic Intern",
        promptHint: "Write it as an overly enthusiastic intern who is excited about absolutely everything, even errors. Two sentences maximum."
    )
}

// MARK: - Dot-syntax via conditional extension

extension ErrorStyle where Self == CuratedStyle {
    public static var snarky: CuratedStyle { .snarky }
    public static var passiveAggressive: CuratedStyle { .passiveAggressive }
    public static var haiku: CuratedStyle { .haiku }
    public static var fortuneCookie: CuratedStyle { .fortuneCookie }
    public static var pirate: CuratedStyle { .pirate }
    public static var shakespearean: CuratedStyle { .shakespearean }
    public static var movieTrailer: CuratedStyle { .movieTrailer }
    public static var corporateMemo: CuratedStyle { .corporateMemo }
    public static var deadpan: CuratedStyle { .deadpan }
    public static var limerick: CuratedStyle { .limerick }
    public static var sportsCommentary: CuratedStyle { .sportsCommentary }
    public static var rosesAreRed: CuratedStyle { .rosesAreRed }
    public static var disappointedParent: CuratedStyle { .disappointedParent }
    public static var noirDetective: CuratedStyle { .noirDetective }
    public static var overenthusiastic: CuratedStyle { .overenthusiastic }
}
