import SwiftUI

struct GenerableErrorsView: View {
    let viewModel: ErrorGeneratorViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GenerationCardSection(viewModel: viewModel)
                    ErrorCodePickerSection(
                        selectedError: viewModel.selectedError,
                        groupedErrors: viewModel.groupedErrorCatalog,
                        catalogLoadMessage: viewModel.catalogLoadMessage
                    ) { error in
                        viewModel.selectError(error)
                    }
                    StylePickerSection(
                        selectedStyle: viewModel.selectedStyle,
                        isEnabled: !viewModel.isGenerating
                    ) { style in
                        viewModel.selectStyle(style)
                    }
                }
                .padding()
                .animation(.default, value: viewModel.generationAnimationPhase)
            }
            .background(.fill.quaternary)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.monitorModelAvailability()
            }
        }
    }
}
