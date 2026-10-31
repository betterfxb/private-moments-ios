import SwiftUI

struct LiveSessionView: View {
    @Environment(SessionClock.self) private var sessionClock
    @Environment(\.dismiss) private var dismiss
    let onFinish: (CompletedSession) -> Void
    @State private var hasFinished = false
    @State private var showingCancelConfirmation = false
    @ScaledMetric(relativeTo: .largeTitle) private var clockFontSize: CGFloat = 54

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Label("Private session", systemImage: "lock.fill")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.paper.opacity(0.88))
                Spacer()
                Text("On this device")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(AppColors.paper.opacity(0.68))
            }

            Spacer(minLength: 10)

            SwiftUI.TimelineView(.periodic(from: .now, by: 1)) { _ in
                VStack(spacing: 7) {
                    Text(SessionClock.clockText(sessionClock.elapsedSeconds))
                        .font(.system(size: clockFontSize, weight: .light, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.paper)
                        .contentTransition(.numericText())
                    Text(sessionClock.isPaused ? "PAUSED" : "ELAPSED")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .tracking(2)
                        .foregroundStyle(AppColors.blush)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AppLocalization.format("Session duration %@", SessionClock.clockText(sessionClock.elapsedSeconds)))
            }

            Text("Take the time you need.\nYou can finish whenever you like.")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.paper.opacity(0.78))

            Spacer(minLength: 10)

            HStack(spacing: 12) {
                Button {
                    sessionClock.togglePause()
                } label: {
                    Label(sessionClock.isPaused ? "Resume" : "Pause", systemImage: sessionClock.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.paper)

                Button {
                    hasFinished = true
                    onFinish(sessionClock.finish())
                } label: {
                    Label("Finish", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.terracotta)
                .disabled(hasFinished)
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))

            Text("Health and Watch readings are not connected in this MVP.")
                .font(.system(.caption, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.paper.opacity(0.58))
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.top, 24)
        .padding(.bottom, 22)
        .frame(maxWidth: 480, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.espresso.ignoresSafeArea())
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.espresso, for: .navigationBar)
        .navigationTitle("Live session")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { showingCancelConfirmation = true }
                    .foregroundStyle(AppColors.paper)
            }
        }
        .tint(AppColors.blush)
        .accessibilityAction(.escape) { showingCancelConfirmation = true }
        .confirmationDialog(
            "Discard this session?",
            isPresented: $showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard session", role: .destructive) {
                hasFinished = true
                _ = sessionClock.finish()
                dismiss()
            }
            Button("Keep going", role: .cancel) { }
        } message: {
            Text("This timer won't be saved to your journal.")
        }
        .onDisappear {
            if !hasFinished && sessionClock.isRunning {
                sessionClock.togglePause()
            }
        }
    }
}
