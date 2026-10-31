import SwiftUI

struct TodayView: View {
    @Environment(MomentStore.self) private var store
    let onStart: () -> Void
    let onOpen: (UUID) -> Void

    private var todayLabel: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var weekSummary: [WeekdayCount] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        var countsByDay: [Date: Int] = [:]
        for moment in store.moments where interval.contains(moment.occurredAt) {
            let day = calendar.startOfDay(for: moment.occurredAt)
            countsByDay[day, default: 0] += 1
        }
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            return WeekdayCount(date: date, count: countsByDay[calendar.startOfDay(for: date), default: 0])
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                HStack {
                    PrivateBadge()
                    Spacer()
                    Text(todayLabel)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(AppColors.inkSoft)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("A private place\nfor your moments.")
                        .font(.system(.largeTitle, design: .serif))
                        .tracking(-1.3)
                        .foregroundStyle(AppColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Keep a gentle record, at your own pace.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                }

                Button(action: onStart) {
                    HStack(spacing: 14) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 22, weight: .medium))
                        Text("Start a moment")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .background(AppColors.paper.opacity(0.2), in: Circle())
                    }
                    .padding(.horizontal, 18)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!store.isStorageAvailable)
                .accessibilityHint(
                    store.isStorageAvailable
                        ? "Starts a private session timer. Health data is optional and is not connected in this MVP."
                        : "Load your local journal before starting a session."
                )

                if !store.isStorageAvailable {
                    StorageRecoveryCard(
                        message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                        onRetry: store.reload
                    )
                }

                if store.isStorageAvailable {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Recent moments")
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(AppColors.ink)
                        Spacer()
                        Text(AppLocalization.format("%lld saved", store.moments.count))
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(AppColors.inkSoft)
                    }

                    if store.recentMoments.isEmpty {
                        EmptyStateCard(
                            title: "Nothing to look back on yet",
                            message: "When you're ready, save a moment. It stays in this app on this device.",
                            symbol: "heart"
                        )
                    } else {
                        VStack(spacing: 9) {
                            ForEach(store.recentMoments) { moment in
                                Button { onOpen(moment.id) } label: {
                                    MomentRow(moment: moment)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens the private details for this moment")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("This week")
                                .font(.system(.title3, design: .serif).weight(.semibold))
                                .foregroundStyle(AppColors.ink)
                            Spacer()
                            let weekTotal = weekSummary.reduce(0) { $0 + $1.count }
                            Text(AppLocalization.format("%lld saved", weekTotal))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(AppColors.inkSoft)
                        }

                        HStack(spacing: 2) {
                            ForEach(weekSummary) { day in
                                VStack(spacing: 7) {
                                    Text(day.count == 0 ? "·" : (day.count > 99 ? "99+" : "\(day.count)"))
                                        .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                                        .foregroundStyle(day.count == 0 ? AppColors.inkSoft : AppColors.paper)
                                        .frame(width: 34, height: 34)
                                        .background(day.count == 0 ? AppColors.cream : AppColors.terracotta, in: Circle())
                                    Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                        .font(.system(.caption2, design: .rounded).weight(.medium))
                                        .foregroundStyle(AppColors.inkSoft)
                                }
                                .frame(maxWidth: .infinity)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(day.accessibilityDescription)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))

                    HStack(spacing: 10) {
                        summaryTile(
                            value: store.averageDurationMinutes.map { AppLocalization.format("%lld min", $0) } ?? "—",
                            title: "Average"
                        )
                        summaryTile(
                            value: store.mostCommonMood?.displayName ?? "—",
                            title: "Most common mood"
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.cream.ignoresSafeArea())
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .task { store.reload() }
    }

    private func summaryTile(value: String, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(AppColors.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
    }
}

private struct WeekdayCount: Identifiable {
    let date: Date
    let count: Int

    var id: Date { date }

    var accessibilityDescription: String {
        AppLocalization.format("%@, %@", date.formatted(.dateTime.weekday(.wide)), AppLocalization.momentCount(count))
    }
}
