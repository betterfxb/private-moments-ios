import Combine
import SwiftUI

struct WeekReviewView: View {
    @Environment(MomentStore.self) private var store
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var referenceDate = Date.now
    let onOpen: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                if !store.isStorageAvailable {
                    StorageRecoveryCard(
                        message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                        onRetry: store.reload
                    )
                } else {
                    if let errorMessage = store.errorMessage { ErrorNotice(message: errorMessage) }
                    let calendar = Calendar.current
                    if let review = MomentDateQuery.weekReview(store.moments, containing: referenceDate, calendar: calendar) {
                        overview(review, calendar: calendar)
                        if review.moments.isEmpty {
                            Text("No moments this week")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("weekReview.empty")
                        } else {
                            feelings(review)
                            records(review.moments)
                        }
                    } else {
                        ErrorNotice(message: AppLocalization.string("Couldn't find this week's dates."))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, AppSpacing.section)
            .padding(.bottom, 30)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.homePaper.ignoresSafeArea())
        .navigationTitle("Week in review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.homePaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { referenceDate = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            referenceDate = .now
        }
    }

    private func overview(_ review: MomentWeekReview, calendar: Calendar) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(weekLabel(review.interval, calendar: calendar))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("weekReview.range")
            Text(AppLocalization.momentCount(review.moments.count))
                .font(.system(.title, design: .serif).weight(.medium))
                .foregroundStyle(AppColors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("weekReview.count")
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.top, 12)
                .accessibilityHidden(true)
        }
    }

    private func feelings(_ review: MomentWeekReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(Text("Feelings"))
            ForEach(review.moods) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(item.mood.displayName)
                            .foregroundStyle(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Text(item.count.formatted(.number.locale(locale)))
                            .monospacedDigit()
                            .foregroundStyle(AppColors.accentText)
                    }
                    .font(.system(.subheadline, design: .rounded))
                    GeometryReader { geometry in
                        Capsule()
                            .fill(AppColors.accentText)
                            .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(review.moments.count))
                    }
                    .frame(height: 4)
                    .background(AppColors.accentWash, in: Capsule())
                    .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.mood.displayName))
                .accessibilityValue(Text(AppLocalization.momentCount(item.count)))
                .accessibilityIdentifier("weekReview.mood.\(item.mood.rawValue)")
            }
        }
    }

    private func records(_ moments: [Moment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(Text("Moments"))
            LazyVStack(spacing: 9) {
                ForEach(moments) { moment in
                    Button { onOpen(moment.id) } label: { MomentRow(moment: moment, fillsWidth: true) }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens the private details for this moment")
                        .accessibilityIdentifier("weekReview.moment")
                }
            }
        }
    }

    private func sectionHeading(_ title: Text) -> some View {
        title
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.text)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func weekLabel(_ interval: DateInterval, calendar: Calendar) -> String {
        let formatter = DateIntervalFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
        let withinYear = calendar.isDate(interval.start, equalTo: lastDay, toGranularity: .year)
        formatter.dateTemplate = withinYear ? "MMMd" : "yMMMd"
        return formatter.string(from: interval.start, to: lastDay)
    }
}
