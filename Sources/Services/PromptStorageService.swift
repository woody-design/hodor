import Foundation
import SwiftData
import os.log

@MainActor
final class PromptStorageService {
    static let shared = PromptStorageService()

    private let logger = Logger(subsystem: "com.promptpal.mac", category: "PromptStorageService")
    private let migrationCompleteKey = "com.hodor.storage.explicitStoreMigrationComplete"

    private init() {}

    func makeModelContainer() throws -> ModelContainer {
        try FileManager.default.createDirectory(
            at: appSupportDirectory,
            withIntermediateDirectories: true
        )

        migrateLegacyStoreIfNeeded()

        do {
            return try makeContainer(at: currentStoreURL)
        } catch {
            logger.error("Failed to open prompt store, moving it aside: \(error.localizedDescription)")
            try moveStoreFiles(
                for: currentStoreURL,
                to: storeBackupsDirectory.appendingPathComponent(
                    "failed-open-\(Self.snapshotFormatter.string(from: Date()))",
                    isDirectory: true
                )
            )
            return try makeContainer(at: currentStoreURL)
        }
    }

    // MARK: - Store URLs

    private var applicationSupportRoot: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
    }

    private var appSupportDirectory: URL {
        applicationSupportRoot.appendingPathComponent("Hodor", isDirectory: true)
    }

    private var currentStoreURL: URL {
        appSupportDirectory.appendingPathComponent("Hodor.store")
    }

    private var legacyStoreURL: URL {
        applicationSupportRoot.appendingPathComponent("default.store")
    }

    private var storeBackupsDirectory: URL {
        appSupportDirectory.appendingPathComponent("StoreBackups", isDirectory: true)
    }

    // MARK: - Migration

    private func migrateLegacyStoreIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationCompleteKey) else { return }
        guard !storeFileExists(for: currentStoreURL) else {
            defaults.set(true, forKey: migrationCompleteKey)
            return
        }
        guard storeFileExists(for: legacyStoreURL) else { return }

        logger.info("Migrating legacy default SwiftData store to explicit Hodor store path")

        let legacyPrompts: [PromptNote]
        do {
            let legacyContainer = try makeContainer(at: legacyStoreURL, allowsSave: false)
            legacyPrompts = try fetchPrompts(from: legacyContainer)
        } catch {
            logger.warning("Skipping unreadable legacy default.store: \(error.localizedDescription)")
            defaults.set(true, forKey: migrationCompleteKey)
            return
        }

        guard !legacyPrompts.isEmpty else {
            defaults.set(true, forKey: migrationCompleteKey)
            return
        }

        do {
            try copyStoreFiles(
                for: legacyStoreURL,
                to: storeBackupsDirectory.appendingPathComponent(
                    "pre-explicit-store-migration-\(Self.snapshotFormatter.string(from: Date()))",
                    isDirectory: true
                )
            )

            let newContainer = try makeContainer(at: currentStoreURL)
            for prompt in legacyPrompts {
                newContainer.mainContext.insert(copyPrompt(prompt))
            }
            do {
                try newContainer.mainContext.save()
            } catch {
                newContainer.mainContext.rollback()
                throw error
            }
            defaults.set(true, forKey: migrationCompleteKey)
            PromptBackupService.shared.captureCurrentLibraryIfPresent(context: newContainer.mainContext)
            logger.info("Migrated \(legacyPrompts.count) prompts to explicit Hodor store path")
        } catch {
            logger.error("Failed to migrate readable legacy default.store: \(error.localizedDescription)")
            moveCurrentStoreAsideAfterFailedMigration()
        }
    }

    private func moveCurrentStoreAsideAfterFailedMigration() {
        guard storeFileExists(for: currentStoreURL) else { return }

        do {
            try moveStoreFiles(
                for: currentStoreURL,
                to: storeBackupsDirectory.appendingPathComponent(
                    "failed-legacy-migration-\(Self.snapshotFormatter.string(from: Date()))",
                    isDirectory: true
                )
            )
        } catch {
            logger.error("Failed to move partial migrated store aside: \(error.localizedDescription)")
        }
    }

    private func makeContainer(at storeURL: URL, allowsSave: Bool = true) throws -> ModelContainer {
        let schema = Schema([PromptNote.self])
        let configuration = ModelConfiguration(
            "Hodor",
            schema: schema,
            url: storeURL,
            allowsSave: allowsSave,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func fetchPrompts(from container: ModelContainer) throws -> [PromptNote] {
        let descriptor = FetchDescriptor<PromptNote>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    private func copyPrompt(_ prompt: PromptNote) -> PromptNote {
        let copy = PromptNote(
            body: prompt.body,
            title: prompt.title,
            shortcutLetter: prompt.shortcutLetter,
            snippetTrigger: prompt.snippetTrigger
        )
        copy.id = prompt.id
        copy.createdAt = prompt.createdAt
        copy.lastUsedAt = prompt.lastUsedAt
        copy.useCount = prompt.useCount
        return copy
    }

    // MARK: - Store File Groups

    private func storeFileExists(for storeURL: URL) -> Bool {
        storeFileURLs(for: storeURL).contains {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }

    private func copyStoreFiles(for storeURL: URL, to directory: URL) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        for sourceURL in storeFileURLs(for: storeURL) where FileManager.default.fileExists(atPath: sourceURL.path) {
            let destinationURL = directory.appendingPathComponent(sourceURL.lastPathComponent)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private func moveStoreFiles(for storeURL: URL, to directory: URL) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        for sourceURL in storeFileURLs(for: storeURL) where FileManager.default.fileExists(atPath: sourceURL.path) {
            let destinationURL = directory.appendingPathComponent(sourceURL.lastPathComponent)
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
        }
    }

    private func storeFileURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm"),
        ]
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
