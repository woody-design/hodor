import AppKit
import Combine
import CoreGraphics
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private var statusBarItem: NSStatusItem?
    private var sidebarPanel: SidebarPanel?
    private var modelContainer: ModelContainer?

    var promptFormWindow: NSWindow?
    var settingsWindow: NSWindow?

    private var dimmingWindow: DimmingWindow?
    private var promptFormDelegate: DialogWindowDelegate?
    private var settingsDelegate: DialogWindowDelegate?
    private var onboardingWindow: OnboardingWindow?
    private var onboardingDelegate: OnboardingWindowDelegate?
    private var onboardingPollTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()
    private var operationStarted = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        NSApp.setActivationPolicy(.regular)

        registerDefaults()
        setupModelContainer()

        // Permission gate — skip event tap to avoid triggering system dialog before onboarding
        PermissionService.shared.check(tryEventTap: false)
        if PermissionService.shared.shouldShowOnboarding {
            showOnboarding()
        } else {
            proceedToNormalOperation()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// When user clicks Dock icon or Cmd+Tab to the app
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let onboarding = onboardingWindow, onboarding.isVisible {
            onboarding.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return false
        }
        SidebarManager.shared.toggle()
        PreviousAppTracker.shared.restoreFocus()
        return false
    }

    // MARK: - Setup

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "screenEdgeTriggerEnabled": true,
            "appearanceMode": "system"
        ])
    }

    private func setupModelContainer() {
        do {
            modelContainer = try ModelContainer(for: PromptNote.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        let view = makeOnboardingView(granted: false)
        let window = OnboardingWindow(contentView: view)

        onboardingDelegate = OnboardingWindowDelegate { [weak self] in
            guard let self else { return }
            PermissionService.shared.check()
            if PermissionService.shared.accessibilityGranted {
                guard !operationStarted else { return }
                onboardingPollTask?.cancel()
                onboardingPollTask = nil
                proceedToNormalOperation()
                SidebarManager.shared.show()
            } else {
                NSApp.terminate(nil)
            }
        }
        window.delegate = onboardingDelegate

        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()

        // Poll and replace rootView when permission is granted
        onboardingPollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                PermissionService.shared.check(tryEventTap: false)
                if PermissionService.shared.accessibilityGranted {
                    self.onboardingWindow?.updateView(
                        self.makeOnboardingView(granted: true)
                    )
                    break
                }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    private func makeOnboardingView(granted: Bool) -> OnboardingView {
        OnboardingView(
            granted: granted,
            onGetStarted: { [weak self] in
                self?.dismissOnboarding()
            }
        )
    }

    private func dismissOnboarding() {
        onboardingPollTask?.cancel()
        onboardingPollTask = nil
        onboardingWindow?.close()   // → triggers windowWillClose → handles initialization
        onboardingWindow = nil
        onboardingDelegate = nil
    }

    // MARK: - Normal Operation

    private func proceedToNormalOperation() {
        guard !operationStarted else { return }
        operationStarted = true

        applyAppearance()
        setupMenuBarIcon()
        setupSidebarPanel()
        observeSidebarVisibility()
        seedDataIfNeeded()
        startHotkeyService()
        ScreenEdgeTriggerService.shared.start()

        // Safety net: permission granted but event tap failed (needs restart)
        if HotkeyService.shared.eventTap == nil {
            showRestartAlert()
        }
    }

    private func applyAppearance() {
        let mode = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        switch mode {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil
        }
    }

    private func showRestartAlert() {
        let alert = NSAlert()
        alert.messageText = "Hodor needs to restart"
        alert.informativeText = "Permission granted — one restart to finish setup."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            relaunch()
        } else {
            NSApp.terminate(nil)
        }
    }

    private func relaunch() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBarIcon() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusBarItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        if let image = NSImage(systemSymbolName: "h.square", accessibilityDescription: "Hodor")?
            .withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "H"
        }
        button.target = self
        button.action = #selector(menuBarClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func menuBarClicked(_ sender: NSStatusBarButton) {
        showMenuBarContextMenu(sender)
    }

    private func showMenuBarContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        let sidebarTitle = SidebarManager.shared.isVisible ? "Hide Sidebar" : "Show Sidebar"
        let sidebarItem = menu.addItem(
            withTitle: sidebarTitle,
            action: #selector(toggleSidebarFromMenu),
            keyEquivalent: " "
        )
        sidebarItem.keyEquivalentModifierMask = [.control, .option]
        sidebarItem.target = self

        menu.addItem(.separator())
        menu.addItem(withTitle: "New Prompt", action: #selector(newPromptFromMenu), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: "Settings", action: #selector(showSettingsFromMenu), keyEquivalent: ",")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            .target = self

        statusBarItem?.menu = menu
        statusBarItem?.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusBarItem?.menu = nil
        }
    }

    @objc private func toggleSidebarFromMenu() {
        SidebarManager.shared.toggle()
    }

    @objc private func newPromptFromMenu() {
        showPromptForm(mode: .create)
    }

    @objc private func showSettingsFromMenu() {
        showSettings()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func observeSidebarVisibility() {
        SidebarManager.shared.$isVisible
            .sink { [weak self] visible in
                DispatchQueue.main.async {
                    self?.statusBarItem?.button?.highlight(visible)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sidebar Panel

    private func setupSidebarPanel() {
        guard let container = modelContainer else { return }

        let sidebarView = SidebarContentView()
            .modelContainer(container)

        let hostingView = NSHostingView(rootView: sidebarView)
        let panel = SidebarPanel(contentView: hostingView)
        self.sidebarPanel = panel
        SidebarManager.shared.configure(panel: panel)
    }

    // MARK: - Window Management

    func showPromptForm(mode: PromptFormMode) {
        if let existing = promptFormWindow {
            existing.close()
            promptFormWindow = nil
        }

        guard let container = modelContainer else {
#if DEBUG
            print("showPromptForm aborted: modelContainer is nil")
#endif
            return
        }

        let formView = PromptFormView(mode: mode)
            .modelContainer(container)

        let window = DialogWindow(
            title: mode.isEdit ? "Edit Prompt" : "New Prompt",
            contentView: formView,
            width: 480,
            height: 540,
            minSize: NSSize(width: 420, height: 480),
            maxSize: NSSize(width: 600, height: 700)
        )

        promptFormDelegate = DialogWindowDelegate { [weak self] in
            self?.dismissDimming()
            self?.promptFormWindow = nil
            PreviousAppTracker.shared.restoreFocus()
        }
        window.delegate = promptFormDelegate

        showDimming(for: window)
        promptFormWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func showSettings() {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView()
        let window = DialogWindow(
            title: "Settings",
            contentView: settingsView,
            width: 400,
            height: 380,
            minSize: NSSize(width: 360, height: 320),
            maxSize: NSSize(width: 500, height: 400)
        )

        settingsDelegate = DialogWindowDelegate { [weak self] in
            self?.dismissDimming()
            self?.settingsWindow = nil
            self?.applyAppearance()
            PreviousAppTracker.shared.restoreFocus()
        }
        window.delegate = settingsDelegate

        showDimming(for: window)
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    // MARK: - Dimming

    private func showDimming(for dialogWindow: NSWindow) {
        let screen = dialogWindow.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let dimming = DimmingWindow(for: screen)
        dimmingWindow = dimming
        dimming.orderFront(nil)
        dialogWindow.level = .floating
        dialogWindow.order(.above, relativeTo: dimming.windowNumber)
    }

    private func dismissDimming() {
        dimmingWindow?.close()
        dimmingWindow = nil
    }

    // MARK: - Data

    private func seedDataIfNeeded() {
        guard let container = modelContainer else { return }
        SeedData.seedIfNeeded(context: container.mainContext)
    }

    private func startHotkeyService() {
        guard let container = modelContainer else { return }
        HotkeyService.shared.start(container: container)
    }
}

// MARK: - Onboarding Window Delegate

private final class OnboardingWindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
