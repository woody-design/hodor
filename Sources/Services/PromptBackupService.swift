import Foundation
import SwiftData
import os.log

@MainActor
final class PromptBackupService {
    static let shared = PromptBackupService()

    private static let backupSchemaVersion = 1
    private static let retainedSnapshotCount = 20

    private let logger = Logger(subsystem: "com.promptpal.mac", category: "PromptBackupService")
    private let lastKnownPromptCountKey = "com.hodor.prompts.lastKnownPromptCount"
    private let intentionallyEmptyKey = "com.hodor.prompts.userIntentionallyEmptiedLibrary"

    private init() {}

    func restoreIfNeeded(context: ModelContext) {
        do {
            let currentPrompts = try fetchPrompts(context: context)
            guard currentPrompts.isEmpty else { return }
            guard shouldRestoreEmptyLibrary else { return }
            guard let backup = try loadLatestBackup(), !backup.prompts.isEmpty else { return }

            for record in backup.prompts {
                context.insert(record.makePromptNote())
            }

            do {
                try context.save()
            } catch {
                context.rollback()
                throw error
            }

            UserDefaults.standard.set(false, forKey: intentionallyEmptyKey)
            UserDefaults.standard.set(backup.prompts.count, forKey: lastKnownPromptCountKey)
            UserDefaults.standard.set(true, forKey: SeedData.hasSeededKey)

            let restoredPrompts = try fetchPrompts(context: context)
            try writeBackup(for: restoredPrompts)
            logger.info("Restored \(backup.prompts.count) prompts from local backup")
        } catch {
            logger.error("Failed to restore prompt backup: \(error.localizedDescription)")
        }
    }

    func captureCurrentLibraryIfPresent(context: ModelContext) {
        do {
            let prompts = try fetchPrompts(context: context)
            guard !prompts.isEmpty else { return }
            try writeBackup(for: prompts)
            markLibraryNonEmpty(count: prompts.count)
        } catch {
            logger.error("Failed to capture prompt backup: \(error.localizedDescription)")
        }
    }

    func recordUserLibrarySave(context: ModelContext) {
        do {
            let prompts = try fetchPrompts(context: context)
            if prompts.isEmpty {
                markLibraryIntentionallyEmpty()
            } else {
                try writeBackup(for: prompts)
                markLibraryNonEmpty(count: prompts.count)
            }
        } catch {
            logger.error("Failed to update prompt backup after user save: \(error.localizedDescription)")
        }
    }

    // MARK: - State

    private var shouldRestoreEmptyLibrary: Bool {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: lastKnownPromptCountKey) > 0
            && !defaults.bool(forKey: intentionallyEmptyKey)
    }

    private func markLibraryNonEmpty(count: Int) {
        UserDefaults.standard.set(count, forKey: lastKnownPromptCountKey)
        UserDefaults.standard.set(false, forKey: intentionallyEmptyKey)
    }

    private func markLibraryIntentionallyEmpty() {
        UserDefaults.standard.set(0, forKey: lastKnownPromptCountKey)
        UserDefaults.standard.set(true, forKey: intentionallyEmptyKey)
    }

    // MARK: - Fetching

    private func fetchPrompts(context: ModelContext) throws -> [PromptNote] {
        let descriptor = FetchDescriptor<PromptNote>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Backup Files

    private func writeBackup(for prompts: [PromptNote]) throws {
        guard !prompts.isEmpty else { return }

        let backup = PromptBackupFile(
            schemaVersion: Self.backupSchemaVersion,
            createdAt: Date(),
            prompts: prompts.map(PromptBackupRecord.init)
        )

        let data = try encoder.encode(backup)
        try FileManager.default.createDirectory(
            at: backupsDirectory,
            withIntermediateDirectories: true
        )
        try data.write(to: latestBackupURL, options: .atomic)
        try data.write(to: snapshotURL(for: backup.createdAt), options: .atomic)
        pruneOldSnapshots()
    }

    private func loadLatestBackup() throws -> PromptBackupFile? {
        guard FileManager.default.fileExists(atPath: latestBackupURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: latestBackupURL)
        return try decoder.decode(PromptBackupFile.self, from: data)
    }

    private var appSupportDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Hodor", isDirectory: true)
    }

    private var backupsDirectory: URL {
        appSupportDirectory.appendingPathComponent("Backups", isDirectory: true)
    }

    private var latestBackupURL: URL {
        backupsDirectory.appendingPathComponent("prompts-latest.json")
    }

    private func snapshotURL(for date: Date) -> URL {
        backupsDirectory.appendingPathComponent("prompts-\(Self.snapshotFormatter.string(from: date)).json")
    }

    private func pruneOldSnapshots() {
        do {
            let snapshots = try FileManager.default.contentsOfDirectory(
                at: backupsDirectory,
                includingPropertiesForKeys: nil
            )
            .filter { url in
                url.lastPathComponent.hasPrefix("prompts-")
                    && url.lastPathComponent != "prompts-latest.json"
                    && url.pathExtension == "json"
            }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

            for snapshot in snapshots.dropFirst(Self.retainedSnapshotCount) {
                try FileManager.default.removeItem(at: snapshot)
            }
        } catch {
            logger.error("Failed to prune old prompt backups: \(error.localizedDescription)")
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static let snapshotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter
    }()
}

private struct PromptBackupFile: Codable {
    let schemaVersion: Int
    let createdAt: Date
    let prompts: [PromptBackupRecord]
}

private struct PromptBackupRecord: Codable {
    let id: UUID
    let body: String
    let title: String?
    let shortcutLetter: String?
    let snippetTrigger: String?
    let createdAt: Date
    let lastUsedAt: Date?
    let useCount: Int

    init(prompt: PromptNote) {
        id = prompt.id
        body = prompt.body
        title = prompt.title
        shortcutLetter = prompt.shortcutLetter
        snippetTrigger = prompt.snippetTrigger
        createdAt = prompt.createdAt
        lastUsedAt = prompt.lastUsedAt
        useCount = prompt.useCount
    }

    func makePromptNote() -> PromptNote {
        let note = PromptNote(
            body: body,
            title: title,
            shortcutLetter: shortcutLetter,
            snippetTrigger: snippetTrigger
        )
        note.id = id
        note.createdAt = createdAt
        note.lastUsedAt = lastUsedAt
        note.useCount = useCount
        return note
    }
}
