import SwiftUI

struct PrivacyLockView: View {
    @Environment(AppLockController.self) private var lockController

    var body: some View {
        ZStack {
            AppColors.cream.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(AppColors.terracotta)
                    .frame(width: 68, height: 68)
                    .background(AppColors.blush.opacity(0.18), in: Circle())
                    .accessibilityHidden(true)
                Text("Your journal is private")
                    .font(.system(.largeTitle, design: .serif))
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)
                Text(
                    lockController.isEnabled
                        ? "Unlock with the authentication method configured on this device."
                        : "Your entries are hidden while the app is inactive."
                )
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppColors.inkSoft)
                    .multilineTextAlignment(.center)

                if let errorMessage = lockController.errorMessage {
                    ErrorNotice(message: errorMessage)
                }

                if lockController.isEnabled {
                    Button {
                        Task { await lockController.unlock() }
                    } label: {
                        Label("Unlock journal", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .frame(maxWidth: 420)
        }
        .accessibilityAddTraits(.isModal)
    }
}
