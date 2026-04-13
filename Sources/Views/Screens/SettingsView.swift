import SwiftUI

/// Settings window content rendered inside a standard titled NSWindow.
struct SettingsView: View {
    @AppStorage("sidebarPosition") private var sidebarPosition: String = "left"
    @AppStorage("screenEdgeTriggerEnabled") private var screenEdgeTriggerEnabled: Bool = true
    @AppStorage("sidebarScreen") private var sidebarScreen: String = "followFocus"
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    @State private var selectedPosition: String = "left"
    @State private var selectedEdgeTrigger: Bool = true
    @State private var selectedScreen: String = "followFocus"
    @State private var selectedAppearance: String = "system"

    private var hasMultipleScreens: Bool {
        NSScreen.screens.count > 1
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Form {
                Section {
                    if hasMultipleScreens {
                        Picker("Display", selection: $selectedScreen) {
                            Text("Active screen").tag("followFocus")
                            Text("Main display").tag("primary")
                            Text("Secondary display").tag("secondary")
                        }
                        Text("The main display has the menu bar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Sidebar position", selection: $selectedPosition) {
                        Text("Left").tag("left")
                        Text("Right").tag("right")
                    }
                    .pickerStyle(.radioGroup)

                    Toggle("Show sidebar on hover at screen edge", isOn: $selectedEdgeTrigger)

                    Picker("Appearance", selection: $selectedAppearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            .formStyle(.grouped)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Cancel") {
                    closeWindow()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                Button("Save") {
                    sidebarPosition = selectedPosition
                    screenEdgeTriggerEnabled = selectedEdgeTrigger
                    sidebarScreen = selectedScreen
                    appearanceMode = selectedAppearance
                    closeWindow()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear {
            selectedPosition = sidebarPosition
            selectedEdgeTrigger = screenEdgeTriggerEnabled
            selectedScreen = sidebarScreen
            selectedAppearance = appearanceMode
        }
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
