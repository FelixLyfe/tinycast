import Foundation
import SQLite3

@main
@MainActor
struct ClipboardMigrationTests {
    static var failures = 0
    static var passes = 0

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if condition() {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message)")
        }
    }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cliiippo-migration-test-\(UUID().uuidString)")
        let source = root.appendingPathComponent("source")
        let destination = root.appendingPathComponent("destination")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceImage = source.appendingPathComponent("source.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: sourceImage)
        let database = source.appendingPathComponent("clipboard.sqlite3")
        try seed(database: database, imagePath: sourceImage.path)

        let batch = try TinycastClipboardMigration.prepare(
            sourceURL: database,
            imagesURL: destination.appendingPathComponent("images"))
        expect(batch.entries.count == 2, "text and available image are prepared")
        expect(batch.skippedImages == 1, "missing images are counted and skipped")

        let text = batch.entries.first { $0.kind == .text }
        expect(text?.text == "from Tinycast", "text content is preserved")
        expect(text?.sourceBundleID == "com.apple.TextEdit", "source app is preserved")
        expect(text?.isPinned == true, "pin timestamp is preserved")

        let image = batch.entries.first { $0.kind == .image }
        expect(image?.imagePath != sourceImage.path, "image receives a Cliiippo-owned path")
        expect(
            image?.imagePath.map(FileManager.default.fileExists(atPath:)) == true,
            "image bytes are copied")

        let store = ClipboardStore(directory: destination)
        expect(store.importEntries(batch.entries) == 2, "prepared entries import exactly once")
        expect(store.items.count == 2, "destination verifies the imported count")
        expect(FileManager.default.fileExists(atPath: database.path), "source database remains")
        expect(FileManager.default.fileExists(atPath: sourceImage.path), "source image remains")

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }

    static func seed(database url: URL, imagePath: String) throws {
        var database: OpaquePointer?
        guard sqlite3_open(url.path, &database) == SQLITE_OK, let database else {
            throw NSError(domain: "ClipboardMigrationTests", code: 1)
        }
        defer { sqlite3_close(database) }
        let created = Date().addingTimeInterval(-100).timeIntervalSince1970
        let pinned = Date().addingTimeInterval(-50).timeIntervalSince1970
        let missing = url.deletingLastPathComponent().appendingPathComponent("missing.png").path
        let sql = """
            CREATE TABLE items(
              id TEXT NOT NULL UNIQUE, kind TEXT NOT NULL, text TEXT, image_path TEXT,
              created_at REAL NOT NULL, source_app TEXT, pinned_at REAL
            );
            INSERT INTO items VALUES(
              '\(UUID().uuidString)', 'text', 'from Tinycast', NULL, \(created),
              'com.apple.TextEdit', \(pinned)
            );
            INSERT INTO items VALUES(
              '\(UUID().uuidString)', 'image', NULL, '\(imagePath)', \(created + 1), NULL, NULL
            );
            INSERT INTO items VALUES(
              '\(UUID().uuidString)', 'image', NULL, '\(missing)', \(created + 2), NULL, NULL
            );
            """
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw NSError(domain: "ClipboardMigrationTests", code: 2)
        }
    }
}
