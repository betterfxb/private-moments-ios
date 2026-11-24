import Foundation
import Observation
import OSLog

struct RecapDraft: Codable, Equatable {
    let id: UUID
    let editingID: UUID?
    let isManualEntry: Bool
    let startedAt: Date
    let originalDuration: Int
    let occurredAt: Date
    let minutes: String
    let seconds: String
    let mood: MomentMood
    let kind: MomentKind
    let rating: Int
    let tags: [String]
    let note: String

    func alreadySaved(in moments: [Moment]) -> Bool {
        guard let saved = moments.first(where: { $0.id == (editingID ?? id) }) else { return false }
        // A new record keeps the draft's UUID, even if the process ended
        // between committing the record and removing the draft file.
        guard editingID != nil else { return true }
        var timing = MomentTimingDraft(startedAt: startedAt, durationSeconds: originalDuration, existingMoment: saved)
        timing.minutes = minutes
        timing.seconds = seconds
        return occurredAt == saved.occurredAt && (try? timing.durationSeconds()) == saved.durationSeconds
            && mood == saved.mood && kind == saved.kind && rating == saved.rating
            && Set(tags) == Set(saved.tags) && note.trimmingCharacters(in: .whitespacesAndNewlines) == saved.privateNote
    }
}

@MainActor
@Observable
final class RecapDraftStore {
    private(set) var draft: RecapDraft?
    private(set) var readFailed = false
    @ObservationIgnored private let url: URL
    @ObservationIgnored private let logger = Logger(subsystem: "com.example.PrivateMoments", category: "draft")
    private static let maximumBytes = 512 * 1024

    init(directory: URL) {
        url = directory.appendingPathComponent("RecapDraft.json")
        reload()
    }

    func reload() {
        do {
            let file = try FileHandle(forReadingFrom: url)
            let data = try file.read(upToCount: Self.maximumBytes + 1) ?? Data()
            try file.close()
            guard data.count <= Self.maximumBytes else { throw CocoaError(.fileReadCorruptFile) }
            let decoded = try JSONDecoder().decode(RecapDraft.self, from: data)
            guard (1...5).contains(decoded.rating),
                  decoded.startedAt.timeIntervalSinceReferenceDate.isFinite,
                  decoded.occurredAt.timeIntervalSinceReferenceDate.isFinite,
                  (0...MomentValidator.maximumDurationSeconds).contains(decoded.originalDuration) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            draft = decoded
            readFailed = false
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            draft = nil
            readFailed = false
        } catch {
            logger.error("Cannot read local draft: \(String(describing: error), privacy: .private)")
            readFailed = true
        }
    }

    @discardableResult
    func save(_ value: RecapDraft) -> Bool {
        guard !readFailed, draft == nil || draft?.id == value.id else { return false }
        guard draft != value else { return true }
        do {
            let data = try JSONEncoder().encode(value)
            guard data.count <= Self.maximumBytes else { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            draft = value
            return true
        } catch {
            logger.error("Cannot save local draft: \(String(describing: error), privacy: .private)")
            return false
        }
    }

    @discardableResult
    func discard(id: UUID? = nil) -> Bool {
        if let id, draft?.id != id { return true }
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as CocoaError where error.code == .fileNoSuchFile || error.code == .fileReadNoSuchFile {
            // An already absent file has the requested state.
        } catch {
            logger.error("Cannot remove local draft: \(String(describing: error), privacy: .private)")
            return false
        }
        draft = nil
        readFailed = false
        return true
    }
}
