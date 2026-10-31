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
    static func makeContainer() throws -> ModelContainer {
        let fileManager = FileManager.default
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport.appendingPathComponent("PrivateMoments", isDirectory: true)
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
