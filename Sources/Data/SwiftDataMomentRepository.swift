import Foundation
import SwiftData

@MainActor
final class SwiftDataMomentRepository: MomentRepository {
    private let modelContext: ModelContext
    private let saveChanges: @MainActor (ModelContext) throws -> Void

    init(modelContext: ModelContext, saveChanges: @escaping @MainActor (ModelContext) throws -> Void = { try $0.save() }) {
        self.modelContext = modelContext
        self.saveChanges = saveChanges
    }

    func fetchAll() throws -> [Moment] {
        let descriptor = FetchDescriptor<MomentEntity>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { try $0.makeDomainValue() }
    }

    func save(_ moment: Moment) throws {
        try MomentValidator.validate(moment)
        let momentID = moment.id
        try performTransaction {
            var descriptor = FetchDescriptor<MomentEntity>(
                predicate: #Predicate { $0.id == momentID }
            )
            descriptor.fetchLimit = 1

            if let existing = try modelContext.fetch(descriptor).first {
                try existing.update(from: moment)
            } else {
                modelContext.insert(try MomentEntity(moment: moment))
            }
        }
    }

    func mergeAll(_ moments: [Moment]) throws {
        try moments.forEach(MomentValidator.validate)
        guard Set(moments.map(\.id)).count == moments.count else {
            throw MomentBackupError.duplicateRecordID
        }

        try performTransaction {
            let entities = try modelContext.fetch(FetchDescriptor<MomentEntity>())
            var entitiesByID = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })

            for moment in moments {
                if let entity = entitiesByID[moment.id] {
                    try entity.update(from: moment)
                } else {
                    let entity = try MomentEntity(moment: moment)
                    modelContext.insert(entity)
                    entitiesByID[moment.id] = entity
                }
            }
        }
    }

    func replaceAll(with moments: [Moment]) throws {
        try moments.forEach(MomentValidator.validate)
        guard Set(moments.map(\.id)).count == moments.count else {
            throw MomentBackupError.duplicateRecordID
        }

        try performTransaction {
            let entities = try modelContext.fetch(FetchDescriptor<MomentEntity>())
            for entity in entities {
                modelContext.delete(entity)
            }
            for moment in moments {
                modelContext.insert(try MomentEntity(moment: moment))
            }
        }
    }

    func delete(id: UUID) throws {
        try performTransaction {
            var descriptor = FetchDescriptor<MomentEntity>(
                predicate: #Predicate { $0.id == id }
            )
            descriptor.fetchLimit = 1
            if let entity = try modelContext.fetch(descriptor).first {
                modelContext.delete(entity)
            }
        }
    }

    func deleteAll() throws {
        try performTransaction {
            let entities = try modelContext.fetch(FetchDescriptor<MomentEntity>())
            for entity in entities {
                modelContext.delete(entity)
            }
        }
    }

    private func performTransaction(_ changes: () throws -> Void) throws {
        do {
            try changes()
            if modelContext.hasChanges {
                try saveChanges(modelContext)
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
