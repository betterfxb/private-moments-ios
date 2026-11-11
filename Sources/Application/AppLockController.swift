import LocalAuthentication
import Observation
import OSLog

enum JournalAuthenticationResult {
    case authenticated, cancelled, passcodeRequired, unavailable, failed
}

@MainActor
protocol JournalAuthenticating: AnyObject {
    func authenticate(reason: String) async -> JournalAuthenticationResult
    func cancel()
}

@MainActor
final class SystemJournalAuthenticator: JournalAuthenticating {
    private var currentContext: LAContext?
    private let logger = Logger(subsystem: "com.example.PrivateMoments", category: "authentication")

    func authenticate(reason: String) async -> JournalAuthenticationResult {
        let context = LAContext()
        currentContext = context
        defer { if currentContext === context { currentContext = nil } }
        var availabilityError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &availabilityError) else {
            if availabilityError?.domain == LAError.errorDomain,
               availabilityError?.code == LAError.Code.passcodeNotSet.rawValue { return .passcodeRequired }
            logger.error("Device authentication unavailable: \(String(describing: availabilityError), privacy: .private)")
            return .unavailable
        }
        do {
            let authenticated = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            return authenticated ? .authenticated : .failed
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel: return .cancelled
            case .passcodeNotSet: return .passcodeRequired
            default:
                logger.error("Device authentication failed: \(String(describing: error), privacy: .private)")
                return .failed
            }
        } catch {
            logger.error("Device authentication failed: \(String(describing: error), privacy: .private)")
            return .failed
        }
    }

    func cancel() {
        currentContext?.invalidate()
        currentContext = nil
    }
}

@MainActor
@Observable
final class AppLockController {
    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let authenticator: any JournalAuthenticating
    @ObservationIgnored private var activeAttempt: UUID?
    private let preferenceKey = "privateMoments.appLockEnabled"

    init(defaults: UserDefaults = .standard, authenticator: (any JournalAuthenticating)? = nil) {
        self.defaults = defaults
        self.authenticator = authenticator ?? SystemJournalAuthenticator()
        let enabled = defaults.bool(forKey: preferenceKey)
        isEnabled = enabled
        isLocked = enabled
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard !isAuthenticating else { return false }
        guard enabled != isEnabled else { return true }
        let reason = enabled
            ? AppLocalization.string("Protect your private journal.")
            : AppLocalization.string("Turn off the private journal lock.")
        return await authenticate(reason: reason) {
            self.isEnabled = enabled
            self.isLocked = false
            self.defaults.set(enabled, forKey: self.preferenceKey)
        }
    }

    @discardableResult
    func unlock() async -> Bool {
        guard !isAuthenticating else { return false }
        guard isEnabled else { isLocked = false; return true }
        return await authenticate(reason: AppLocalization.string("Unlock your private journal.")) {
            self.isLocked = false
        }
    }

    func lockForBackground() {
        // The root shield covers inactive authentication prompts. Only a real
        // background transition cancels an evaluation and always locks below.
        if isEnabled && !isAuthenticating { isLocked = true }
    }

    func cancelAuthenticationForBackground() {
        if isEnabled { isLocked = true }
        activeAttempt = nil
        isAuthenticating = false
        authenticator.cancel()
        errorMessage = nil
    }

    private func authenticate(reason: String, onSuccess: () -> Void) async -> Bool {
        guard !isAuthenticating else { return false }
        let attempt = UUID()
        activeAttempt = attempt
        isAuthenticating = true
        errorMessage = nil
        defer {
            if activeAttempt == attempt {
                activeAttempt = nil
                isAuthenticating = false
            }
        }
        let result = await authenticator.authenticate(reason: reason)
        guard activeAttempt == attempt else { return false }
        switch result {
        case .authenticated:
            // Commit within the same MainActor turn as the attempt check.
            onSuccess()
            return true
        case .cancelled:
            return false
        case .passcodeRequired:
            errorMessage = AppLocalization.string("Set a device passcode to use the privacy lock.")
        case .unavailable:
            errorMessage = AppLocalization.string("Device authentication is unavailable. Try again.")
        case .failed:
            errorMessage = AppLocalization.string("Authentication didn't complete. Try again.")
        }
        return false
    }
}
