import SwiftUI

struct TodayView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Binding var selectedDate: Date?
    let onStart: () -> Void
    let onOpen: (UUID) -> Void
    let onAddRecord: (Date) -> Void
    @State private var showingDatePicker = false
    @State private var dateToView = Date.now

    private var visibleMoments: [Moment] {
        guard let selectedDate else { return store.recentMoments }
        return MomentDateQuery.onDay(store.moments, date: selectedDate)
    }

    private var todayLabel: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
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
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Private Moments")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(AppColors.accentText)
                        .fixedSize(horizontal: false, vertical: true)
                    adaptiveLayout {
                        Text(todayLabel)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppColors.secondaryText)
                        Spacer(minLength: 0)
                        PrivateBadge()
                    }
                }

                if store.isStorageAvailable {
                    weekSelector
                }

                adaptiveLayout {
                    Button(action: onStart) {
                        Label("Start a moment", systemImage: "play.fill")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(!store.isStorageAvailable)
                    .accessibilityIdentifier("today.startMoment")
                    .accessibilityHint(store.isStorageAvailable
                        ? "Starts a private session timer"
                        : "Load your journal before starting a record.")

                    Button { onAddRecord(min(selectedDate ?? .now, .now)) } label: {
                        Label("Add past moment", systemImage: "square.and.pencil")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .disabled(!store.isStorageAvailable)
                    .accessibilityIdentifier("today.addRecord")
                    .accessibilityHint("Adds a record without starting the timer")
                }

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

                    adaptiveLayout {
                        summaryTile(
                            value: store.averageDurationMinutes.map { AppLocalization.format("%lld min", $0) } ?? "—",
                            title: "Average"
                        )
                        summaryTile(value: store.mostCommonMood?.displayName ?? "—", title: "Most common mood")
                    }
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 16)
            .padding(.bottom, 30)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { showingDatePicker = false }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dateToView = selectedDate ?? .now
                    showingDatePicker = true
                } label: { Label("View a day", systemImage: "calendar") }
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("today.chooseDate")
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                ScrollView {
                    Button("Today") { dateToView = .now }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("today.selectToday")
                        .padding(.top)
                    DatePicker("View a day", selection: $dateToView, displayedComponents: .date)
                        .datePickerStyle(.graphical)
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
        .task { store.reload() }
    }

    private var weekSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Spacer()
                Text(AppLocalization.format("%lld saved", weekSummary.reduce(0) { $0 + $1.count }))
                    .font(.system(.caption2, design: .rounded))
            }
            .foregroundStyle(AppColors.secondaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 3 : 7), spacing: 3) {
                ForEach(weekSummary) { day in
                    let selected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } == true
                    Button { selectedDate = day.date } label: {
                        VStack(spacing: 6) {
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(.caption2, design: .rounded))
                            Text(day.date.formatted(.dateTime.day()))
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

private struct WeekdayCount: Identifiable {
    let date: Date
    let count: Int

    var id: Date { date }

    var accessibilityDescription: String {
        AppLocalization.format("%@, %@", date.formatted(date: .complete, time: .omitted), AppLocalization.momentCount(count))
    }
}
