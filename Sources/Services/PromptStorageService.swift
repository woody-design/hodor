import Foundation
import SwiftData
import os.log

@MainActor
final class PromptStorageService {
    static let shared = PromptStorageService()

    private let logger = Logger(subsystem: "com.promptpal.mac", category: "PromptStorageService")

    private init() {}

    func makeModelContainer() throws -> ModelContainer {
        try FileManager.default.createDirectory(
            at: appSupportDirectory,
            withIntermediateDirectories: true
        )

        do {
            return try makeContainer(at: currentStoreURL)
        } catch {
            logger.error("Failed to open prompt store, moving it aside: \(error.localizedDescription)")
            if storeFileExists(for: currentStoreURL) {
                try moveStoreFiles(
                    for: currentStoreURL,
                    to: storeBackupsDirectory.appendingPathComponent(
                        "failed-open-\(Self.snapshotFormatter.string(from: Date()))",
                        isDirectory: true
                    )
                )
            }
            return try makeContainer(at: currentStoreURL)
        }
    }

    // MARK: - Store URLs

    private var appSupportDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Hodor", isDirectory: true)
    }

    private var currentStoreURL: URL {
        appSupportDirectory.appendingPathComponent("Hodor.store")
    }

    private var storeBackupsDirectory: URL {
        appSupportDirectory.appendingPathComponent("StoreBackups", isDirectory: true)
    }

    private func makeContainer(at storeURL: URL) throws -> ModelContainer {
        let schema = Schema([PromptNote.self])
        let configuration = ModelConfiguration(
            "Hodor",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Store File Groups

    private func storeFileExists(for storeURL: URL) -> Bool {
        storeFileURLs(for: storeURL).contains {
            FileManager.default.fileExists(atPath: $0.path)
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
