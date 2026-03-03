import Testing
import GenerableErrors
import CuratedStyles

@Suite("CuratedStyle")
struct CuratedStyleTests {

    @Test("all 15 styles are in the catalog")
    func catalogHas15Styles() {
        #expect(CuratedStyle.allCases.count == 15)
    }

    @Test("dot-syntax accessors stay in sync with catalog")
    func dotSyntaxAccessorsStayInSyncWithCatalog() {
        let dotSyntaxStyles: [CuratedStyle] = [
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

        #expect(dotSyntaxStyles.count == CuratedStyle.allCases.count)
        for style in CuratedStyle.allCases {
            #expect(dotSyntaxStyles.contains(style))
        }
    }

    @Test("all styles have unique ids")
    func uniqueIds() {
        let ids = CuratedStyle.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("all styles have non-empty prompt hints")
    func nonEmptyPromptHints() {
        for style in CuratedStyle.allCases {
            #expect(!style.promptHint.isEmpty)
        }
    }

    @Test("all styles have non-empty labels")
    func nonEmptyLabels() {
        for style in CuratedStyle.allCases {
            #expect(!style.label.isEmpty)
        }
    }

    @Test("temperatures are within valid range")
    func temperaturesInRange() {
        for style in CuratedStyle.allCases {
            #expect(style.temperature >= 0.0)
            #expect(style.temperature <= 1.0)
        }
    }

    @Test("CuratedStyle conforms to ErrorStyle")
    func conformsToErrorStyle() {
        func acceptsStyle(_ style: some ErrorStyle) -> String {
            style.promptHint
        }

        let hint = acceptsStyle(CuratedStyle.snarky)
        #expect(!hint.isEmpty)
    }
}
