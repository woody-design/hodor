import AppKit
import SwiftData
import CoreGraphics
import os.log

/// Handles the clipboard write + simulated Cmd+V paste flow.
@MainActor
final class AutoPasteService {
    static let shared = AutoPasteService()

    private let logger = Logger(subsystem: "com.promptpal.mac", category: "AutoPasteService")

    private init() {}

    func pastePrompt(_ prompt: PromptNote, context: ModelContext) {
        prompt.useCount += 1
        prompt.lastUsedAt = Date()
        do {
            try context.save()
        } catch {
            logger.error("Failed to save prompt usage metadata: \(error.localizedDescription)")
            context.rollback()
        }

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
