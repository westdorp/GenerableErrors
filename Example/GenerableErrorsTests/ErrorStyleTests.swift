import CuratedStyles
import Testing
@testable import GenerableErrorsApp

@Suite("ErrorStyle")
struct ErrorStyleTests {
    @Test("grouped confidence tiers preserve expected order")
    func groupedConfidenceTiersPreserveOrder() {
        let tiers = AppStyle.confidenceTierGroups.map(\.tier)
        #expect(tiers == [.high, .medium, .persona])
    }

    @Test("all styles appear exactly once in grouped confidence tiers")
    func allStylesAppearExactlyOnceInGroupedConfidenceTiers() {
        let flattenedStyles = AppStyle.confidenceTierGroups.flatMap(\.styles)
        #expect(flattenedStyles.count == AppStyle.allCases.count)
        #expect(Set(flattenedStyles).count == AppStyle.allCases.count)
    }
}
