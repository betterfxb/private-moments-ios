import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct MomentBackupEnvelope: Codable {
    let formatVersion: Int
    let createdAt: Date
    let moments: [Moment]

    init(moments: [Moment], createdAt: Date = .now) {
        formatVersion = MomentBackupCodec.currentFormatVersion
        self.createdAt = createdAt
        self.moments = moments
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
