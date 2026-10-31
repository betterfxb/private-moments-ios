import Foundation

enum MomentMood: String, CaseIterable, Codable, Identifiable {
    case calm = "Calm"
    case connected = "Connected"
    case joyful = "Joyful"
    case relaxed = "Relaxed"
    case happy = "Happy"

    var id: String { rawValue }

    var displayName: String { AppLocalization.string(rawValue) }
}

enum MomentKind: String, CaseIterable, Codable, Identifiable {
    case together = "Together"
    case solo = "Solo"

    var id: String { rawValue }

    var displayName: String { AppLocalization.string(rawValue) }
}

struct Moment: Identifiable, Codable, Hashable {
    let id: UUID
    var occurredAt: Date
    var durationSeconds: Int
    var mood: MomentMood
    var kind: MomentKind
    var rating: Int
    var tags: [String]
    var privateNote: String
    var approximatePlace: String?

    init(
        id: UUID = UUID(),
        occurredAt: Date = .now,
        durationSeconds: Int,
        mood: MomentMood,
        kind: MomentKind = .together,
        rating: Int,
        tags: [String] = [],
        privateNote: String = "",
        approximatePlace: String? = nil
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.durationSeconds = max(0, durationSeconds)
        self.mood = mood
        self.kind = kind
        self.rating = min(max(rating, 1), 5)
        self.tags = tags
        self.privateNote = privateNote
        self.approximatePlace = approximatePlace
    }
}

enum MomentValidationError: LocalizedError, Equatable {
    case invalidDuration
    case invalidRating
    case tooManyTags
    case invalidTag
    case noteTooLong
    case placeTooLong
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return AppLocalization.string("A moment must be between zero and 30 days long.")
        case .invalidRating:
            return AppLocalization.string("Choose a rating from 1 to 5.")
        case .tooManyTags:
            return AppLocalization.string("A moment can have up to 20 tags.")
        case .invalidTag:
            return AppLocalization.string("Each tag must contain 1 to 64 characters.")
        case .noteTooLong:
            return AppLocalization.string("Private notes can contain up to 10,000 characters or 60 KB.")
        case .placeTooLong:
            return AppLocalization.string("A place label can contain up to 160 characters.")
        case .invalidDate:
            return AppLocalization.string("The moment has an invalid date.")
        }
    }
}

enum MomentValidator {
    static let maximumDurationSeconds = 30 * 24 * 60 * 60
    static let maximumTagCount = 20
    static let maximumTagLength = 64
    static let maximumNoteLength = 10_000
    static let maximumNoteUTF8Bytes = 60 * 1024
    static let maximumPlaceLength = 160

    static func validate(_ moment: Moment) throws {
        guard moment.occurredAt.timeIntervalSince1970.isFinite else {
            throw MomentValidationError.invalidDate
        }
        guard (0...maximumDurationSeconds).contains(moment.durationSeconds) else {
            throw MomentValidationError.invalidDuration
        }
        guard (1...5).contains(moment.rating) else {
            throw MomentValidationError.invalidRating
        }
        guard moment.tags.count <= maximumTagCount else {
            throw MomentValidationError.tooManyTags
        }
        guard moment.tags.allSatisfy({
            let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty
                && trimmed.count <= maximumTagLength
                && trimmed.utf8.count <= maximumTagLength * 4
        }) else {
            throw MomentValidationError.invalidTag
        }
        try validatePrivateNote(moment.privateNote)
        if let place = moment.approximatePlace,
           (place.count > maximumPlaceLength || place.utf8.count > maximumPlaceLength * 4) {
            throw MomentValidationError.placeTooLong
        }
    }

    static func validatePrivateNote(_ note: String) throws {
        guard note.count <= maximumNoteLength,
              note.utf8.count <= maximumNoteUTF8Bytes else {
            throw MomentValidationError.noteTooLong
        }
    }
}
