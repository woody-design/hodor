import AppKit
import SwiftUI

/// Standard titled NSWindow for dialogs (PromptForm, Settings).
/// System provides solid background, ~18pt rounded corners, window shadow,
/// and traffic light buttons automatically.
final class DialogWindow<Content: View>: NSWindow {
    init(
        title: String,
        contentView: Content,
        width: CGFloat,
        height: CGFloat,
        minSize: NSSize,
        maxSize: NSSize
    ) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        self.title = title
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.minSize = minSize
        self.maxSize = maxSize

        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView
        self.isOpaque = true
        self.hasShadow = true
        self.center()
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
