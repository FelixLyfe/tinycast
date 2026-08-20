import AppKit
import Foundation
import SQLite3

/// One-way, copy-only migration from Tinycast's stable clipboard cache.
@MainActor
enum TinycastClipboardMigration {
    static let sourceBundleID = "com.tinycast.app"

    struct Result: Sendable {
        let entries: Int
        let preferences: Int
        let skippedImages: Int
    }

    enum MigrationError: LocalizedError {
        case tinycastRunning
        case destinationNotEmpty
        case sourceUnavailable
        case databaseUnreadable
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .tinycastRunning:
                String(localized: "Quit Tinycast before importing its clipboard history.")
            case .destinationNotEmpty:
                String(localized: "Import is available only while Cliiippo history is empty.")
            case .sourceUnavailable:
                String(localized: "No Tinycast clipboard history was found.")
            case .databaseUnreadable:
                String(localized: "Tinycast clipboard history could not be read.")
            case .verificationFailed:
                String(localized: "The copied history could not be verified, so it was rolled back.")
            }
        }
    }

    struct Prepared: Sendable {
        let entries: [ClipboardItem]
        let skippedImages: Int
    }

    @MainActor
    private struct SettingsSnapshot {
        let retention: ClipboardRetention
        let excludedApps: [String]
        let appearance: AppAppearance
        let language: AppLanguage

        init(_ settings: AppSettings) {
            retention = settings.clipboardRetention
            excludedApps = settings.clipboardDisabledApps
            appearance = settings.appearance
            language = settings.appLanguage
        }

        func restore(_ settings: AppSettings) {
            settings.clipboardRetention = retention
            settings.clipboardDisabledApps = excludedApps
            settings.appearance = appearance
            settings.appLanguage = language
        }
    }

    static var sourceDatabaseURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(sourceBundleID, isDirectory: true)
            .appendingPathComponent("clipboard.sqlite3")
    }

    static var sourceExists: Bool {
        FileManager.default.fileExists(atPath: sourceDatabaseURL.path)
    }

    static var isTinycastRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == sourceBundleID }
    }

    static func run(store: ClipboardStore, settings: AppSettings) async throws -> Result {
        guard !isTinycastRunning else { throw MigrationError.tinycastRunning }
        guard store.isEmpty else { throw MigrationError.destinationNotEmpty }
        guard sourceExists else { throw MigrationError.sourceUnavailable }

        let sourceURL = sourceDatabaseURL
        let imagesURL = AppPaths.applicationSupport()
            .appendingPathComponent("images", isDirectory: true)
        let prepared = try await Task.detached(priority: .utility) {
            try prepare(sourceURL: sourceURL, imagesURL: imagesURL)
        }.value

        let previousSettings = SettingsSnapshot(settings)
        let preferences = settings.importTinycastPreferences()
        store.maxAge = settings.clipboardRetention.maxAge
        let inserted = store.importEntries(prepared.entries)
        guard inserted == prepared.entries.count else {
            store.clearAll()
            previousSettings.restore(settings)
            store.maxAge = settings.clipboardRetention.maxAge
            throw MigrationError.verificationFailed
        }
        return Result(
            entries: inserted, preferences: preferences, skippedImages: prepared.skippedImages)
    }

    nonisolated static func prepare(sourceURL: URL, imagesURL: URL) throws -> Prepared {
        var database: OpaquePointer?
        guard sqlite3_open_v2(sourceURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
            let database
        else {
            if let database { sqlite3_close(database) }
            throw MigrationError.databaseUnreadable
        }
        defer { sqlite3_close(database) }

        let sql = """
            SELECT id, kind, text, image_path, created_at, source_app, pinned_at
            FROM items ORDER BY rowid ASC
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
            let statement
        else { throw MigrationError.databaseUnreadable }
        defer { sqlite3_finalize(statement) }

        try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        var entries: [ClipboardItem] = []
        var files: [URL] = []
        var skippedImages = 0
        var seenText = Set<String>()

        do {
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let identifier = text(statement, 0).flatMap(UUID.init(uuidString:)),
                    let rawKind = text(statement, 1),
                    let kind = ClipboardItem.Kind(rawValue: rawKind)
                else { continue }

                let entryText = text(statement, 2)
                var imagePath: String?
                if kind == .text {
                    guard let entryText, seenText.insert(entryText).inserted else { continue }
                } else {
                    guard let oldPath = text(statement, 3),
                        FileManager.default.fileExists(atPath: oldPath)
                    else {
                        skippedImages += 1
                        continue
                    }
                    let destination = imagesURL.appendingPathComponent(UUID().uuidString + ".png")
                    try FileManager.default.copyItem(
                        at: URL(fileURLWithPath: oldPath), to: destination)
                    files.append(destination)
                    imagePath = destination.path
                }

                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
                let pinnedAt =
                    sqlite3_column_type(statement, 6) == SQLITE_NULL
                    ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
                entries.append(
                    ClipboardItem(
                        id: identifier, kind: kind, text: entryText, imagePath: imagePath,
                        createdAt: createdAt, sourceBundleID: text(statement, 5), pinnedAt: pinnedAt))
            }
        } catch {
            for file in files { try? FileManager.default.removeItem(at: file) }
            throw error
        }
        return Prepared(entries: entries, skippedImages: skippedImages)
    }

    nonisolated private static func text(_ statement: OpaquePointer, _ column: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: value)
    }
}
