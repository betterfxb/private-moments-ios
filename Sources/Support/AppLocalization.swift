import Foundation

enum AppLocalization {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ value: Int) -> String {
        String.localizedStringWithFormat(string(key), Int64(value))
    }

    static func format(_ key: String, _ first: Int, _ second: Int) -> String {
        String.localizedStringWithFormat(string(key), Int64(first), Int64(second))
    }

    static func format(_ key: String, _ first: String, _ second: String) -> String {
        String.localizedStringWithFormat(string(key), first, second)
    }

    static func momentCount(_ count: Int) -> String {
        count == 1 ? string("1 moment") : format("%lld moments", count)
    }

    static func localizedTag(_ rawValue: String) -> String {
        let builtInTags = ["Relaxed", "Connected", "Better sleep"]
        guard builtInTags.contains(rawValue) else { return rawValue }
        return string(rawValue)
    }
}
