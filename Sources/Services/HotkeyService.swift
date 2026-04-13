import AppKit
import CoreGraphics
import SwiftData
import os.log

/// Single CGEventTap that handles:
/// 1. Global hotkey (Ctrl+Opt+Space) — toggle sidebar
/// 2. Per-prompt shortcuts (Ctrl+Opt+{letter}) — direct auto-paste
/// 3. Snippet expansion — rolling keystroke buffer with trigger matching
@MainActor
final class HotkeyService {
    static let shared = HotkeyService()

    nonisolated(unsafe) var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var snippetBuffer: String = ""
    private var snippetTimer: Timer?
    private var modelContainer: ModelContainer?

    private let logger = Logger(subsystem: "com.promptpal.mac", category: "HotkeyService")

    private init() {}

    func start(container: ModelContainer) {
        self.modelContainer = container
        installEventTap()
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Event Tap

    @discardableResult
    private func installEventTap() -> Bool {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyCallback,
            userInfo: refcon
        ) else {
            logger.error("Failed to create CGEventTap — Accessibility permission likely not granted")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        logger.info("CGEventTap installed successfully")
        return true
    }
}

// MARK: - CGEventTap Callback (C function)

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let refcon {
            let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
            if let tap = service.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passRetained(event)
    }

    let startTime = CFAbsoluteTimeGetCurrent()

    guard type == .keyDown else {
        return Unmanaged.passRetained(event)
    }

    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    // Global hotkey: Ctrl+Opt+Space (keycode 49 = Space)
    let requiredGlobalFlags: CGEventFlags = [.maskControl, .maskAlternate]
    if keyCode == 49
        && flags.contains(requiredGlobalFlags)
        && !flags.contains(.maskCommand)
        && !flags.contains(.maskShift)
    {
        Task { @MainActor in
            SidebarManager.shared.toggle()
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        if elapsed > 10 {
            let logger = Logger(subsystem: "com.promptpal.mac", category: "HotkeyService")
            logger.warning("Hotkey callback took \(elapsed, format: .fixed(precision: 1))ms")
        }
        return nil
    }

    // Per-prompt shortcut: Ctrl+Opt+{letter} (keycodes 0-25 = A-Z)
    let requiredShortcutFlags: CGEventFlags = [.maskControl, .maskAlternate]
    if flags.contains(requiredShortcutFlags) && !flags.contains(.maskCommand) && !flags.contains(.maskShift) {
        if keyCode >= 0 && keyCode <= 50 {
            if let letter = keyCodeToLetter(Int(keyCode)) {
                Task { @MainActor in
                    HotkeyService.shared.handlePerPromptShortcut(letter: letter)
                }
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                if elapsed > 10 {
                    let logger = Logger(subsystem: "com.promptpal.mac", category: "HotkeyService")
                    logger.warning("Shortcut callback took \(elapsed, format: .fixed(precision: 1))ms")
                }
                return nil
            }
        }
    }

    // Snippet buffer: only process when no modifiers (except shift for uppercase)
    let significantFlags: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
    if !flags.isDisjoint(with: significantFlags) {
        Task { @MainActor in
            HotkeyService.shared.resetSnippetBuffer()
        }
        return Unmanaged.passRetained(event)
    }

    // Check for buffer-resetting keys
    let resetKeyCodes: Set<Int64> = [
        53, // Escape
        36, // Return
        76, // Enter (numpad)
        123, 124, 125, 126 // Arrow keys
    ]
    if resetKeyCodes.contains(keyCode) {
        Task { @MainActor in
            HotkeyService.shared.resetSnippetBuffer()
        }
        return Unmanaged.passRetained(event)
    }

    // Backspace removes last character from buffer
    if keyCode == 51 {
        Task { @MainActor in
            HotkeyService.shared.handleBackspace()
        }
        return Unmanaged.passRetained(event)
    }

    // Regular character — convert CGEvent to NSEvent to get characters
    if let nsEvent = NSEvent(cgEvent: event), let characters = nsEvent.characters, !characters.isEmpty {
        Task { @MainActor in
            HotkeyService.shared.appendToSnippetBuffer(characters)
        }
    }

    let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
    if elapsed > 10 {
        let logger = Logger(subsystem: "com.promptpal.mac", category: "HotkeyService")
        logger.warning("Callback took \(elapsed, format: .fixed(precision: 1))ms")
    }

    return Unmanaged.passRetained(event)
}

/// Maps virtual key codes to uppercase letter characters.
private func keyCodeToLetter(_ keyCode: Int) -> String? {
    let keyMap: [Int: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E",
        3: "F", 5: "G", 4: "H", 34: "I", 38: "J",
        40: "K", 37: "L", 46: "M", 45: "N", 31: "O",
        35: "P", 12: "Q", 15: "R", 1: "S", 17: "T",
        32: "U", 9: "V", 13: "W", 7: "X", 16: "Y",
        6: "Z"
    ]
    return keyMap[keyCode]
}

// MARK: - MainActor Snippet Logic

extension HotkeyService {
    func handlePerPromptShortcut(letter: String) {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let descriptor = FetchDescriptor<PromptNote>()
        guard let prompts = try? context.fetch(descriptor) else { return }
        guard let match = prompts.first(where: { $0.shortcutLetter == letter }) else { return }

        AutoPasteService.shared.pastePrompt(match, context: context)
    }

    func appendToSnippetBuffer(_ chars: String) {
        // Suppress when own windows are key
        if NSApp.keyWindow != nil && !(NSApp.keyWindow is SidebarPanel) {
            resetSnippetBuffer()
            return
        }

        snippetBuffer.append(chars)
        if snippetBuffer.count > 50 {
            snippetBuffer = String(snippetBuffer.suffix(50))
        }

        restartSnippetTimer()
        checkSnippetMatch()
    }

    func handleBackspace() {
        if !snippetBuffer.isEmpty {
            snippetBuffer.removeLast()
        }
    }

    func resetSnippetBuffer() {
        snippetBuffer = ""
        snippetTimer?.invalidate()
        snippetTimer = nil
    }

    private func restartSnippetTimer() {
        snippetTimer?.invalidate()
        snippetTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.resetSnippetBuffer()
            }
        }
    }

    private func checkSnippetMatch() {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let descriptor = FetchDescriptor<PromptNote>()
        guard let prompts = try? context.fetch(descriptor) else { return }

        for prompt in prompts {
            guard let trigger = prompt.snippetTrigger else { continue }
            if snippetBuffer.hasSuffix(trigger) {
                resetSnippetBuffer()
                deleteBackwards(count: trigger.count) {
                    AutoPasteService.shared.pastePrompt(prompt, context: context)
                }
                return
            }
        }
    }

    private func deleteBackwards(count: Int, completion: @escaping () -> Void) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let backspaceCode: CGKeyCode = 51

        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.008) {
                guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: backspaceCode, keyDown: true),
                      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: backspaceCode, keyDown: false) else { return }
                keyDown.post(tap: .cgAnnotatedSessionEventTap)
                keyUp.post(tap: .cgAnnotatedSessionEventTap)
            }
        }

        let totalDelay = Double(count) * 0.008 + 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            completion()
        }
    }
}
