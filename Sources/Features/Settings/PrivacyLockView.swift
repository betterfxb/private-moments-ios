import SwiftUI

struct PrivacyLockView: View {
    @Environment(AppLockController.self) private var lockController

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(AppColors.accentText)
                    .frame(width: 68, height: 68)
                    .background(AppColors.accentWash, in: Circle())
                    .accessibilityHidden(true)
                Text("Your journal is private")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                Text(
                    lockController.isEnabled
                        ? "Unlock with the authentication method configured on this device."
                        : "Your entries are hidden while the app is inactive."
                )
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)

                if let errorMessage = lockController.errorMessage {
                    ErrorNotice(message: errorMessage)
                }

                if lockController.isEnabled {
                    Button {
                        Task { await lockController.unlock() }
                    } label: {
                        if lockController.isAuthenticating {
                            ProgressView("Authenticating…").tint(AppColors.onAccent)
                        } else {
                            Label("Unlock journal", systemImage: "lock.open.fill")
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(lockController.isAuthenticating)
                    .accessibilityIdentifier("privacy.unlock")
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .frame(maxWidth: 420)
        }
        .accessibilityAddTraits(.isModal)
    }
}
