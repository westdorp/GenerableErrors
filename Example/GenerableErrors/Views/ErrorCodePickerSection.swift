import SwiftUI

struct ErrorCodePickerSection: View {
    let selectedError: HTTPError?
    let groupedErrors: [(category: HTTPErrorCategory, errors: [HTTPError])]
    let catalogLoadMessage: String?
    let onSelect: (HTTPError) -> Void
    @State private var showErrorPicker = false

    private var canPresentPicker: Bool {
        !groupedErrors.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showErrorPicker = true
            } label: {
                HStack(spacing: 12) {
                    if let error = selectedError {
                        Text("\(error.code)")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundStyle(AppGradient.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(error.name)
                                .font(.headline)
                            Text(error.rfc)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "number")
                            .font(.title2)
                            .foregroundStyle(AppGradient.accent)
                        Text("Choose an error code")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(.background, in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canPresentPicker)
            .opacity(canPresentPicker ? 1 : 0.6)
            .accessibilityLabel(
                selectedError.map { "\($0.statusCode) \($0.name)" } ?? "Choose an error code"
            )
            .sheet(isPresented: $showErrorPicker) {
                ErrorCodePickerSheet(
                    selectedError: selectedError,
                    groupedErrors: groupedErrors,
                    emptyStateMessage: catalogLoadMessage,
                    onSelect: { error in
                        onSelect(error)
                        showErrorPicker = false
                    }
                )
            }

            if let catalogLoadMessage {
                Text(catalogLoadMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
