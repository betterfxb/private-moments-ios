import SwiftData
import SwiftUI
import OSLog

@main
@MainActor
struct PrivateMomentsApp: App {
    private static let logger = Logger(subsystem: "com.example.PrivateMoments", category: "startup")
    @State private var modelContainer: ModelContainer?
    @State private var startupMessage: String?
    @State private var isRetryingStorage = false
    @State private var privacyLock: AppLockController

    init() {
        _privacyLock = State(initialValue: AppLockController(defaults: PrivateStoreFactory.makePreferences()))
        do {
            _modelContainer = State(initialValue: try PrivateStoreFactory.makeContainer())
            _startupMessage = State(initialValue: nil)
        } catch {
            _modelContainer = State(initialValue: nil)
            Self.logger.error("Could not create the local SwiftData container: \(String(describing: error), privacy: .private)")
            _startupMessage = State(initialValue: Self.startupFailureMessage)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                RootView(modelContext: modelContainer.mainContext)
                    .modelContainer(modelContainer)
                    .environment(privacyLock)
            } else {
                StorageUnavailableView(
                    message: startupMessage ?? AppLocalization.string("Local storage could not be opened."),
                    isRetrying: isRetryingStorage,
                    onRetry: retryStorage
                )
            }
        }
    }

    private func retryStorage() {
        guard !isRetryingStorage else { return }
        isRetryingStorage = true
        Task { @MainActor in
            await Task.yield()
            defer { isRetryingStorage = false }
            do {
                modelContainer = try PrivateStoreFactory.makeContainer()
                startupMessage = nil
            } catch {
                Self.logger.error("Could not open the local SwiftData container on retry: \(String(describing: error), privacy: .private)")
                startupMessage = Self.startupFailureMessage
            }
        }
    }

    private static var startupFailureMessage: String {
        AppLocalization.string("Tap Try again to reopen your local journal. If the problem continues, close and reopen the app.")
    }
}

private struct StorageUnavailableView: View {
    let message: String
    let isRetrying: Bool
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Private storage unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(alignment: .leading, spacing: 8) {
                Text("The app couldn't open its local journal. Your existing entries have not been intentionally deleted.")
                Text(message)
            }
        } actions: {
            Button(action: onRetry) {
                if isRetrying {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Opening local journal…")
                    }
                } else {
                    Label("Try again", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
        }
        .tint(AppColors.accent)
    }
}
