import AppKit
import SwiftUI

/// NSPanel-based sidebar that overlays without stealing focus from the target app.
/// Uses `.nonactivatingPanel` style mask so clicking buttons in the panel
/// does not deactivate the frontmost application.
final class SidebarPanel: NSPanel {
    init(contentView: NSView, position: SidebarPosition = .left) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: true
        )

        self.contentView = contentView
        isFloatingPanel = true
        level = .floating
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        updateFrame(position: position, screen: NSScreen.screens.first ?? NSScreen.main!)
    }

    private let panelWidth: CGFloat = 320
    private let verticalInset: CGFloat = 12
    private let edgeGap: CGFloat = 6

    func updateFrame(position: SidebarPosition, screen: NSScreen) {
        let screenFrame = screen.visibleFrame

        let origin: NSPoint
        switch position {
        case .left:
            origin = NSPoint(x: screenFrame.minX + edgeGap, y: screenFrame.minY + verticalInset)
        case .right:
            origin = NSPoint(x: screenFrame.maxX - panelWidth - edgeGap, y: screenFrame.minY + verticalInset)
        }

        setFrame(
            NSRect(x: origin.x, y: origin.y, width: panelWidth, height: screenFrame.height - 2 * verticalInset),
            display: true
        )
    }

    /// Override to allow the panel to become key when text fields need input.
    override var canBecomeKey: Bool { true }
}

enum SidebarPosition: String, CaseIterable {
    case left
    case right
}
