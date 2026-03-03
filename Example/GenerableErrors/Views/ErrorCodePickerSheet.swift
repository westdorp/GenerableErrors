import SwiftUI

struct ErrorCodePickerSheet: View {
    let selectedError: HTTPError?
    let groupedErrors: [(category: HTTPErrorCategory, errors: [HTTPError])]
    let emptyStateMessage: String?
    let onSelect: (HTTPError) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if groupedErrors.isEmpty {
                    ContentUnavailableView(
                        "Error Catalog Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(
                            emptyStateMessage ?? "No HTTP error catalog entries are available."
                        )
                    )
                } else {
                    List {
                        ForEach(groupedErrors, id: \.category) { group in
                            Section(group.category.rawValue) {
                                ForEach(group.errors) { error in
                                    Button {
                                        onSelect(error)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text("\(error.code)")
                                                .font(
                                                    .system(
                                                        .body,
                                                        design: .monospaced,
                                                        weight: .semibold
                                                    )
                                                )
                                                .frame(width: 40, alignment: .trailing)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(error.name)
                                                    .font(.body.weight(.medium))
                                                Text(error.explanation)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(2)
                                            }

                                            Spacer()

                                            if selectedError?.id == error.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.tint)
                                            }
                                        }
                                        .contentShape(.rect)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("HTTP Error Codes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
