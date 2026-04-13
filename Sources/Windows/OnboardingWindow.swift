import AppKit
import SwiftUI

/// Fixed-size centered window for the permission onboarding flow.
/// Closing this window without granting permission terminates the app.
final class OnboardingWindow: NSWindow {
    private var hostingView: NSHostingView<OnboardingView>?

    init(contentView: OnboardingView) {
        let size = NSSize(width: 440, height: 480)
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        self.title = "Hodor"
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true

        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = NSRect(origin: .zero, size: size)
        self.contentView = hosting
        self.hostingView = hosting

        self.setContentSize(size)
        self.isOpaque = true
        self.hasShadow = true
        self.center()
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false

        self.minSize = size
        self.maxSize = size
    }

    /// Replace the SwiftUI rootView to switch states.
    func updateView(_ view: OnboardingView) {
        hostingView?.rootView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
