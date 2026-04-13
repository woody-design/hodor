import AppKit

/// Monitors mouse position and shows the sidebar when the cursor dwells
/// at the configured screen edge, mimicking macOS Dock auto-show behavior.
@MainActor
final class ScreenEdgeTriggerService {
    static let shared = ScreenEdgeTriggerService()

    private static let dwellDelay: TimeInterval = 0.2

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
        guard UserDefaults.standard.bool(forKey: "screenEdgeTriggerEnabled") else { return }
        guard !SidebarManager.shared.isVisible else { return }

        let mouseX = NSEvent.mouseLocation.x
        let screen = SidebarManager.shared.resolvedScreen()
        let frame = screen.frame

        let position = SidebarManager.shared.currentSidebarPosition()
        let atEdge: Bool
        switch position {
        case .left:
            atEdge = mouseX <= frame.minX + 1
        case .right:
            atEdge = mouseX >= frame.maxX - 1
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
}
