import SwiftUI

struct LiveSessionView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(SessionClock.self) private var sessionClock
    @Environment(\.dismiss) private var dismiss
    let onFinish: (CompletedSession) -> Void
    @State private var hasFinished = false
    @State private var showingCancelConfirmation = false
    @ScaledMetric(relativeTo: .largeTitle) private var clockFontSize: CGFloat = 64

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 28) {
                    adaptiveLayout {
                        Label("Private session", systemImage: "lock.fill")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppColors.onDark)
                        Spacer()
                        Text("On this device")
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                            .foregroundStyle(AppColors.onDarkSecondary)
                    }

                    Spacer(minLength: 10)

                    Image(systemName: "heart")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(AppColors.onDarkAccent)
                        .frame(width: 72, height: 72)
                        .background(AppColors.onDarkAccent.opacity(0.08), in: Circle())
                        .accessibilityHidden(true)

                    SwiftUI.TimelineView(.periodic(from: .now, by: 1)) { _ in
                        VStack(spacing: 7) {
                            Text(SessionClock.clockText(sessionClock.elapsedSeconds))
                                .font(.system(size: clockFontSize, weight: .light, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppColors.onDark)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .contentTransition(.numericText())
                            Text(sessionClock.isPaused ? "PAUSED" : "ELAPSED")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .tracking(2)
                                .foregroundStyle(AppColors.onDarkAccent)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(AppLocalization.format("Session duration %@", SessionClock.clockText(sessionClock.elapsedSeconds)))
                    }

                    Text("Take the time you need.\nYou can finish whenever you like.")
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.onDarkSecondary)

                    Spacer(minLength: 10)

                    adaptiveLayout {
                        Button {
                            sessionClock.togglePause()
                        } label: {
                            Label(sessionClock.isPaused ? "Resume" : "Pause", systemImage: sessionClock.isPaused ? "play.fill" : "pause.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.onDark)
                        .accessibilityIdentifier("session.pauseResume")

                        Button {
                            hasFinished = true
                            onFinish(sessionClock.finish())
                        } label: {
                            Label("Finish", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(AppColors.onAccent)
                        .tint(AppColors.accent)
                        .disabled(hasFinished)
                        .accessibilityIdentifier("session.finish")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))

                    Text("You can add your reflection when you finish.")
                        .font(.system(.caption, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.onDarkSecondary)
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 24)
                .padding(.bottom, 22)
                .frame(maxWidth: 480)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppColors.session.ignoresSafeArea())
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.session, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("Live session")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { showingCancelConfirmation = true }
                    .foregroundStyle(AppColors.onDark)
                    .accessibilityIdentifier("session.cancel")
            }
        }
        .tint(AppColors.accentWash)
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

    private var adaptiveLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }
}
