import AppKit

/// Tracks the previously-focused application so focus can be restored
/// before auto-paste or after dialog close.
@MainActor
final class PreviousAppTracker {
    static let shared = PreviousAppTracker()

    private(set) var previousApp: NSRunningApplication?
    private var workspaceObserver: Any?

    private init() {
        startObserving()
    }

    /// Snapshot the current frontmost app. Call before showing sidebar or dialogs.
    func snapshot() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = frontmost
        }
    }

    /// Restore focus to the previously tracked app.
    @discardableResult
    func restoreFocus() -> Bool {
        guard let app = previousApp else { return false }
        return app.activate(from: NSRunningApplication.current)
    }

    private func startObserving() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
            Task { @MainActor in
                self?.previousApp = app
            }
        }
    }
}
