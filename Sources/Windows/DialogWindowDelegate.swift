import AppKit

/// Handles window close lifecycle for dialog windows.
/// Single cleanup path: dimming dismissal, reference cleanup,
/// and focus restoration all happen here regardless of how
/// the window was closed (CTA button, traffic light, Cmd+W).
final class DialogWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
