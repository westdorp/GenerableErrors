import CuratedStyles
import SwiftUI

private extension ErrorStyleConfidenceTier {
    var tintColor: Color {
        switch self {
        case .high: .teal
        case .medium: .indigo
        case .persona: .orange
        }
    }
}

struct StyleChip: View {
    let style: AppStyle
    let tier: ErrorStyleConfidenceTier
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(style.label)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AnyShapeStyle(tier.tintColor) : AnyShapeStyle(.fill.tertiary),
                    in: .rect(cornerRadius: 10)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(reduceMotion ? 1.0 : (isSelected ? 1.0 : 0.97))
        .animation(
            reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6),
            value: isSelected
        )
        .accessibilityLabel(style.label)
        .accessibilityHint("Sets the generation style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
