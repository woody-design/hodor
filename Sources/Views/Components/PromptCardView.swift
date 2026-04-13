import SwiftUI

/// The core card view for displaying a single prompt.
/// Figma 87:3279
struct PromptCardView: View {
    let prompt: PromptNote
    let onTap: () -> Void
    let onEdit: () -> Void

    @State private var isChevronHovered = false
    @State private var isHovered = false
    @AppStorage("recordingMode") private var recordingMode = false

    private static let tileShape = RoundedRectangle(cornerRadius: 12)

    var body: some View {
        cardBase
            .overlay(
                Self.tileShape
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(isHovered ? 0.12 : 0.08), radius: isHovered ? 5 : 3, y: 1)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var cardBase: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            bodyRow
            if prompt.shortcutLetter != nil || prompt.snippetTrigger != nil {
                snippetShortcutRow
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.primary.opacity(isHovered ? 0.08 : 0.04),
            in: .rect(cornerRadius: 12)
        )

        if recordingMode {
            content
        } else {
            content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
    }

    private var hasTitle: Bool {
        if let title = prompt.title, !title.isEmpty { return true }
        return false
    }

    private var bodyRow: some View {
        HStack(alignment: .top, spacing: 4) {
            if hasTitle {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title!)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                    Text(prompt.body)
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(prompt.body)
                    .font(.system(size: 13, weight: .semibold))
                    .lineSpacing(1)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onEdit) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isChevronHovered ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(nsColor: .secondaryLabelColor)))
                    .frame(width: 6, height: 20)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isChevronHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var snippetShortcutRow: some View {
        HStack(spacing: 16) {
            if let snippet = prompt.snippetTrigger {
                Text(snippet)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }

            if let letter = prompt.shortcutLetter {
                Text("Ctrl+Opt+\(letter)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
