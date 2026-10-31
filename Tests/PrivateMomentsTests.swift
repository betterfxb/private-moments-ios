import XCTest
@testable import PrivateMoments

final class MomentValidationTests: XCTestCase {
    func testPrivateNoteAllowsEmptyAndExactCharacterLimit() throws {
        try MomentValidator.validatePrivateNote("")
        try MomentValidator.validatePrivateNote(String(repeating: "a", count: MomentValidator.maximumNoteLength))
        XCTAssertThrowsError(try MomentValidator.validatePrivateNote(
            String(repeating: "a", count: MomentValidator.maximumNoteLength + 1)
        )) {
            XCTAssertEqual($0 as? MomentValidationError, .noteTooLong)
        }
    }

    func testPrivateNoteUTF8BoundaryIsIndependentOfCharacterCount() throws {
        let note = "a" + String(repeating: "\u{0301}", count: (MomentValidator.maximumNoteUTF8Bytes - 2) / 2) + "b"
        XCTAssertEqual(note.utf8.count, MomentValidator.maximumNoteUTF8Bytes)
        XCTAssertLessThan(note.count, MomentValidator.maximumNoteLength)
        try MomentValidator.validatePrivateNote(note)
        XCTAssertThrowsError(try MomentValidator.validatePrivateNote(note + "c")) {
            XCTAssertEqual($0 as? MomentValidationError, .noteTooLong)
        }
    }

    func testValidMomentPassesValidation() throws {
        try MomentValidator.validate(makeMoment())
    }

    func testNegativeDurationIsRejected() {
        var moment = makeMoment()
        moment.durationSeconds = -1

        XCTAssertThrowsError(try MomentValidator.validate(moment)) {
            XCTAssertEqual($0 as? MomentValidationError, .invalidDuration)
        }
    }

    func testOverlongPrivateNoteIsRejected() {
        var moment = makeMoment()
        moment.privateNote = String(repeating: "a", count: MomentValidator.maximumNoteLength + 1)

        XCTAssertThrowsError(try MomentValidator.validate(moment)) {
            XCTAssertEqual($0 as? MomentValidationError, .noteTooLong)
        }
    }

    func testOversizedUnicodeNoteIsRejectedEvenWhenGraphemeCountIsSmall() {
        var moment = makeMoment()
        moment.privateNote = "a" + String(repeating: "\u{0301}", count: MomentValidator.maximumNoteUTF8Bytes)

        XCTAssertThrowsError(try MomentValidator.validate(moment)) {
            XCTAssertEqual($0 as? MomentValidationError, .noteTooLong)
        }
    }

    func testBackupRoundTripPreservesPrivateFields() throws {
        let original = makeMoment(privateNote: "A private reflection", kind: .solo)
        let data = try MomentBackupCodec.encode([original])
        let restored = try MomentBackupCodec.decode(data)

        XCTAssertEqual(restored.moments, [original])
        XCTAssertEqual(restored.formatVersion, MomentBackupCodec.currentFormatVersion)
    }

    func testBackupRejectsDuplicateIDsBeforeRestore() {
        let moment = makeMoment()

        XCTAssertThrowsError(try MomentBackupCodec.encode([moment, moment])) {
            XCTAssertEqual(
                ($0 as? MomentBackupError)?.localizedDescription,
                MomentBackupError.duplicateRecordID.localizedDescription
            )
        }
    }

    func testBackupRejectsUnknownFormatVersion() {
        let data = Data(#"{"formatVersion":42,"createdAt":0,"moments":[]}"#.utf8)

        XCTAssertThrowsError(try MomentBackupCodec.decode(data)) {
            XCTAssertEqual(
                ($0 as? MomentBackupError)?.localizedDescription,
                MomentBackupError.unsupportedVersion(42).localizedDescription
            )
        }
    }

    func testBackupRejectsFilesOverSizeLimit() {
        let data = Data(repeating: 0, count: MomentBackupCodec.maximumFileSize + 1)

        XCTAssertThrowsError(try MomentBackupCodec.decode(data)) {
            XCTAssertEqual(
                ($0 as? MomentBackupError)?.localizedDescription,
                MomentBackupError.fileTooLarge.localizedDescription
            )
        }
    }

    private func makeMoment(
        privateNote: String = "",
        kind: MomentKind = .together
    ) -> Moment {
        Moment(
            occurredAt: Date(timeIntervalSince1970: 1_000),
            durationSeconds: 600,
            mood: .calm,
            kind: kind,
            rating: 4,
            tags: ["Connected"],
            privateNote: privateNote
        )
    }
}

@MainActor
final class MomentStoreImportTests: XCTestCase {
    func testMergeAddsNewRecordsAndUpdatesMatchingIDs() {
        let original = makeMoment(note: "old")
        let repository = InMemoryMomentRepository(moments: [original])
        let store = MomentStore(repository: repository)
        let updated = Moment(
            id: original.id,
            occurredAt: original.occurredAt,
            durationSeconds: 900,
            mood: .joyful,
            kind: .together,
            rating: 5,
            tags: ["Connected"],
            privateNote: "updated"
        )
        let newMoment = makeMoment(note: "new")

        let addedCount = store.mergeBackup([updated, newMoment])

        XCTAssertEqual(addedCount, 1)
        XCTAssertEqual(store.moments.count, 2)
        XCTAssertEqual(store.moments.first(where: { $0.id == original.id })?.privateNote, "updated")
        XCTAssertEqual(repository.moments.count, 2)
    }

    func testInvalidMergeLeavesExistingRecordsUnchanged() {
        let original = makeMoment(note: "keep")
        let repository = InMemoryMomentRepository(moments: [original])
        let store = MomentStore(repository: repository)
        var invalid = makeMoment(note: "")
        invalid.privateNote = String(repeating: "x", count: MomentValidator.maximumNoteLength + 1)

        XCTAssertNil(store.mergeBackup([invalid]))
        XCTAssertEqual(store.moments, [original])
        XCTAssertEqual(repository.moments, [original])
    }

    func testFailedReplacementLeavesExistingRecordsUnchanged() {
        let original = makeMoment(note: "keep")
        let repository = InMemoryMomentRepository(moments: [original])
        repository.failReplacement = true
        let store = MomentStore(repository: repository)

        XCTAssertFalse(store.replaceWithBackup([makeMoment(note: "replacement")]))
        XCTAssertEqual(store.moments, [original])
        XCTAssertEqual(repository.moments, [original])
    }

    private func makeMoment(note: String) -> Moment {
        Moment(
            occurredAt: Date(timeIntervalSince1970: 1_000),
            durationSeconds: 600,
            mood: .calm,
            rating: 4,
            tags: ["Connected"],
            privateNote: note
        )
    }
}

@MainActor
private final class InMemoryMomentRepository: MomentRepository {
    private(set) var moments: [Moment]
    var failReplacement = false

    init(moments: [Moment] = []) {
        self.moments = moments
    }

    func fetchAll() throws -> [Moment] {
        moments.sorted { $0.occurredAt > $1.occurredAt }
    }

    func save(_ moment: Moment) throws {
        moments.removeAll { $0.id == moment.id }
        moments.append(moment)
    }

    func mergeAll(_ imported: [Moment]) throws {
        for moment in imported {
            moments.removeAll { $0.id == moment.id }
            moments.append(moment)
        }
    }

    func replaceAll(with imported: [Moment]) throws {
        if failReplacement { throw TestRepositoryError.writeFailed }
        moments = imported
    }

    func delete(id: UUID) throws {
        moments.removeAll { $0.id == id }
    }

    func deleteAll() throws {
        moments = []
    }
}

private enum TestRepositoryError: Error {
    case writeFailed
}
