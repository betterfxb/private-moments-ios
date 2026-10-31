import Foundation
import Observation

struct CompletedSession: Hashable {
    let startedAt: Date
    let durationSeconds: Int
}

@MainActor
@Observable
final class SessionClock {
    private let clock = ContinuousClock()
    private(set) var startedAt: ContinuousClock.Instant?
    private(set) var sessionStartDate: Date?
    private(set) var accumulatedSeconds: Int = 0
    private(set) var isPaused = false

    var elapsedSeconds: Int {
        let current = startedAt.map { Int((clock.now - $0).components.seconds) } ?? 0
        return accumulatedSeconds + max(0, current)
    }

    var isRunning: Bool { startedAt != nil }

    func startFresh() {
        accumulatedSeconds = 0
        startedAt = clock.now
        sessionStartDate = .now
        isPaused = false
    }

    func togglePause() {
        if startedAt != nil {
            accumulatedSeconds = elapsedSeconds
            self.startedAt = nil
            isPaused = true
        } else {
            startedAt = clock.now
            isPaused = false
        }
    }

    func finish() -> CompletedSession {
        let result = CompletedSession(
            startedAt: sessionStartDate ?? .now,
            durationSeconds: elapsedSeconds
        )
        startedAt = nil
        sessionStartDate = nil
        accumulatedSeconds = 0
        isPaused = false
        return result
    }

    static func clockText(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let remainder = max(0, seconds) % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    static func durationText(_ seconds: Int) -> String {
        guard seconds >= 60 else { return AppLocalization.string("Under a minute") }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return remainder == 0
            ? AppLocalization.format("%lld min", minutes)
            : AppLocalization.format("%lld min %lld sec", minutes, remainder)
    }
}
