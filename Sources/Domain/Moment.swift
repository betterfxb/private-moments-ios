import Foundation

enum MomentMood: String, CaseIterable, Codable, Identifiable, Sendable {
    case calm = "Calm"
    case connected = "Connected"
    case joyful = "Joyful"
    case relaxed = "Relaxed"
    case happy = "Happy"

    var id: String { rawValue }

    var displayName: String { AppLocalization.string(rawValue) }
}

enum MomentKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case together = "Together"
    case solo = "Solo"

    var id: String { rawValue }

    var displayName: String { AppLocalization.string(rawValue) }
}

struct Moment: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var occurredAt: Date
    var durationSeconds: Int
    var mood: MomentMood
    var kind: MomentKind
    var rating: Int
    var tags: [String]
    var privateNote: String
    var approximatePlace: String?
    // Missing in older backups and stores. An explicit false records a removal.
    var favorite: Bool?

    var isFavorite: Bool { favorite == true }

    init(
        id: UUID = UUID(),
        occurredAt: Date = .now,
        durationSeconds: Int,
        mood: MomentMood,
        kind: MomentKind = .together,
        rating: Int,
        tags: [String] = [],
        privateNote: String = "",
        approximatePlace: String? = nil,
        favorite: Bool? = nil
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
        self.favorite = favorite
    }
}

struct MomentRepeatPreset: Hashable {
    let kind: MomentKind
    let tags: [String]

    init(from moment: Moment) {
        kind = moment.kind
        tags = moment.tags
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

enum MomentTags {
    static let builtIn = ["Relaxed", "Connected", "Better sleep"]

    static func key(for tag: String) -> String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    static func distinct(_ tags: [String]) -> [String] {
        var seen: Set<String> = []
        return tags.filter { seen.insert(key(for: $0)).inserted }
    }

    static func adding(_ input: String, to selection: Set<String>, stored: [String]) throws -> Set<String> {
        let clean = input.trimmingCharacters(in: .whitespacesAndNewlines)
        try MomentValidator.validateTag(clean)
        let identity = key(for: clean)
        if selection.contains(where: { key(for: $0) == identity }) { return selection }
        guard selection.count < MomentValidator.maximumTagCount else { throw MomentValidationError.tooManyTags }
        let spelling = stored.first { key(for: $0) == identity } ?? clean
        return selection.union([spelling])
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
        try moment.tags.forEach(validateTag)
        try validatePrivateNote(moment.privateNote)
        if let place = moment.approximatePlace,
           (place.count > maximumPlaceLength || place.utf8.count > maximumPlaceLength * 4) {
            throw MomentValidationError.placeTooLong
        }
    }

    static func validateTag(_ tag: String) throws {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maximumTagLength,
              trimmed.utf8.count <= maximumTagLength * 4 else {
            throw MomentValidationError.invalidTag
        }
    }

    static func validatePrivateNote(_ note: String) throws {
        guard note.count <= maximumNoteLength,
              note.utf8.count <= maximumNoteUTF8Bytes else {
            throw MomentValidationError.noteTooLong
        }
    }
}

/// A form draft, separate from the persisted Moment and its backup contract.
struct MomentTimingDraft {
    var occurredAt: Date
    var minutes: String
    var seconds: String
    private let initialDate: Date
    private let initialSeconds: Int
    private let existingDate: Date?

    init(startedAt: Date, durationSeconds: Int, existingMoment: Moment? = nil) {
        let date = existingMoment?.occurredAt ?? startedAt
        let duration = existingMoment?.durationSeconds ?? durationSeconds
        occurredAt = date
        minutes = String(duration / 60)
        seconds = String(duration % 60)
        initialDate = date
        initialSeconds = duration
        existingDate = existingMoment?.occurredAt
    }

    var hasChanges: Bool {
        occurredAt != initialDate || (try? durationSeconds()) != initialSeconds
    }

    func durationSeconds() throws -> Int {
        func integer(_ text: String) -> Int? {
            let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, clean.allSatisfy({ "0123456789".contains($0) }) else { return nil }
            return Int(clean)
        }
        guard let minuteValue = integer(minutes), let secondValue = integer(seconds),
              (0...MomentValidator.maximumDurationSeconds / 60).contains(minuteValue),
              (0..<60).contains(secondValue) else { throw MomentTimingError.invalidDuration }
        let total = minuteValue * 60 + secondValue
        guard total <= MomentValidator.maximumDurationSeconds else { throw MomentTimingError.invalidDuration }
        return total
    }

    func validate(now: Date = .now) throws {
        guard occurredAt.timeIntervalSince1970.isFinite else { throw MomentValidationError.invalidDate }
        // A previously imported future date can be kept while editing other fields.
        // New dates and changes to that date must not be in the future.
        guard occurredAt <= now || occurredAt == existingDate else { throw MomentTimingError.futureDate }
        _ = try durationSeconds()
    }
}

enum MomentTimingError: LocalizedError, Equatable {
    case invalidDuration
    case futureDate

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            AppLocalization.string("Enter whole minutes and 0–59 seconds, up to 30 days in total.")
        case .futureDate:
            AppLocalization.string("Choose a date and time that is not in the future.")
        }
    }
}

enum MomentReviewPeriod: Hashable {
    case week
    case month

    private var component: Calendar.Component {
        self == .week ? .weekOfYear : .month
    }

    func interval(containing date: Date, calendar: Calendar) -> DateInterval? {
        calendar.dateInterval(of: component, for: date)
    }

    func date(byMoving offset: Int, from date: Date, calendar: Calendar) -> Date? {
        guard let start = interval(containing: date, calendar: calendar)?.start else { return nil }
        return calendar.date(byAdding: component, value: offset, to: start)
    }
}

struct MomentDayRange: Equatable {
    var start: Date
    var end: Date

    func interval(calendar: Calendar) -> DateInterval? {
        let firstDay = calendar.startOfDay(for: start)
        guard let lastDay = calendar.dateInterval(of: .day, for: end), firstDay <= lastDay.start else { return nil }
        return DateInterval(start: firstDay, end: lastDay.end)
    }
}

struct MomentTimelineQuery {
    let kind: MomentKind?
    let favoritesOnly: Bool
    let days: MomentDayRange?
    let tag: String?
    let text: String

    func matching(_ moments: [Moment], calendar: Calendar = .current) -> [Moment] {
        guard kind != nil || favoritesOnly || days != nil || tag != nil || !text.isEmpty else { return moments }
        let tagKey = tag.map(MomentTags.key(for:))
        let interval = days?.interval(calendar: calendar)
        guard days == nil || interval != nil else { return [] }
        return moments.filter { moment in
            if let kind, moment.kind != kind { return false }
            if favoritesOnly && !moment.isFavorite { return false }
            if let interval, !MomentDateQuery.contains(moment.occurredAt, in: interval) { return false }
            if let tagKey, !moment.tags.contains(where: { MomentTags.key(for: $0) == tagKey }) { return false }
            if text.isEmpty { return true }
            let searchable = [
                moment.occurredAt.formatted(date: .abbreviated, time: .shortened),
                moment.mood.rawValue, moment.mood.displayName,
                moment.kind.rawValue, moment.kind.displayName
            ] + moment.tags.flatMap { [$0, AppLocalization.localizedTag($0)] }
            return searchable.joined(separator: " ").localizedCaseInsensitiveContains(text)
        }
    }
}

enum MomentDateQuery {
    static func onDay(_ moments: [Moment], date: Date, calendar: Calendar = .current) -> [Moment] {
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return [] }
        return within(moments, interval: interval)
    }

    static func review(_ moments: [Moment], period: MomentReviewPeriod, containing date: Date, calendar: Calendar) -> MomentReview? {
        guard let interval = period.interval(containing: date, calendar: calendar) else { return nil }
        return MomentReview(interval: interval, moments: within(moments, interval: interval))
    }

    static func previousReview(_ moments: [Moment], period: MomentReviewPeriod,
                               from current: MomentReview, calendar: Calendar) -> MomentReview? {
        guard !current.moments.isEmpty,
              let date = period.date(byMoving: -1, from: current.interval.start, calendar: calendar),
              let previous = review(moments, period: period, containing: date, calendar: calendar),
              !previous.moments.isEmpty else { return nil }
        return previous
    }

    private static func within(_ moments: [Moment], interval: DateInterval) -> [Moment] {
        moments.filter { contains($0.occurredAt, in: interval) }
    }

    static func contains(_ date: Date, in interval: DateInterval) -> Bool {
        // DateInterval.contains includes its upper bound, which belongs to the next period here.
        date >= interval.start && date < interval.end
    }
}

struct MomentReview {
    struct MoodCount: Identifiable {
        let mood: MomentMood
        let count: Int
        var id: MomentMood { mood }
    }

    struct DayGroup: Identifiable {
        let date: Date
        let moments: [Moment]
        var id: Date { date }
    }

    let interval: DateInterval
    let moments: [Moment]

    func dayGroups(matching mood: MomentMood? = nil, favoritesOnly: Bool = false, calendar: Calendar) -> [DayGroup] {
        let matches = moments.filter { (mood == nil || $0.mood == mood) && (!favoritesOnly || $0.isFavorite) }
        return Dictionary(grouping: matches, by: { calendar.startOfDay(for: $0.occurredAt) })
            .map { DayGroup(date: $0.key, moments: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var favoriteCount: Int { moments.lazy.filter(\.isFavorite).count }

    var moods: [MoodCount] {
        var counts: [MomentMood: Int] = [:]
        for moment in moments { counts[moment.mood, default: 0] += 1 }
        return MomentMood.allCases.compactMap { mood in
            counts[mood].map { MoodCount(mood: mood, count: $0) }
        }
    }

    var commonMoods: [MoodCount] {
        let counts = moods
        guard let highest = counts.map(\.count).max(), highest >= 2 else { return [] }
        return counts.filter { $0.count == highest }
    }

    func dayCount(calendar: Calendar) -> Int {
        Set(moments.map { calendar.startOfDay(for: $0.occurredAt) }).count
    }
}

struct MomentMonthCalendar {
    struct Day: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    let firstDayOffset: Int
    let days: [Day]

    init(review: MomentReview, calendar: Calendar) {
        let start = review.interval.start
        firstDayOffset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let counts = Dictionary(uniqueKeysWithValues: review.dayGroups(calendar: calendar).map { ($0.date, $0.moments.count) })
        let daysInMonth = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        days = (0..<daysInMonth).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start),
                  MomentDateQuery.contains(date, in: review.interval) else { return nil }
            let day = calendar.startOfDay(for: date)
            return Day(date: day, count: counts[day, default: 0])
        }
    }
}
