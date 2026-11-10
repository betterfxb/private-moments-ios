import SwiftUI

struct TodayView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
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
                adaptiveLayout {
                    PrivateBadge()
                    Spacer()
                    Text(todayLabel)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(AppColors.inkSoft)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your moments")
                        .font(.system(.largeTitle).weight(.bold))
                        .foregroundStyle(AppColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onStart) {
                    HStack(spacing: 14) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "waveform.path")
                                .font(.system(size: 22, weight: .medium))
                        }
                        Text("Start a moment")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 34, height: 34)
                                .background(AppColors.onAccent.opacity(0.2), in: Circle())
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("today.startMoment")
                .accessibilityHint(
                    store.isStorageAvailable
                        ? "Starts a private session timer. Health data is optional and is not connected in this MVP."
                        : "Load your local journal before starting a session."
                )

                Button { onAddRecord(min(selectedDate ?? .now, .now)) } label: {
                    Label("Add past moment", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.terracottaDark)
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("today.addRecord")
                .accessibilityHint("Adds a record without starting the timer")

                if !store.isStorageAvailable {
                    StorageRecoveryCard(
                        message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                        onRetry: store.reload
                    )
                }

                if store.isStorageAvailable {
                    adaptiveLayout {
                        if let selectedDate {
                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .foregroundStyle(AppColors.ink)
                        } else {
                            Text("Recent moments")
                                .font(.headline)
                                .foregroundStyle(AppColors.ink)
                        }
                        Spacer()
                        Text(AppLocalization.format("%lld saved", selectedDate == nil ? store.moments.count : visibleMoments.count))
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(AppColors.inkSoft)
                    }

                    if selectedDate != nil {
                        Button("Show recent moments") { selectedDate = nil }
                            .accessibilityIdentifier("today.clearDateFilter")
                            .frame(minHeight: 44)
                    }

                    if visibleMoments.isEmpty {
                        EmptyStateCard(
                            title: selectedDate == nil ? "Nothing to look back on yet" : "No moments on this day",
                            message: selectedDate == nil
                                ? "When you're ready, save a moment. It stays in this app on this device."
                                : "Choose another day or add a past moment.",
                            symbol: "heart"
                        )
                    } else {
                        VStack(spacing: 9) {
                            ForEach(visibleMoments) { moment in
                                Button { onOpen(moment.id) } label: {
                                    MomentRow(moment: moment)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens the private details for this moment")
                                .accessibilityIdentifier("moment.row")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        adaptiveLayout {
                            Text("This week")
                                .font(.system(.title3, design: .serif).weight(.semibold))
                                .foregroundStyle(AppColors.ink)
                            Spacer()
                            let weekTotal = weekSummary.reduce(0) { $0 + $1.count }
                            Text(AppLocalization.format("%lld saved", weekTotal))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(AppColors.inkSoft)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 3 : 7), spacing: 8) {
                            ForEach(weekSummary) { day in
                                Button { selectedDate = day.date } label: {
                                    VStack(spacing: 7) {
                                        Text(day.count == 0 ? "·" : (day.count > 99 ? "99+" : "\(day.count)"))
                                            .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                                            .foregroundStyle(day.count == 0 ? AppColors.inkSoft : AppColors.onAccent)
                                            .frame(minWidth: 28, minHeight: 34)
                                            .background(day.count == 0 ? AppColors.cream : AppColors.terracotta, in: Circle())
                                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                            .font(.system(.caption2, design: .rounded).weight(.medium))
                                            .foregroundStyle(AppColors.inkSoft)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(day.accessibilityDescription)
                                }
                                .buttonStyle(.plain)
                                .frame(minHeight: 44)
                                .background(selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } == true ? AppColors.blush.opacity(0.22) : .clear, in: RoundedRectangle(cornerRadius: 10))
                                .accessibilityAddTraits(selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } == true ? .isSelected : [])
                                .accessibilityIdentifier("today.weekday")
                                .accessibilityHint("Shows moments from this day")
                            }
                        }
                    }
                    .padding(16)
                    .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))

                    adaptiveLayout {
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

    private func summaryTile(value: String, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(AppColors.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
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
        AppLocalization.format("%@, %@", date.formatted(.dateTime.weekday(.wide)), AppLocalization.momentCount(count))
    }
}
