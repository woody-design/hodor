import AppKit

/// Monitors mouse position and shows the sidebar when the cursor dwells
/// at the configured screen edge, mimicking macOS Dock auto-show behavior.
@MainActor
final class ScreenEdgeTriggerService {
    static let shared = ScreenEdgeTriggerService()

    private static let dwellDelay: TimeInterval = 0.2
    private static let outerEdgeWidth: CGFloat = 3
    private static let sharedEdgeWidth: CGFloat = 12
    private static let sharedEdgeTolerance: CGFloat = 1

    private var monitor: Any?
    private var dwellWork: DispatchWorkItem?
    private var armed = true

    private init() {}

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor in
                self?.handleMouseMoved()
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        cancelDwell()
    }

    // MARK: - Detection

    private func handleMouseMoved() {
        guard UserDefaults.standard.bool(forKey: "screenEdgeTriggerEnabled") else {
            cancelDwell()
            armed = true
            return
        }
        guard !SidebarManager.shared.isVisible else {
            cancelDwell()
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let screen = SidebarManager.shared.resolvedScreen()
        let frame = screen.frame
        let insideVerticalRange = mouseLocation.y >= frame.minY && mouseLocation.y <= frame.maxY
        let position = SidebarManager.shared.currentSidebarPosition()
        let edgeWidth = triggerWidth(
            for: position,
            screen: screen,
            mouseY: mouseLocation.y
        )

        let atEdge: Bool
        switch position {
        case .left:
            atEdge = insideVerticalRange
                && mouseLocation.x >= frame.minX
                && mouseLocation.x <= frame.minX + edgeWidth
        case .right:
            atEdge = insideVerticalRange
                && mouseLocation.x <= frame.maxX
                && mouseLocation.x >= frame.maxX - edgeWidth
        }

        if atEdge {
            guard armed else { return }
            guard dwellWork == nil else { return }

            let work = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    guard let self, self.armed else { return }
                    self.armed = false
                    self.dwellWork = nil
                    SidebarManager.shared.show()
                }
            }
            dwellWork = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Self.dwellDelay,
                execute: work
            )
        } else {
            cancelDwell()
            armed = true
        }
    }

    private func cancelDwell() {
        dwellWork?.cancel()
        dwellWork = nil
    }

    private func triggerWidth(for position: SidebarPosition, screen: NSScreen, mouseY: CGFloat) -> CGFloat {
        sharesEdgeWithAnotherScreen(position: position, screen: screen, mouseY: mouseY)
            ? Self.sharedEdgeWidth
            : Self.outerEdgeWidth
    }

    private func sharesEdgeWithAnotherScreen(position: SidebarPosition, screen: NSScreen, mouseY: CGFloat) -> Bool {
        let frame = screen.frame

        for other in NSScreen.screens where other !== screen {
            let otherFrame = other.frame
            guard verticalRangesOverlap(frame, otherFrame),
                  mouseY >= max(frame.minY, otherFrame.minY),
                  mouseY <= min(frame.maxY, otherFrame.maxY)
            else {
                continue
            }

            switch position {
            case .left:
                if abs(otherFrame.maxX - frame.minX) <= Self.sharedEdgeTolerance {
                    return true
                }
            case .right:
                if abs(otherFrame.minX - frame.maxX) <= Self.sharedEdgeTolerance {
                    return true
                }
            }
        }

        return false
    }

    private func verticalRangesOverlap(_ lhs: NSRect, _ rhs: NSRect) -> Bool {
        max(lhs.minY, rhs.minY) < min(lhs.maxY, rhs.maxY)
    }
}
