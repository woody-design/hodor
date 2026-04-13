import AppKit
import SwiftData
import CoreGraphics

/// Handles the clipboard write + simulated Cmd+V paste flow.
@MainActor
final class AutoPasteService {
    static let shared = AutoPasteService()

    private init() {}

    func pastePrompt(_ prompt: PromptNote, context: ModelContext) {
        prompt.useCount += 1
        prompt.lastUsedAt = Date()
        try? context.save()

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt.body, forType: .string)

        SidebarManager.shared.resignPanelKey()
        PreviousAppTracker.shared.restoreFocus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            self.simulatePaste()
            NSSound.beep()
        }
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
