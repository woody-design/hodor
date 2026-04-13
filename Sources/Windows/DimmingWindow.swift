import AppKit

/// Fullscreen semi-transparent overlay shown behind dialog windows
/// to signal modality. Purely visual — does not intercept clicks.
final class DimmingWindow: NSWindow {
    init(for screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )

        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.3)
        level = .floating
        ignoresMouseEvents = true
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces]
        isReleasedWhenClosed = false
    }
}
