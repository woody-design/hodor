import AppKit
import ApplicationServices
import CoreGraphics

/// Owns Accessibility permission state.
/// Single permission gate — Input Monitoring is NOT required for active CGEventTap.
@MainActor
final class PermissionService {
    static let shared = PermissionService()

    private(set) var accessibilityGranted: Bool = false

    private init() {}

    /// Updates permission state. Uses CGEventTap creation as fallback
    /// because AXIsProcessTrusted() can return stale cached values.
    /// Pass `tryEventTap: false` during onboarding to avoid triggering
    /// the system permission dialog before the user clicks Grant Access.
    func check(tryEventTap: Bool = true) {
        if AXIsProcessTrusted() {
            accessibilityGranted = true
            return
        }
        accessibilityGranted = tryEventTap ? canCreateEventTap() : false
    }

    /// Whether the onboarding gate should be shown.
    var shouldShowOnboarding: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-forceOnboarding") {
            return true
        }
        #endif
        return !accessibilityGranted
    }

    /// Opens System Settings → Accessibility and auto-adds the app to the list.
    func requestAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private nonisolated func canCreateEventTap() -> Bool {
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: permissionCheckCallback,
            userInfo: nil
        )
        guard let tap else { return false }
        CFMachPortInvalidate(tap)
        return true
    }
}

private func permissionCheckCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    Unmanaged.passRetained(event)
}
