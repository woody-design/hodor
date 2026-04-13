import AppKit
import SwiftUI

/// Manages the toast notification window.
/// Toast appears at bottom center of screen, 48pt above Dock.
@MainActor
final class ToastWindowController {
    static let shared = ToastWindowController()

    private var window: NSWindow?
    private var dismissTimer: Timer?

    private init() {}

    func show(title: String, description: String) {
        dismiss()

        let toastView = ToastView(
            title: title,
            description: description,
            onClose: { [weak self] in self?.dismiss() }
        )

        let hostingView = NSHostingView(rootView: toastView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        positionAtBottom(window)
        window.orderFront(nil)
        self.window = window

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        window?.orderOut(nil)
        window = nil
    }

    private func positionAtBottom(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let dockHeight = visibleFrame.minY - screenFrame.minY
        let windowSize = window.frame.size
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + dockHeight + 48
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
