import Foundation
import SwiftData

enum SeedData {
    static let hasSeededKey = "com.hodor.hasSeeded"

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }

        let examples = [
            PromptNote(
                body: "Rewrite this to be clear and concise. Keep my meaning. Cut the filler.",
                title: nil,
                shortcutLetter: "P",
                snippetTrigger: ";polish"
            ),
            PromptNote(
                body: "Reply in my voice. Match their tone. Cover every point. Suggest a next step.",
                title: nil,
                shortcutLetter: "R",
                snippetTrigger: ";reply"
            ),
            PromptNote(
                body: "What am I not considering? List blind spots and risks I might be missing.",
                title: nil,
                shortcutLetter: "X",
                snippetTrigger: ";cha"
            ),
            PromptNote(
                body: "Commit and push. Include a version bump, a one-line summary, and a brief description of what changed.",
                title: "Git commit",
                shortcutLetter: "G",
                snippetTrigger: ";git"
            ),
        ]

        for example in examples {
            context.insert(example)
        }

        UserDefaults.standard.set(true, forKey: hasSeededKey)
    }
}
