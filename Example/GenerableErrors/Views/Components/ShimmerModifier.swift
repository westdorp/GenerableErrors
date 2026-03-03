import SwiftUI

struct ShimmerModifier: ViewModifier {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content.overlay { shimmerOverlay }
        } else {
            content
        }
    }

    private var shimmerOverlay: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let phase = elapsed.truncatingRemainder(dividingBy: 2.0) / 2.0

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.12), location: 0.5),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(25))
                .offset(x: shimmerOffset(for: phase))
                .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: 16))
    }

    private func shimmerOffset(for phase: Double) -> CGFloat {
        CGFloat(-200 + phase * 600)
    }
}

extension View {
    func shimmer(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
