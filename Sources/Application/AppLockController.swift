import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockController {
    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var errorMessage: String?

    @ObservationIgnored private let defaults: UserDefaults
    private let preferenceKey = "privateMoments.appLockEnabled"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let enabled = defaults.bool(forKey: preferenceKey)
        isEnabled = enabled
        isLocked = enabled
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled != isEnabled else { return true }
        let reason = enabled
            ? AppLocalization.string("Protect your private journal.")
            : AppLocalization.string("Turn off the private journal lock.")
        guard await authenticate(reason: reason) else { return false }

        isEnabled = enabled
        isLocked = false
        errorMessage = nil
        defaults.set(enabled, forKey: preferenceKey)
        return true
    }

    @discardableResult
    func unlock() async -> Bool {
        guard isEnabled else {
            isLocked = false
            return true
        }
        guard await authenticate(reason: AppLocalization.string("Unlock your private journal.")) else { return false }
        isLocked = false
        errorMessage = nil
        return true
    }

    func lockForBackground() {
        if isEnabled { isLocked = true }
    }

    private func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var availabilityError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &availabilityError) else {
            errorMessage = AppLocalization.string("Set a device passcode to use the privacy lock.")
            return false
        }

        do {
            let authenticated = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            guard authenticated else {
                errorMessage = AppLocalization.string("Authentication didn't complete. Try again.")
                return false
            }
            errorMessage = nil
            return true
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel:
                errorMessage = nil
            case .passcodeNotSet:
                errorMessage = AppLocalization.string("Set a device passcode to use the privacy lock.")
            default:
                errorMessage = AppLocalization.string("Authentication didn't complete. Try again.")
            }
            return false
        } catch {
            errorMessage = AppLocalization.string("Authentication didn't complete. Try again.")
            return false
        }
    }
}
