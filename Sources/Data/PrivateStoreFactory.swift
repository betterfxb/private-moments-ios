import Foundation
import SwiftData

enum PrivateMomentsSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [MomentEntity.self] }
}

enum PrivateMomentsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PrivateMomentsSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
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

    static func makeContainer() throws -> ModelContainer {
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

        let schema = Schema(versionedSchema: PrivateMomentsSchemaV1.self)
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
        return container
    }
}
