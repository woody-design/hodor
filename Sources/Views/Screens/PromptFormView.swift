import SwiftUI
import SwiftData

// MARK: - Focus & Layout

private enum FormField: Hashable {
    case body, title, snippet, shortcut
}

private struct FormInputStyle: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .focused($isFocused)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isFocused
                            ? Color.accentColor.opacity(0.5)
                            : Color.primary.opacity(0.1),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    fileprivate func formInputStyle() -> some View {
        modifier(FormInputStyle())
    }
}

/// Two-column row: fixed-width label on the left, content on the right.
private struct FormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

/// Shared Create/Edit form rendered inside a standard titled NSWindow.
struct PromptFormView: View {
    let mode: PromptFormMode

    @Environment(\.modelContext) private var modelContext
    @Query private var allPrompts: [PromptNote]

    @State private var bodyText: String = ""
    @State private var titleText: String = ""
    @State private var snippetTrigger: String = ""
    @State private var shortcutLetter: String = ""

    @State private var bodyError: String?
    @State private var snippetError: String?
    @State private var shortcutError: String?

    @FocusState private var focusedField: FormField?

    var body: some View {
        VStack(spacing: 0) {
            header
            contentArea
            buttonBar
        }
        .onAppear {
            loadExistingData()
            focusedField = .body
        }
    }

    // MARK: - Header

    private var header: some View {
        Text(mode.isEdit ? "Edit Prompt" : "New Prompt")
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        VStack(spacing: 0) {
            bodyRow
            titleRow
            snippetRow
            shortcutRow
            if mode.isEdit {
                usageRow
            }
        }
    }

    private var bodyRow: some View {
        FormRow(label: "Content") {
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: $bodyText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .body)
                    .formInputStyle()
                    .frame(minHeight: 80, maxHeight: .infinity)
                    .accessibilityLabel("Content")
                if let error = bodyError {
                    Text(error).font(.caption2).foregroundStyle(.red)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var titleRow: some View {
        FormRow(label: "Title") {
            VStack(alignment: .leading, spacing: 4) {
                TextField(
                    text: $titleText,
                    prompt: Text("Optional").foregroundStyle(.quaternary)
                ) { EmptyView() }
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .title)
                    .formInputStyle()
                    .accessibilityLabel("Title")
                Text("Optional — shown on the prompt card.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var snippetRow: some View {
        FormRow(label: "Keyword") {
            VStack(alignment: .leading, spacing: 4) {
                TextField(
                    text: $snippetTrigger,
                    prompt: Text("e.g. ;rewrite").foregroundStyle(.quaternary)
                ) { EmptyView() }
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .snippet)
                    .formInputStyle()
                    .accessibilityLabel("Keyword")
                Text("Type this in any text field to paste the prompt.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if let error = snippetError {
                    Text(error).font(.caption2).foregroundStyle(.red)
                }
            }
        }
    }

    private var shortcutRow: some View {
        FormRow(label: "Shortcut") {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Ctrl+Opt+")
                        .foregroundStyle(.secondary)
                    TextField(
                        text: $shortcutLetter,
                        prompt: Text("A-Z").foregroundStyle(.quaternary)
                    ) { EmptyView() }
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .shortcut)
                        .frame(width: 44)
                        .onChange(of: shortcutLetter) {
                            if shortcutLetter.count > 1 {
                                shortcutLetter = String(shortcutLetter.prefix(1))
                            }
                            shortcutLetter = shortcutLetter.uppercased()
                        }
                        .formInputStyle()
                        .accessibilityLabel("Shortcut letter")
                }
                Text("Single letter A\u{2013}Z. Press Ctrl+Opt+letter to use this prompt.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if let error = shortcutError {
                    Text(error).font(.caption2).foregroundStyle(.red)
                }
            }
        }
    }

    private var usageRow: some View {
        FormRow(label: "Usage") {
            Text(usageText)
                .foregroundStyle(.secondary)
        }
    }

    private var usageText: String {
        let count = mode.existingNote?.useCount ?? 0
        switch count {
        case 0: return "Never used"
        case 1: return "Used once"
        default: return "Used \(count) times"
        }
    }

    // MARK: - Buttons

    private var buttonBar: some View {
        HStack(spacing: 8) {
            if mode.isEdit {
                Button("Delete", role: .destructive) {
                    showDeleteConfirmation()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()

            Button("Cancel") {
                closeWindow()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Logic

    private func loadExistingData() {
        guard let note = mode.existingNote else { return }
        bodyText = note.body
        titleText = note.title ?? ""
        snippetTrigger = note.snippetTrigger ?? ""
        shortcutLetter = note.shortcutLetter ?? ""
    }

    private func save() {
        clearErrors()

        guard validate() else { return }

        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSnippet = snippetTrigger.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = mode.existingNote {
            existing.body = trimmedBody
            existing.title = trimmedTitle.isEmpty ? nil : trimmedTitle
            existing.snippetTrigger = trimmedSnippet.isEmpty ? nil : trimmedSnippet
            existing.shortcutLetter = shortcutLetter.isEmpty ? nil : shortcutLetter
        } else {
            let note = PromptNote(
                body: trimmedBody,
                title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                shortcutLetter: shortcutLetter.isEmpty ? nil : shortcutLetter,
                snippetTrigger: trimmedSnippet.isEmpty ? nil : trimmedSnippet
            )
            modelContext.insert(note)
        }

        try? modelContext.save()
        closeWindow()
    }

    private func validate() -> Bool {
        var valid = true

        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBody.isEmpty {
            bodyError = "Write something first"
            valid = false
        }

        if !shortcutLetter.isEmpty {
            let letter = shortcutLetter.uppercased()
            let validLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            if letter.count != 1 || !validLetters.contains(letter) {
                shortcutError = "Just one letter, A\u{2013}Z"
                valid = false
            } else {
                let editingID = mode.existingNote?.id
                let conflict = allPrompts.first {
                    $0.id != editingID && $0.shortcutLetter == letter
                }
                if let conflict {
                    let preview = conflict.title ?? String(conflict.body.prefix(30))
                    shortcutError = "Letter already assigned to \"\(preview)\""
                    valid = false
                }
            }
        }

        let trimmedSnippet = snippetTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSnippet.isEmpty {
            let editingID = mode.existingNote?.id
            for other in allPrompts where other.id != editingID {
                guard let otherTrigger = other.snippetTrigger else { continue }
                if otherTrigger == trimmedSnippet {
                    let preview = other.title ?? String(other.body.prefix(30))
                    snippetError = "Already in use by \"\(preview)\""
                    valid = false
                    break
                }
                if otherTrigger.hasPrefix(trimmedSnippet) || trimmedSnippet.hasPrefix(otherTrigger) {
                    snippetError = "Too similar to \"\(otherTrigger)\" — Hodor can't tell them apart"
                    valid = false
                    break
                }
            }
        }

        return valid
    }

    private func clearErrors() {
        bodyError = nil
        snippetError = nil
        shortcutError = nil
    }

    private func showDeleteConfirmation() {
        guard let note = mode.existingNote else { return }
        guard let window = NSApp.keyWindow else { return }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Delete this prompt?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                self.modelContext.delete(note)
                try? self.modelContext.save()
                window.close()
            }
        }
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
