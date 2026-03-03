import GenerableErrors
import SwiftUI

struct GenerationCardSection: View {
    let viewModel: ErrorGeneratorViewModel
    @State private var generationCompletionCount = 0
    @State private var staggerPhase = 0
    @State private var showActionRow = false
    @State private var isCompletionBounced = false
    @State private var idleIconOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let heroMinHeight: CGFloat = 280

    var body: some View {
        Group {
            switch viewModel.generationState {
            case .idle:
                emptyStateCard
            case .codeSelected:
                educationalCard
            case .generating:
                generatedContentCard(isStreaming: true)
            case .generated:
                generatedContentCard(isStreaming: false)
            case .error(let failure):
                errorCard(failure: failure)
            }
        }
        .onChange(of: viewModel.generationState) { oldState, newState in
            guard case .generated = newState else { return }
            guard case .generated = oldState else {
                generationCompletionCount &+= 1
                UIAccessibility.post(notification: .announcement, argument: "Generation complete")
                return
            }
        }
        .sensoryFeedback(.success, trigger: generationCompletionCount)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 44))
                .foregroundStyle(AppGradient.accent.opacity(0.4))
                .offset(y: reduceMotion ? 0 : idleIconOffset)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        idleIconOffset = -4
                    }
                }
            Text("Choose an error code to start")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: heroMinHeight)
        .padding(20)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var educationalCard: some View {
        if let error = viewModel.selectedError {
            VStack(alignment: .leading, spacing: 16) {
                ErrorCodeHero(error: error)
                    .staggerReveal(phase: staggerPhase, step: 0, reduceMotion: reduceMotion)

                if let message = viewModel.modelAvailability.unavailabilityMessage {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                generateButton
                    .staggerReveal(phase: staggerPhase, step: 1, reduceMotion: reduceMotion)
            }
            .frame(minHeight: heroMinHeight, alignment: .top)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background.secondary)
                    .overlay(alignment: .leading) {
                        accentBar(color: AppGradient.accent)
                    }
                    .clipShape(.rect(cornerRadius: 16))
            }
            .onAppear { triggerStagger(steps: 2) }
            .onChange(of: viewModel.selectedError) { triggerStagger(steps: 2) }
        }
    }

    private func generatedContentCard(isStreaming: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let partial = viewModel.currentResult {
                if let meaning = partial.meaning {
                    Text(meaning)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .contentTransition(.opacity)
                }

                if let message = partial.message {
                    Text(message)
                        .font(.title3.weight(.medium))
                        .lineSpacing(4)
                        .contentTransition(.opacity)
                }
            }

            if !isStreaming {
                regenerateButton
                    .opacity(showActionRow ? 1 : 0)
                    .offset(y: showActionRow ? 0 : 8)
            }
        }
        .animation(.easeOut, value: streamedContentAnimationKey)
        .frame(minHeight: heroMinHeight, alignment: .top)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isStreaming ? AppGradient.subtle : Color.clear,
            in: .rect(cornerRadius: 16)
        )
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .shimmer(isActive: isStreaming)
        .scaleEffect(isCompletionBounced ? 1.0 : 0.98)
        .onChange(of: isStreaming) { wasStreaming, nowStreaming in
            guard wasStreaming && !nowStreaming else {
                if nowStreaming {
                    showActionRow = false
                    isCompletionBounced = false
                }
                return
            }
            if reduceMotion {
                showActionRow = true
                isCompletionBounced = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isCompletionBounced = true
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8).delay(0.1)) {
                    showActionRow = true
                }
            }
        }
    }

    private var streamedContentAnimationKey: String {
        "\(viewModel.currentResult?.meaning ?? "")|\(viewModel.currentResult?.message ?? "")"
    }

    private func errorCard(failure: ErrorGeneration.FailureState) -> some View {
        let guidance = failure.error.recoveryGuidance
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(guidance.title)
                    .font(.headline)
            }

            Text(failure.error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(guidance.steps.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            generateButton
        }
        .frame(minHeight: heroMinHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background.secondary)
                .overlay(alignment: .leading) {
                    accentBar(color: .orange)
                }
                .clipShape(.rect(cornerRadius: 16))
        }
    }

    private var generateButton: some View {
        Button {
            viewModel.generate()
        } label: {
            Label("Generate", systemImage: "wand.and.stars")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppGradient.accent)
        .controlSize(.large)
        .disabled(!viewModel.canGenerate)
    }

    private var regenerateButton: some View {
        Button {
            viewModel.generate()
        } label: {
            Label("Reroll", systemImage: "dice")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(!viewModel.canGenerate)
    }

    private func accentBar(color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 3)
    }

    private func triggerStagger(steps: Int) {
        staggerPhase = 0
        guard !reduceMotion else {
            staggerPhase = steps
            return
        }
        for step in 0..<steps {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8).delay(Double(step) * 0.05)) {
                staggerPhase = step + 1
            }
        }
    }
}

private struct StaggerRevealModifier: ViewModifier {
    let phase: Int
    let step: Int
    let reduceMotion: Bool

    private var isRevealed: Bool { phase > step }

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 12)
        }
    }
}

private extension View {
    func staggerReveal(phase: Int, step: Int, reduceMotion: Bool) -> some View {
        modifier(StaggerRevealModifier(phase: phase, step: step, reduceMotion: reduceMotion))
    }
}
