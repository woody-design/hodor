import AppKit
import SwiftUI

/// Manages the sidebar panel lifecycle: show, hide, toggle, and dismiss.
@MainActor
final class SidebarManager: ObservableObject {
    static let shared = SidebarManager()

    @Published var isVisible = false
    @Published var dismissCount = 0

    private var panel: SidebarPanel?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var spaceChangeObserver: Any?
    private var screenChangeObserver: Any?

    private init() {}

    func configure(panel: SidebarPanel) {
        self.panel = panel
        observeSpaceChanges()
        observeScreenChanges()
    }

    func toggle() {
        if isVisible {
            dismiss()
        } else {
            show()
        }
    }

    func show() {
        guard let panel else { return }
        PreviousAppTracker.shared.snapshot()

        panel.updateFrame(position: currentSidebarPosition(), screen: resolvedScreen())
        panel.orderFront(nil)
        isVisible = true
        installClickMonitors()
    }

    func dismiss() {
        guard let panel else { return }
        isVisible = false
        dismissCount += 1
        removeClickMonitors()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, !self.isVisible else { return }
            panel.orderOut(nil)
        }
    }

    /// Resign the panel's key window status without hiding it.
    /// Called before restoreFocus() so the target app reliably receives keyboard events.
    func resignPanelKey() {
        guard let panel, panel.isKeyWindow else { return }
        panel.resignKey()
    }

    func currentSidebarPosition() -> SidebarPosition {
        let raw = UserDefaults.standard.string(forKey: "sidebarPosition") ?? "left"
        return SidebarPosition(rawValue: raw) ?? .left
    }

    /// Returns the screen the sidebar should appear on based on user preference.
    /// Falls back to the active screen when the preferred screen is unavailable.
    func resolvedScreen() -> NSScreen {
        let pref = UserDefaults.standard.string(forKey: "sidebarScreen") ?? "followFocus"
        switch pref {
        case "primary":
            return NSScreen.screens.first ?? NSScreen.main!
        case "secondary":
            return NSScreen.screens.dropFirst().first
                ?? NSScreen.main
                ?? NSScreen.screens.first!
        default:
            return NSScreen.main ?? NSScreen.screens.first!
        }
    }

    // MARK: - Click-outside dismissal

    private func installClickMonitors() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let clickPoint = NSEvent.mouseLocation
                guard self.shouldDismissForGlobalClick(at: clickPoint) else { return }
                self.dismiss()
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self else { return event }
            // Don't dismiss if click is in our sidebar panel or in our dialog windows
            if event.window === self.panel { return event }
            if event.window is SidebarPanel { return event }
            // Clicks in PromptFormWindow, Settings, or Alert don't dismiss
            return event
        }
    }

    private func removeClickMonitors() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }

    /// Global monitors do not provide window context; use click location to avoid
    /// dismissing when users click inside our own visible windows (sidebar/dialogs).
    private func shouldDismissForGlobalClick(at point: NSPoint) -> Bool {
        for window in NSApp.windows where window.isVisible {
            if window.frame.contains(point) {
                return false
            }
        }
        return true
    }

    // MARK: - Space change dismissal

    private func observeSpaceChanges() {
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.isVisible == true {
                    self?.dismiss()
                }
            }
        }
    }

    // MARK: - Screen configuration changes

    private func observeScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isVisible, let panel = self.panel else { return }
                panel.updateFrame(position: self.currentSidebarPosition(), screen: self.resolvedScreen())
            }
        }
    }
}
