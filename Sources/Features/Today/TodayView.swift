import SwiftUI

struct TodayView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(MomentStore.self) private var store
    @Environment(RecapDraftStore.self) private var drafts
    @Environment(\.scenePhase) private var scenePhase
    @Binding var selectedDate: Date?
    let onStart: () -> Void
    let onOpen: (UUID) -> Void
    let onAddRecord: (Date) -> Void
    let onQuickRecord: () -> Void
    let onOpenWeekReview: () -> Void
    let hasPendingDraft: Bool
    let canResumeDraft: Bool
    let onResumeDraft: () -> Void
    let onDiscardDraft: () -> Void
    @State private var showingDatePicker = false
    @State private var dateToView = Date.now

    private var visibleMoments: [Moment] {
        guard let selectedDate else { return store.recentMoments }
        return MomentDateQuery.onDay(store.moments, date: selectedDate)
    }

    private var todayLabel: String {
        if dynamicTypeSize.isAccessibilitySize {
            Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        } else {
            Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
    }

    private var weekSummary: [WeekdayCount] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        var countsByDay: [Date: Int] = [:]
        for moment in store.moments where moment.occurredAt >= interval.start && moment.occurredAt < interval.end {
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
            VStack(spacing: 0) {
                cover
                journal
                    .padding(.top, -18)
            }
        }
        .background(AppColors.homePaper.ignoresSafeArea())
        .navigationTitle(dynamicTypeSize.isAccessibilitySize ? LocalizedStringKey("Today") : LocalizedStringKey(""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.homeCoverNavigation, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { showingDatePicker = false }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Quick record", action: onQuickRecord)
                .tint(AppColors.homeCoverAction)
                .disabled(!store.isStorageAvailable)
                .accessibilityHint("Saves a moment without starting the timer")
                .accessibilityIdentifier("today.quickRecord")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dateToView = selectedDate ?? .now
                    showingDatePicker = true
                } label: { Label("View a day", systemImage: "calendar") }
                .tint(AppColors.homeCoverAction)
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("today.chooseDate")
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            calendarSheet
        }
        .task { store.reload() }
    }

    private var cover: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todayLabel)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(AppColors.homeCoverSecondary)
                    Text("Private Moments")
                        .font(.system(dynamicTypeSize.isAccessibilitySize ? .title2 : .largeTitle,
                                      design: .serif).weight(.medium))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("today.brand")
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if dynamicTypeSize <= .large && verticalSizeClass != .compact && store.isStorageAvailable {
                    coverArtwork
                }
            }
            .frame(maxWidth: 380)

            VStack(spacing: 4) {
                Button(action: onStart) {
                    Text("Start a moment")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(TodayCoverActionStyle(isPrimary: true))
                .accessibilityIdentifier("today.startMoment")
                .accessibilityHint(store.isStorageAvailable
                    ? "Starts a private session timer"
                    : "Load your journal before starting a record.")

                Button { onAddRecord(min(selectedDate ?? .now, .now)) } label: {
                    Text("Add past moment")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(TodayCoverActionStyle(isPrimary: false))
                .accessibilityIdentifier("today.addRecord")
                .accessibilityHint("Adds a record without starting the timer")
            }
            .frame(maxWidth: 380)
            .disabled(!store.isStorageAvailable)
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        .foregroundStyle(AppColors.homeCoverText)
        .padding(.horizontal, AppSpacing.page)
        .padding(.top, 10)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background {
            RadialGradient(colors: [AppColors.homeCoverGlow, AppColors.homeCover],
                           center: .center, startRadius: 12, endRadius: 275)
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [AppColors.homeCoverNavigation, AppColors.homeCoverNavigation.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 48)
                }
        }
    }

    private var coverArtwork: some View {
        ZStack {
            ForEach(0..<2) { index in
                Capsule()
                    .fill(LinearGradient(
                        stops: [
                            .init(color: AppColors.homeCoverAction, location: 0),
                            .init(color: AppColors.homeCoverText.opacity(0.9), location: 0.3),
                            .init(color: AppColors.homeCoverAction.opacity(0.72), location: 0.58),
                            .init(color: AppColors.homeCoverGlow, location: 1),
                        ],
                        startPoint: index == 0 ? .leading : .topLeading,
                        endPoint: index == 0 ? .trailing : .bottomTrailing
                    ))
                    .overlay { Capsule().strokeBorder(AppColors.homeCoverText.opacity(0.16)) }
                    .frame(width: 28, height: 47)
                    .rotationEffect(.degrees(index == 0 ? -25 : 20))
                    .offset(x: index == 0 ? -11 : 10, y: index == 0 ? -2 : 2)
            }
        }
        .frame(width: 62, height: 56)
        .accessibilityHidden(true)
    }

    private var journal: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            if hasPendingDraft { draftNotice }
            if !store.isStorageAvailable {
                StorageRecoveryCard(
                    message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                    onRetry: store.reload
                )
            } else {
                if let errorMessage = store.errorMessage { ErrorNotice(message: errorMessage) }

                VStack(alignment: .leading, spacing: 12) {
                    adaptiveLayout {
                        Text(selectedDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? AppLocalization.string("Recent moments"))
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppColors.text)
                        Spacer(minLength: 0)
                        Text(AppLocalization.format("%lld saved", selectedDate == nil ? store.moments.count : visibleMoments.count))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    if selectedDate != nil {
                        Button("Show recent moments") { selectedDate = nil }
                            .font(.subheadline)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("today.clearDateFilter")
                    }
                    if visibleMoments.isEmpty {
                        EmptyStateCard(
                            title: selectedDate == nil ? "No moments here yet" : "No moments on this day",
                            message: selectedDate == nil
                                ? "Your timeline will appear here after you save a moment."
                                : "Choose another day or add a past moment.",
                            symbol: "heart"
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(visibleMoments) { moment in
                                Button { onOpen(moment.id) } label: { MomentRow(moment: moment) }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Opens the private details for this moment")
                                    .accessibilityIdentifier("moment.row")
                            }
                        }
                    }
                }

                VStack(spacing: 4) {
                    weekSelector
                    weekReviewLink
                }

                Text("All-time overview")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("today.overviewScope")
                adaptiveLayout {
                    summaryTile(
                        value: store.averageDurationMinutes.map { AppLocalization.format("%lld min", $0) } ?? "—",
                        title: "Average"
                    )
                    summaryTile(value: store.mostCommonMood?.displayName ?? "—", title: "Most common mood")
                }
                PrivateBadge()
            }
        }
        .padding(.horizontal, AppSpacing.page)
        .padding(.top, 18)
        .padding(.bottom, 30)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
                .fill(AppColors.homePaper)
        }
    }

    private var draftNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unfinished draft")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(AppColors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if canResumeDraft {
                Button(action: onResumeDraft) {
                    Text("Resume draft")
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .accessibilityIdentifier("today.resumeDraft")
            } else {
                Text("This draft can't be resumed right now.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                if drafts.readFailed {
                    Button("Reload", action: drafts.reload)
                        .frame(minHeight: 44)
                }
            }
            Button("Discard draft", role: .destructive, action: onDiscardDraft)
                .foregroundStyle(AppColors.destructive)
                .frame(minHeight: 44)
                .accessibilityIdentifier("today.discardDraft")
        }
        .modifier(JournalPanel())
    }

    private var calendarSheet: some View {
        NavigationStack {
            ScrollView {
                Button("Today") { dateToView = .now }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("today.selectToday")
                    .padding(.top)
                DatePicker("View a day", selection: $dateToView, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppColors.controlTint)
                    .padding()
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("View a day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDatePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Show day") {
                        selectedDate = dateToView
                        showingDatePicker = false
                    }
                    .accessibilityIdentifier("today.applyDate")
                }
            }
        }
    }

    @ViewBuilder
    private var weekSelector: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Menu {
                ForEach(weekSummary) { day in
                    Button { selectedDate = day.date } label: {
                        if selectedDate.map({ Calendar.current.isDate($0, inSameDayAs: day.date) }) == true {
                            Label(day.menuTitle, systemImage: "checkmark")
                        } else {
                            Text(day.menuTitle)
                        }
                    }
                    .accessibilityLabel(day.accessibilityDescription)
                    .accessibilityAddTraits(selectedDate.map({ Calendar.current.isDate($0, inSameDayAs: day.date) }) == true ? .isSelected : [])
                    .accessibilityIdentifier(Calendar.current.isDateInToday(day.date) ? "today.week.current" : "today.weekday")
                }
            } label: {
                HStack {
                    Text("This week")
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down").accessibilityHidden(true)
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.accentText)
                .frame(minHeight: 44)
                .modifier(JournalPanel())
            }
            .accessibilityIdentifier("today.weekMenu")
        } else {
            weekGrid
        }
    }

    private var weekReviewLink: some View {
        Button(action: onOpenWeekReview) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Week in review").fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(.footnote).weight(.semibold))
                    .accessibilityHidden(true)
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.accentText)
            .padding(.vertical, 6)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.weekReview")
    }

    private var weekGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Spacer()
                Text(AppLocalization.format("%lld saved", weekSummary.reduce(0) { $0 + $1.count }))
                    .font(.system(.caption2, design: .rounded))
            }
            .foregroundStyle(AppColors.secondaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 3) {
                ForEach(weekSummary) { day in
                    let selected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } == true
                    Button { selectedDate = day.date } label: {
                        VStack(spacing: 6) {
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(.caption2, design: .rounded))
                            Text(Calendar.current.component(.day, from: day.date).formatted())
                                .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                            Circle()
                                .fill(day.count > 0 ? (selected ? AppColors.onAccent : AppColors.accentText) : .clear)
                                .frame(width: 4, height: 4)
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(selected ? AppColors.onAccent : AppColors.accentText)
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .background(selected ? AppColors.accent : .clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            if Calendar.current.isDateInToday(day.date) && !selected {
                                RoundedRectangle(cornerRadius: 18).strokeBorder(AppColors.separator, lineWidth: 1)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(day.accessibilityDescription)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("today.weekday")
                    .accessibilityHint("Shows moments from this day")
                }
            }
        }
    }

    private func summaryTile(value: String, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.accentText)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
    }

    private var adaptiveLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 10))
    }
}

private struct TodayCoverActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(isPrimary ? .headline : .subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(isPrimary ? AppColors.homeCoverActionText : AppColors.homeCoverText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: isPrimary ? 50 : 44)
            .background(isPrimary ? AppColors.homeCoverAction : .clear, in: Capsule())
            .contentShape(Rectangle())
            .opacity(!isEnabled ? 0.55 : (configuration.isPressed ? 0.78 : 1))
    }
}

private struct WeekdayCount: Identifiable {
    let date: Date
    let count: Int

    var id: Date { date }

    var menuTitle: String {
        date.formatted(.dateTime.weekday(.abbreviated).day())
    }

    var accessibilityDescription: String {
        AppLocalization.format("%@, %@", date.formatted(date: .complete, time: .omitted), AppLocalization.momentCount(count))
    }
}
