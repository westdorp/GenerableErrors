import SwiftUI

struct ErrorCodeHero: View {
    let error: HTTPError

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(error.code)")
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundStyle(AppGradient.accent)

            Text(error.name)
                .font(.title2.weight(.semibold))

            Text(error.rfc)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.fill.tertiary, in: .capsule)

            Text(error.explanation)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
}
