import SwiftUI

struct PrivacyInformationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                VStack(alignment: .leading, spacing: 9) {
                    Label("Stored locally", systemImage: "iphone")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.accentText)
                    Text("Your entries stay on this device")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Text("Records you create are kept in this app's local storage.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))

                infoCard(
                    title: "What is stored",
                    body: "Your journal can include dates, durations, moment type, mood, rating, tags, an optional private note, and an optional place label from an imported backup."
                )
                infoCard(
                    title: "No account or tracking",
                    body: "This version does not use an account, advertising, analytics, a health service, partner sharing, or app-run cloud sync."
                )
                infoCard(
                    title: "Device authentication",
                    body: "If you turn on App Lock, iOS checks Face ID, Touch ID, or your device passcode. The app receives the result, not biometric data."
                )
                infoCard(
                    title: "Backups",
                    body: "A JSON backup includes saved entries and private notes. This app does not encrypt the file. You choose where to save it; a file provider may store it outside this device."
                )
                infoCard(
                    title: "Deleting your entries",
                    body: "Delete an entry in its detail screen, or choose Delete all local moments in Settings. These actions do not erase exported copies."
                )
                infoCard(
                    title: "How long entries stay",
                    body: "Entries remain in the app until you delete them. Copies at export destinations are handled separately."
                )
                infoCard(
                    title: "Storage protection",
                    body: "The app requests iOS file protection and exclusion from device backups. Backup exclusion is best effort and is not guaranteed."
                )
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Privacy information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoCard(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.text)
            Text(body)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).stroke(AppColors.separator.opacity(0.8), lineWidth: 1))
    }
}
