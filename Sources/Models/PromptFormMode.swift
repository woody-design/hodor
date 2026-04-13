import Foundation

enum PromptFormMode {
    case create
    case edit(PromptNote)

    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingNote: PromptNote? {
        if case .edit(let note) = self { return note }
        return nil
    }
}
