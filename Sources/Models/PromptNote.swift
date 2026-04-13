import Foundation
import SwiftData

@Model
final class PromptNote: Identifiable {
    var id: UUID
    var body: String
    var title: String?
    var shortcutLetter: String?
    var snippetTrigger: String?
    var createdAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    init(
        body: String,
        title: String? = nil,
        shortcutLetter: String? = nil,
        snippetTrigger: String? = nil
    ) {
        self.id = UUID()
        self.body = body
        self.title = title
        self.shortcutLetter = shortcutLetter
        self.snippetTrigger = snippetTrigger
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.useCount = 0
    }
}

extension PromptNote {
    /// Validates that shortcutLetter is a single uppercase A-Z character.
    var isShortcutLetterValid: Bool {
        guard let letter = shortcutLetter else { return true }
        return letter.count == 1 && letter.first?.isUppercase == true && letter.first?.isLetter == true
    }

    /// Returns a normalized uppercase shortcut letter, or nil.
    var normalizedShortcutLetter: String? {
        guard let letter = shortcutLetter?.uppercased(), letter.count == 1,
              letter.first?.isLetter == true else { return nil }
        return letter
    }
}
