import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class MomentStore {
    private(set) var moments: [Moment] = []
    private(set) var errorMessage: String?
    private(set) var isStorageAvailable = false

    @ObservationIgnored private let repository: any MomentRepository
    @ObservationIgnored private let logger = Logger(subsystem: "com.example.PrivateMoments", category: "storage")

    init(repository: any MomentRepository) {
        self.repository = repository
        reload()
    }

    var recentMoments: [Moment] {
        Array(moments.prefix(3))
    }

    var averageDurationMinutes: Int? {
        guard !moments.isEmpty else { return nil }
        let totalSeconds = moments.reduce(0.0) { $0 + Double($1.durationSeconds) }
        return Int((totalSeconds / Double(moments.count) / 60).rounded())
    }

    var mostCommonMood: MomentMood? {
        moments
            .reduce(into: [MomentMood: Int]()) { counts, moment in
                counts[moment.mood, default: 0] += 1
            }
            .max { $0.value < $1.value }?.key
    }

    func reload() {
        do {
            moments = try repository.fetchAll()
            isStorageAvailable = true
            errorMessage = nil
        } catch {
            isStorageAvailable = false
            logger.error("Failed to load local moments: \(String(describing: error), privacy: .private)")
            errorMessage = error is MomentEntityConversionError
                ? AppLocalization.string("A saved entry contains data this version can't safely read. No records were changed.")
                : AppLocalization.string("Couldn't load your moments. Please try again.")
        }
    }

    @discardableResult
    func add(_ moment: Moment) -> Bool {
        guard ensureStorageAvailable() else { return false }
        do {
            try MomentValidator.validate(moment)
            try repository.save(moment)
            upsertInMemory(moment)
            errorMessage = nil
            return true
        } catch {
            logger.error("Failed to save a local moment: \(String(describing: error), privacy: .private)")
            if let validationError = error as? MomentValidationError {
                errorMessage = validationError.localizedDescription
            } else {
                isStorageAvailable = false
                errorMessage = AppLocalization.string("Couldn't save this moment. Your existing entries are unchanged.")
            }
            return false
        }
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        guard ensureStorageAvailable() else { return false }
        do {
            try repository.delete(id: id)
            moments.removeAll { $0.id == id }
            errorMessage = nil
            return true
        } catch {
            isStorageAvailable = false
            logger.error("Failed to delete a local moment: \(String(describing: error), privacy: .private)")
            errorMessage = AppLocalization.string("Couldn't delete this moment. Please try again.")
            return false
        }
    }

    @discardableResult
    func deleteAll() -> Bool {
        guard ensureStorageAvailable() else { return false }
        do {
            try repository.deleteAll()
            moments = []
            errorMessage = nil
            return true
        } catch {
            isStorageAvailable = false
            logger.error("Failed to delete all local moments: \(String(describing: error), privacy: .private)")
            errorMessage = AppLocalization.string("Couldn't delete your local entries. Please try again.")
            return false
        }
    }

    @discardableResult
    func mergeBackup(_ importedMoments: [Moment]) -> Int? {
        guard ensureStorageAvailable() else { return nil }
        do {
            try importedMoments.forEach(MomentValidator.validate)
            guard Set(importedMoments.map(\.id)).count == importedMoments.count else {
                throw MomentBackupError.duplicateRecordID
            }
            let existingIDs = Set(moments.map(\.id))
            try repository.mergeAll(importedMoments)
            let importedIDs = Set(importedMoments.map(\.id))
            moments = sorted(moments.filter { !importedIDs.contains($0.id) } + importedMoments)
            errorMessage = nil
            return importedMoments.reduce(into: 0) { count, moment in
                if !existingIDs.contains(moment.id) { count += 1 }
            }
        } catch {
            logger.error("Failed to merge a local backup: \(String(describing: error), privacy: .private)")
            switch error {
            case let validationError as MomentValidationError:
                errorMessage = validationError.localizedDescription
            case let backupError as MomentBackupError:
                errorMessage = backupError.localizedDescription
            default:
                isStorageAvailable = false
                errorMessage = AppLocalization.string("Couldn't merge this backup. Your existing records are unchanged.")
            }
            return nil
        }
    }

    @discardableResult
    func replaceWithBackup(_ importedMoments: [Moment]) -> Bool {
        guard ensureStorageAvailable() else { return false }
        do {
            try importedMoments.forEach(MomentValidator.validate)
            guard Set(importedMoments.map(\.id)).count == importedMoments.count else {
                throw MomentBackupError.duplicateRecordID
            }
            try repository.replaceAll(with: importedMoments)
            moments = sorted(importedMoments)
            errorMessage = nil
            return true
        } catch {
            logger.error("Failed to replace local records from backup: \(String(describing: error), privacy: .private)")
            switch error {
            case let validationError as MomentValidationError:
                errorMessage = validationError.localizedDescription
            case let backupError as MomentBackupError:
                errorMessage = backupError.localizedDescription
            default:
                isStorageAvailable = false
                errorMessage = AppLocalization.string("Couldn't restore this backup. Your existing records are unchanged.")
            }
            return false
        }
    }

    private func upsertInMemory(_ moment: Moment) {
        moments = sorted(moments.filter { $0.id != moment.id } + [moment])
    }

    private func ensureStorageAvailable() -> Bool {
        guard isStorageAvailable else {
            if errorMessage == nil {
                errorMessage = AppLocalization.string("Couldn't load your moments. Please try again.")
            }
            return false
        }
        return true
    }

    private func sorted(_ values: [Moment]) -> [Moment] {
        values.sorted { $0.occurredAt > $1.occurredAt }
    }
}
