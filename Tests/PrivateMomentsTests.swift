import XCTest
import SwiftUI
import UIKit
import SwiftData
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
    var fetchError: Error?
    var failedMutation: RepositoryMutation?
    private(set) var mutationCalls = 0

    init(moments: [Moment] = []) {
        self.moments = moments
    }

    func fetchAll() throws -> [Moment] {
        if let fetchError { throw fetchError }
        return moments.sorted { $0.occurredAt > $1.occurredAt }
    }

    func save(_ moment: Moment) throws {
        try checkFailure(.save)
        moments.removeAll { $0.id == moment.id }
        moments.append(moment)
    }

    func mergeAll(_ imported: [Moment]) throws {
        try checkFailure(.merge)
        for moment in imported {
            moments.removeAll { $0.id == moment.id }
            moments.append(moment)
        }
    }

    func replaceAll(with imported: [Moment]) throws {
        try checkFailure(.replace)
        if failReplacement { throw TestRepositoryError.writeFailed }
        moments = imported
    }

    func delete(id: UUID) throws {
        try checkFailure(.delete)
        moments.removeAll { $0.id == id }
    }

    func deleteAll() throws {
        try checkFailure(.deleteAll)
        moments = []
    }

    private func checkFailure(_ mutation: RepositoryMutation) throws {
        mutationCalls += 1
        if failedMutation == mutation { throw TestRepositoryError.writeFailed }
    }
}

private enum TestRepositoryError: Error {
    case writeFailed
    case readFailed
}

@MainActor
final class SemanticColorTests: XCTestCase {
    func testAccentAndSessionTextRemainReadableInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            for (foreground, background) in [
                (AppColors.onAccent, AppColors.terracotta),
                (AppColors.onDark, AppColors.espresso),
                (AppColors.onDarkSecondary, AppColors.espresso),
                (AppColors.onDarkAccent, AppColors.espresso)
            ] {
                XCTAssertGreaterThanOrEqual(contrast(foreground, background, style), 4.5)
            }
        }
    }

    func testBodyAndSecondaryTextContrastOnSurfaces() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            for surface in [AppColors.cream, AppColors.paper] {
                for foreground in [AppColors.ink, AppColors.inkSoft, AppColors.terracottaDark] {
                    XCTAssertGreaterThanOrEqual(contrast(foreground, surface, style), 4.5)
                }
            }
        }
    }

    private func contrast(_ foreground: Color, _ background: Color, _ style: UIUserInterfaceStyle) -> Double {
        let traits = UITraitCollection(userInterfaceStyle: style)
        func luminance(_ color: Color) -> Double {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            let resolved = UIColor(color).resolvedColor(with: traits)
            XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            func linear(_ component: CGFloat) -> Double {
                let value = Double(component)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let a = luminance(foreground), b = luminance(background)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

private enum RepositoryMutation: CaseIterable {
    case save, merge, replace, delete, deleteAll

    @MainActor
    func apply(to store: MomentStore, moment: Moment) -> Bool {
        switch self {
        case .save: return store.add(moment)
        case .merge: return store.mergeBackup([moment]) != nil
        case .replace: return store.replaceWithBackup([moment])
        case .delete: return store.delete(id: moment.id)
        case .deleteAll: return store.deleteAll()
        }
    }

    @MainActor
    func apply(to repository: any MomentRepository, moment: Moment) throws {
        switch self {
        case .save: try repository.save(moment)
        case .merge: try repository.mergeAll([moment])
        case .replace: try repository.replaceAll(with: [moment])
        case .delete: try repository.delete(id: moment.id)
        case .deleteAll: try repository.deleteAll()
        }
    }
}

@MainActor
final class MomentStoreRecoveryTests: XCTestCase {
    func testFirstReadFailureBlocksAllMutationsUntilSuccessfulRetry() {
        let original = makeRecoveryMoment()
        let repository = InMemoryMomentRepository(moments: [original])
        repository.fetchError = TestRepositoryError.readFailed
        let store = MomentStore(repository: repository)
        XCTAssertFalse(store.isStorageAvailable)
        XCTAssertNotNil(store.errorMessage)
        for operation in RepositoryMutation.allCases {
            XCTAssertFalse(operation.apply(to: store, moment: original))
        }
        XCTAssertEqual(repository.mutationCalls, 0)
        XCTAssertEqual(repository.moments, [original])
        store.reload()
        XCTAssertFalse(store.isStorageAvailable)
        repository.fetchError = nil
        store.reload()
        XCTAssertTrue(store.isStorageAvailable)
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.moments, [original])
    }

    func testReadFailureKeepsCachedRecordsReadOnly() throws {
        let original = makeRecoveryMoment()
        let repository = InMemoryMomentRepository(moments: [original])
        let store = MomentStore(repository: repository)
        repository.fetchError = TestRepositoryError.readFailed
        store.reload()
        XCTAssertFalse(store.isStorageAvailable)
        XCTAssertEqual(store.moments, [original])
        for operation in RepositoryMutation.allCases {
            XCTAssertFalse(operation.apply(to: store, moment: original))
        }
        XCTAssertEqual(repository.mutationCalls, 0)

        repository.fetchError = nil
        let newer = makeRecoveryMoment()
        try repository.save(newer)
        store.reload()
        XCTAssertTrue(store.isStorageAvailable)
        XCTAssertEqual(Set(store.moments.map(\.id)), Set([original.id, newer.id]))
    }

    func testEachPersistenceFailurePreservesSnapshotAndRequiresReload() {
        for operation in RepositoryMutation.allCases {
            let original = makeRecoveryMoment()
            let repository = InMemoryMomentRepository(moments: [original])
            let store = MomentStore(repository: repository)
            repository.failedMutation = operation
            var changed = original
            changed.privateNote = "Attempted change"
            XCTAssertFalse(operation.apply(to: store, moment: changed))
            XCTAssertEqual(store.moments, [original])
            XCTAssertEqual(repository.moments, [original])
            XCTAssertFalse(store.isStorageAvailable)
            XCTAssertNotNil(store.errorMessage)
            XCTAssertFalse(store.add(changed))
            XCTAssertEqual(repository.mutationCalls, 1)
            repository.failedMutation = nil
            store.reload()
            XCTAssertTrue(store.isStorageAvailable)
            XCTAssertNil(store.errorMessage)
            XCTAssertTrue(operation.apply(to: store, moment: changed))
        }
    }

    func testValidationAndDuplicateBackupErrorsDoNotDisableStorage() {
        let original = makeRecoveryMoment()
        let repository = InMemoryMomentRepository(moments: [original])
        let store = MomentStore(repository: repository)
        var invalid = original
        invalid.privateNote = String(repeating: "x", count: MomentValidator.maximumNoteLength + 1)
        XCTAssertFalse(store.add(invalid))
        XCTAssertTrue(store.isStorageAvailable)
        XCTAssertNil(store.mergeBackup([original, original]))
        XCTAssertTrue(store.isStorageAvailable)
        XCTAssertFalse(store.replaceWithBackup([original, original]))
        XCTAssertTrue(store.isStorageAvailable)
        XCTAssertEqual(repository.mutationCalls, 0)
        XCTAssertEqual(store.moments, [original])
    }

    func testConversionFailurePreservesCachedSnapshotUntilRepair() {
        let original = makeRecoveryMoment()
        let repository = InMemoryMomentRepository(moments: [original])
        let store = MomentStore(repository: repository)
        repository.fetchError = MomentEntityConversionError.unknownMood
        store.reload()
        XCTAssertFalse(store.isStorageAvailable)
        XCTAssertEqual(store.moments, [original])
        XCTAssertEqual(store.errorMessage, AppLocalization.string("A saved entry contains data this version can't safely read. No records were changed."))
        repository.fetchError = nil
        store.reload()
        XCTAssertTrue(store.isStorageAvailable)
        XCTAssertNil(store.errorMessage)
    }
}

@MainActor
final class SwiftDataRecoveryTests: XCTestCase {
    func testSaveFailureRollsBackEveryMutationInRealModelContext() throws {
        for operation in RepositoryMutation.allCases {
            let container = try makeContainer()
            let context = ModelContext(container)
            context.autosaveEnabled = false
            let repository = SwiftDataMomentRepository(modelContext: context)
            let original = makeRecoveryMoment()
            try repository.save(original)
            let failingRepository = SwiftDataMomentRepository(modelContext: context, saveChanges: { _ in
                throw TestRepositoryError.writeFailed
            })
            var changed = original
            changed.privateNote = "Unsaved change"
            XCTAssertThrowsError(try operation.apply(to: failingRepository, moment: changed))
            XCTAssertFalse(context.hasChanges)
            XCTAssertEqual(try repository.fetchAll(), [original], "Rollback failed for \(operation)")
            // Also read through a new context, outside the failed mutation's cache.
            let freshRepository = SwiftDataMomentRepository(modelContext: ModelContext(container))
            XCTAssertEqual(try freshRepository.fetchAll(), [original])
        }
    }

    func testInsertFailureLeavesNoPhantomRecord() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let repository = SwiftDataMomentRepository(modelContext: context, saveChanges: { _ in
            throw TestRepositoryError.writeFailed
        })
        XCTAssertThrowsError(try repository.save(makeRecoveryMoment()))
        XCTAssertEqual(try repository.fetchAll(), [])
        XCTAssertFalse(context.hasChanges)
    }

    func testInvalidPersistedFieldsBlockReadAndRepairRestoresAccess() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let original = makeRecoveryMoment()
        let entity = try MomentEntity(moment: original)
        context.insert(entity)
        try context.save()
        let repository = SwiftDataMomentRepository(modelContext: context)
        let store = MomentStore(repository: repository)
        for corrupt in [
            { entity.moodRawValue = "Unknown mood" },
            { entity.kindRawValue = "Unknown kind" },
            { entity.rating = 9 },
            { entity.durationSeconds = -1 }
        ] {
            corrupt()
            try context.save()
            XCTAssertThrowsError(try repository.fetchAll())
            store.reload()
            XCTAssertFalse(store.isStorageAvailable)
            XCTAssertEqual(store.moments, [original])
            XCTAssertFalse(store.deleteAll())
            // The app never substitutes defaults or rewrites the corrupt record.
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<MomentEntity>()), 1)
            try entity.update(from: original)
            try context.save()
            store.reload()
            XCTAssertTrue(store.isStorageAvailable)
            XCTAssertNil(store.errorMessage)
            XCTAssertEqual(store.moments, [original])
        }
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: PrivateMomentsSchemaV1.self)
        return try ModelContainer(
            for: schema,
            migrationPlan: PrivateMomentsMigrationPlan.self,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
        )
    }
}

private func makeRecoveryMoment() -> Moment {
    Moment(occurredAt: Date(timeIntervalSince1970: 1_000), durationSeconds: 600,
           mood: .calm, rating: 4, tags: ["Connected"], privateNote: "Preserve this note")
}
