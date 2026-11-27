import Foundation
import SwiftData

enum PrivateMomentsSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [MomentEntity.self] }

    @Model
    final class MomentEntity {
        @Attribute(.unique) var id: UUID
        var occurredAt: Date
        var durationSeconds: Int
        var moodRawValue: String
        var kindRawValue: String
        var rating: Int
        private var tagsJSON: String
        var privateNote: String
        var approximatePlace: String?

        init(moment: Moment) throws {
            id = moment.id
            occurredAt = moment.occurredAt
            durationSeconds = moment.durationSeconds
            moodRawValue = moment.mood.rawValue
            kindRawValue = moment.kind.rawValue
            rating = moment.rating
            tagsJSON = String(decoding: try JSONEncoder().encode(moment.tags), as: UTF8.self)
            privateNote = moment.privateNote
            approximatePlace = moment.approximatePlace
        }
    }
}

enum PrivateMomentsSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [MomentEntity.self] }
}

enum PrivateMomentsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PrivateMomentsSchemaV1.self, PrivateMomentsSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: PrivateMomentsSchemaV1.self, toVersion: PrivateMomentsSchemaV2.self)]
    }
}

enum PrivateStoreFactory {
    static func makePreferences(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        #if DEBUG
        if let identifier = uiTestStoreIdentifier(arguments: arguments) {
            guard let defaults = UserDefaults(suiteName: "PrivateMoments-UITests." + identifier.uuidString) else {
                preconditionFailure("Could not create isolated UI-test preferences.")
            }
            return defaults
        }
        #endif
        return .standard
    }

    #if DEBUG
    static func uiTestStoreIdentifier(arguments: [String] = ProcessInfo.processInfo.arguments) -> UUID? {
        guard let index = arguments.firstIndex(of: "-pm-ui-test-store"),
              arguments.indices.contains(index + 1) else { return nil }
        return UUID(uuidString: arguments[index + 1])
    }

    static func uiTestSaveFailureEnabled(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        uiTestStoreIdentifier(arguments: arguments) != nil
            && arguments.contains("-pm-ui-test-fail-save-once")
    }
    #endif

    @MainActor
    static func makeJournal() throws -> (container: ModelContainer, drafts: RecapDraftStore) {
        let fileManager = FileManager.default
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory: URL
        #if DEBUG
        // UI tests use their own persistent sandbox. Relaunch tests reuse the UUID;
        // no test setup erases or opens the normal journal.
        if let identifier = uiTestStoreIdentifier() {
            directory = applicationSupport
                .appendingPathComponent("PrivateMoments-UITests", isDirectory: true)
                .appendingPathComponent(identifier.uuidString, isDirectory: true)
        } else {
            directory = applicationSupport.appendingPathComponent("PrivateMoments", isDirectory: true)
        }
        #else
        directory = applicationSupport.appendingPathComponent("PrivateMoments", isDirectory: true)
        #endif
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )

        var directoryURL = directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try directoryURL.setResourceValues(resourceValues)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: directory.path
        )

        let schema = Schema(versionedSchema: PrivateMomentsSchemaV2.self)
        let storeURL = directory.appendingPathComponent("PrivateMoments.store")
        let configuration = ModelConfiguration(
            "PrivateMoments",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: PrivateMomentsMigrationPlan.self,
            configurations: [configuration]
        )

        #if DEBUG
        if uiTestStoreIdentifier() != nil,
           ProcessInfo.processInfo.arguments.contains("-pm-ui-test-performance-fixture") {
            try seedPerformanceFixture(in: container)
        }
        if uiTestStoreIdentifier() != nil,
           ProcessInfo.processInfo.arguments.contains("-pm-ui-test-review-comparison-fixture") {
            try seedMonthlyComparisonFixture(in: container)
        }
        if uiTestStoreIdentifier() != nil,
           let note = ProcessInfo.processInfo.environment["PM_UI_TEST_READING_NOTE"], !note.isEmpty {
            try seedReadingFixture(note: note, in: container)
        }
        #endif

        // Apply protection to store files created by SwiftData as well as the containing directory.
        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        )) ?? []
        for fileURL in fileURLs {
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true {
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: fileURL.path
                )
            }
        }
        return (container, RecapDraftStore(directory: directory))
    }

    #if DEBUG
    @MainActor
    private static func seedPerformanceFixture(in container: ModelContainer) throws {
        let context = container.mainContext
        guard try context.fetchCount(FetchDescriptor<MomentEntity>()) == 0 else { return }
        let latest = Date.now.addingTimeInterval(-60)
        let moments = (0..<1_000).map { index in
            Moment(occurredAt: latest.addingTimeInterval(-Double(index) * 3_600),
                   durationSeconds: 60 + index % 300,
                   mood: .calm,
                   rating: 4,
                   tags: index == 0 ? ["baseline-target"] : [],
                   privateNote: "synthetic-fixture")
        }
        try SwiftDataMomentRepository(modelContext: context).mergeAll(moments)
    }

    @MainActor
    private static func seedMonthlyComparisonFixture(in container: ModelContainer) throws {
        let context = container.mainContext
        guard try context.fetchCount(FetchDescriptor<MomentEntity>()) == 0 else { return }
        let now = Date.now
        let calendar = Calendar.current
        guard let prior = MomentReviewPeriod.month.date(byMoving: -1, from: now, calendar: calendar) else {
            throw CocoaError(.coderInvalidValue)
        }
        let moments = [
            Moment(occurredAt: now, durationSeconds: 80, mood: .connected, rating: 4, tags: ["Connected"]),
            Moment(occurredAt: prior, durationSeconds: 90, mood: .calm, rating: 3,
                   tags: ["Connected"], privateNote: "previous-month-first-entry", favorite: true),
            Moment(occurredAt: prior.addingTimeInterval(90), durationSeconds: 120, mood: .calm, rating: 5,
                   tags: ["Connected", "Quiet mornings and slow conversations"], privateNote: "previous-month-second-entry")
        ]
        try SwiftDataMomentRepository(modelContext: context).mergeAll(moments)
    }

    @MainActor
    private static func seedReadingFixture(note: String, in container: ModelContainer) throws {
        let context = container.mainContext
        guard try context.fetchCount(FetchDescriptor<MomentEntity>()) == 0 else { return }
        let date = Date(timeIntervalSince1970: 1_761_770_400)
        let moments = [
            Moment(occurredAt: date, durationSeconds: 420, mood: .happy, rating: 5,
                   tags: ["Connected"], privateNote: note, favorite: true),
            Moment(occurredAt: date.addingTimeInterval(-3_600), durationSeconds: 125, mood: .calm,
                   kind: .solo, rating: 4, tags: ["Relaxed"]),
        ]
        try SwiftDataMomentRepository(modelContext: context).mergeAll(moments)
    }
    #endif
}
