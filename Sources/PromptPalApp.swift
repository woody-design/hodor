import SwiftUI

@main
struct PromptPalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    Task { @MainActor in
                        AppDelegate.shared?.openSettingsFromCommand()
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
