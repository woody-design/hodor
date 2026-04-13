import AppKit
import SwiftUI

/// Transparent `NSPopUpButton` overlay that provides native click-to-menu
/// behavior. The visual appearance is handled by a SwiftUI label underneath;
/// this view only contributes the hit area and the dropdown menu.
struct SortPopUpButton: NSViewRepresentable {
    @Binding var sortModeRaw: String
    let activeSortMode: SortMode

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.isBordered = false
        button.alphaValue = 0.02
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentHuggingPriority(.defaultLow, for: .vertical)
        populateMenu(button, coordinator: context.coordinator)
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        populateMenu(button, coordinator: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sortModeRaw: $sortModeRaw)
    }

    private func populateMenu(_ button: NSPopUpButton, coordinator: Coordinator) {
        button.removeAllItems()
        for mode in SortMode.allCases {
            let item = NSMenuItem(
                title: mode.displayName,
                action: #selector(Coordinator.itemSelected(_:)),
                keyEquivalent: ""
            )
            item.target = coordinator
            item.representedObject = mode.rawValue
            item.state = (mode == activeSortMode) ? .on : .off
            button.menu?.addItem(item)
        }
        if let index = SortMode.allCases.firstIndex(of: activeSortMode) {
            button.selectItem(at: index)
        }
    }

    final class Coordinator: NSObject {
        var sortModeRaw: Binding<String>

        init(sortModeRaw: Binding<String>) {
            self.sortModeRaw = sortModeRaw
        }

        @objc func itemSelected(_ sender: NSMenuItem) {
            if let value = sender.representedObject as? String {
                sortModeRaw.wrappedValue = value
            }
        }
    }
}
