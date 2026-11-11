import Foundation
import SwiftUI
import UniformTypeIdentifiers

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
    static func read(_ url: URL) throws -> MomentBackupEnvelope {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
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
