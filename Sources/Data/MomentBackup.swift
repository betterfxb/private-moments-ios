import Foundation
import SwiftUI
import UniformTypeIdentifiers
import OSLog
import Darwin

struct MomentBackupEnvelope: Codable, Sendable {
    let formatVersion: Int
    let createdAt: Date
    let moments: [Moment]

    init(moments: [Moment], createdAt: Date = .now) {
        formatVersion = MomentBackupCodec.currentFormatVersion
        self.createdAt = createdAt
        self.moments = moments
    }
}

struct BackupImportSummary {
    let totalCount: Int
    let newCount: Int
    let updatedCount: Int
    let noteCount: Int
    let localCount: Int
    let removedCount: Int

    init(backup: MomentBackupEnvelope, existing: [Moment]) {
        let localIDs = Set(existing.map(\.id))
        let importedIDs = Set(backup.moments.map(\.id))
        totalCount = backup.moments.count
        newCount = importedIDs.subtracting(localIDs).count
        updatedCount = importedIDs.intersection(localIDs).count
        noteCount = backup.moments.filter { !$0.privateNote.isEmpty }.count
        localCount = existing.count
        removedCount = localIDs.subtracting(importedIDs).count
    }
}

enum MomentBackupFileReader {
    private static let logger = Logger(subsystem: "com.example.PrivateMoments", category: "backup")

    static func readPickerSnapshot(_ url: URL) throws -> MomentBackupEnvelope {
        // Only consume a copy already imported into this app. Never move a
        // user-owned original or depend on the provider's shared Inbox name.
        guard try isOwnedImportedFile(url) else { throw CocoaError(.fileReadNoPermission) }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            "PrivateMoments-Import-" + UUID().uuidString, isDirectory: true
        )
        let snapshot = folder.appendingPathComponent("backup.json")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false,
            attributes: [.protectionKey: FileProtectionType.complete])
        defer { cleanSnapshot(snapshot, folder: folder) }
        try excludeFromBackup(folder)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var moved: Result<Void, Error>?
        coordinator.coordinate(writingItemAt: url, options: .forMoving,
            writingItemAt: snapshot, options: [], error: &coordinationError) { source, destination in
            moved = Result {
                guard try isOwnedImportedFile(source) else { throw CocoaError(.fileReadNoPermission) }
                let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
                if let size = attributes[.size] as? NSNumber, size.intValue > MomentBackupCodec.maximumFileSize {
                    throw MomentBackupError.fileTooLarge
                }
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: source.path)
                try excludeFromBackup(source)
                coordinator.item(at: source, willMoveTo: destination)
                do { try FileManager.default.moveItem(at: source, to: destination) }
                catch {
                    coordinator.item(at: source, didMoveTo: source)
                    throw error
                }
                coordinator.item(at: source, didMoveTo: destination)
            }
        }
        if let coordinationError { throw coordinationError }
        guard let moved else { throw CocoaError(.fileReadUnknown) }
        try moved.get()
        return try read(snapshot)
    }

    private static func excludeFromBackup(_ url: URL) throws {
        var target = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try target.setResourceValues(values)
    }

    private static func cleanSnapshot(_ url: URL, folder: URL) {
        // Each path is a fresh UUID owned by this operation. Neither syscall
        // can recursively delete a directory or remove the provider original.
        for (item, directory) in [(url, false), (folder, true)] {
            let failure = item.withUnsafeFileSystemRepresentation { path -> Int32 in
                guard let path else { return EINVAL }
                let result = directory ? Darwin.rmdir(path) : Darwin.unlink(path)
                return result == 0 || errno == ENOENT ? 0 : errno
            }
            if failure != 0 {
                logger.error("Backup snapshot cleanup failed: POSIX \(failure, privacy: .private)")
            }
        }
    }

    private static func isOwnedImportedFile(_ url: URL) throws -> Bool {
        guard url.isFileURL else { return false }
        let file = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        var roots = [FileManager.default.temporaryDirectory]
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            roots.append(documents.appendingPathComponent("Inbox", isDirectory: true))
        }
        let ownedPath = roots.contains { root in
            let components = root.standardizedFileURL.resolvingSymlinksInPath().pathComponents
            return file.count > components.count && file.starts(with: components)
        }
        guard ownedPath else { return false }
        // Do not change attributes of directories or symbolic links.
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.type] as? FileAttributeType == .typeRegular
    }

    static func read(_ url: URL) throws -> MomentBackupEnvelope {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<MomentBackupEnvelope, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinatedURL in
            result = Result { try readContents(coordinatedURL) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw CocoaError(.fileReadUnknown) }
        return try result.get()
    }

    private static func readContents(_ url: URL) throws -> MomentBackupEnvelope {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? NSNumber,
           size.intValue > MomentBackupCodec.maximumFileSize {
            throw MomentBackupError.fileTooLarge
        }
        let handle = try FileHandle(forReadingFrom: url)
        var data = Data()
        do {
            while data.count <= MomentBackupCodec.maximumFileSize {
                let remaining = MomentBackupCodec.maximumFileSize + 1 - data.count
                let part = try handle.read(upToCount: min(64 * 1024, remaining)) ?? Data()
                if part.isEmpty { break }
                data.append(part)
            }
            try handle.close()
        } catch {
            // Preserve the primary read error if cleanup also fails.
            try? handle.close()
            throw error
        }
        return try MomentBackupCodec.decode(data)
    }
}

enum MomentBackupError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidFormat
    case fileTooLarge
    case tooManyRecords
    case duplicateRecordID

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return AppLocalization.format("This backup uses an unsupported format version (%lld).", version)
        case .invalidFormat:
            return AppLocalization.string("This file isn't a valid Private Moments backup.")
        case .fileTooLarge:
            return AppLocalization.string("The backup file is larger than the supported 25 MB limit.")
        case .tooManyRecords:
            return AppLocalization.string("The backup contains more records than this app supports.")
        case .duplicateRecordID:
            return AppLocalization.string("The backup contains duplicate record identifiers. No records were changed.")
        }
    }
}

enum MomentBackupCodec {
    static let currentFormatVersion = 1
    static let maximumRecordCount = 100_000
    static let maximumFileSize = 25 * 1024 * 1024

    static func encode(_ moments: [Moment]) throws -> Data {
        try validate(moments)
        let estimatedBytes = moments.reduce(0) { total, moment in
            let variableBytes = moment.privateNote.utf8.count
                + (moment.approximatePlace?.utf8.count ?? 0)
                + moment.tags.reduce(0) { $0 + $1.utf8.count }
            return total + 256 + variableBytes * 6
        }
        guard estimatedBytes <= maximumFileSize else { throw MomentBackupError.fileTooLarge }
        let envelope = MomentBackupEnvelope(moments: moments)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(envelope)
        guard data.count <= maximumFileSize else { throw MomentBackupError.fileTooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> MomentBackupEnvelope {
        guard data.count <= maximumFileSize else { throw MomentBackupError.fileTooLarge }

        let envelope: MomentBackupEnvelope
        do {
            envelope = try JSONDecoder().decode(MomentBackupEnvelope.self, from: data)
        } catch {
            throw MomentBackupError.invalidFormat
        }

        guard envelope.formatVersion == currentFormatVersion else {
            throw MomentBackupError.unsupportedVersion(envelope.formatVersion)
        }
        guard envelope.createdAt.timeIntervalSince1970.isFinite else {
            throw MomentBackupError.invalidFormat
        }
        try validate(envelope.moments)
        return envelope
    }

    private static func validate(_ moments: [Moment]) throws {
        guard moments.count <= maximumRecordCount else {
            throw MomentBackupError.tooManyRecords
        }
        guard Set(moments.map(\.id)).count == moments.count else {
            throw MomentBackupError.duplicateRecordID
        }
        try moments.forEach(MomentValidator.validate)
    }
}

struct MomentBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw MomentBackupError.invalidFormat
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
