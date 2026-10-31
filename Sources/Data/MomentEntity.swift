import Foundation
import SwiftData

enum MomentEntityConversionError: Error {
    case invalidTagEncoding
    case invalidTagPayload
    case unknownMood
    case unknownKind
    case invalidStoredRecord
}

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
        let encodedTags = try Self.encodeTags(moment.tags)
        id = moment.id
        occurredAt = moment.occurredAt
        durationSeconds = moment.durationSeconds
        moodRawValue = moment.mood.rawValue
        kindRawValue = moment.kind.rawValue
        rating = moment.rating
        tagsJSON = encodedTags
        privateNote = moment.privateNote
        approximatePlace = moment.approximatePlace
    }

    func makeDomainValue() throws -> Moment {
        guard let mood = MomentMood(rawValue: moodRawValue) else {
            throw MomentEntityConversionError.unknownMood
        }
        guard let kind = MomentKind(rawValue: kindRawValue) else {
            throw MomentEntityConversionError.unknownKind
        }
        guard (0...MomentValidator.maximumDurationSeconds).contains(durationSeconds),
              (1...5).contains(rating) else {
            throw MomentEntityConversionError.invalidStoredRecord
        }

        let moment = Moment(
            id: id,
            occurredAt: occurredAt,
            durationSeconds: durationSeconds,
            mood: mood,
            kind: kind,
            rating: rating,
            tags: try Self.decodeTags(tagsJSON),
            privateNote: privateNote,
            approximatePlace: approximatePlace
        )

        do {
            try MomentValidator.validate(moment)
        } catch {
            throw MomentEntityConversionError.invalidStoredRecord
        }
        return moment
    }

    func update(from moment: Moment) throws {
        let encodedTags = try Self.encodeTags(moment.tags)
        occurredAt = moment.occurredAt
        durationSeconds = moment.durationSeconds
        moodRawValue = moment.mood.rawValue
        kindRawValue = moment.kind.rawValue
        rating = moment.rating
        tagsJSON = encodedTags
        privateNote = moment.privateNote
        approximatePlace = moment.approximatePlace
    }

    private static func encodeTags(_ tags: [String]) throws -> String {
        let data = try JSONEncoder().encode(tags)
        guard let value = String(data: data, encoding: .utf8) else {
            throw MomentEntityConversionError.invalidTagEncoding
        }
        return value
    }

    private static func decodeTags(_ value: String) throws -> [String] {
        guard let data = value.data(using: .utf8) else {
            throw MomentEntityConversionError.invalidTagPayload
        }
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            throw MomentEntityConversionError.invalidTagPayload
        }
    }
}
