import SwiftUI

/// Toast content view with title, description, and close button.
/// Figma 47:4286
struct ToastView: View {
    let title: String
    let description: String
    let onClose: () -> Void
    @AppStorage("recordingMode") private var recordingMode = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 222)
        .background {
            if recordingMode {
                Color.white.opacity(0.75)
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                Color.clear
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
            }
        }
        .clipShape(.rect(cornerRadius: 12))
    }
}
