import CuratedStyles
import SwiftUI

struct StylePickerSection: View {
    let selectedStyle: AppStyle
    let isEnabled: Bool
    let onSelect: (AppStyle) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(AppStyle.allCases) { style in
                StyleChip(
                    style: style,
                    tier: style.confidenceTier,
                    isSelected: selectedStyle == style
                ) {
                    onSelect(style)
                }
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }
}
