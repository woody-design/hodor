import SwiftUI

/// Full-width pill button for creating a new prompt.
/// Figma 47:4198
struct ButtonAddView: View {
    let action: () -> Void

    @State private var isHovered = false
    @AppStorage("recordingMode") private var recordingMode = false

    var body: some View {
        Button(action: action) {
            buttonBase
                .shadow(color: .black.opacity(isHovered ? 0.12 : 0.08), radius: isHovered ? 5 : 3, y: 1)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var buttonBase: some View {
        let content = HStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
            Text("New Prompt")
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(
            Color.primary.opacity(isHovered ? 0.08 : 0.04),
            in: Capsule()
        )

        if recordingMode {
            content
        } else {
            content.glassEffect(.regular.interactive(), in: Capsule())
        }
    }
}
