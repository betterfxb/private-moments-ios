import Combine
import SwiftUI

private enum ReviewRecordFilter: Equatable {
    case favorites
    case mood(MomentMood)
    case day(Date)

    var mood: MomentMood? {
        if case .mood(let mood) = self { return mood }
        return nil
    }

    var day: Date? {
        if case .day(let date) = self { return date }
        return nil
    }

    func title(locale: Locale) -> Text {
        switch self {
        case .favorites: Text("Bookmarked moments")
        case .mood(let mood): Text(mood.displayName)
        case .day(let date): Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale)))
        }
    }
}

struct MomentReviewView: View {
    @Environment(MomentStore.self) private var store
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var recordsFocused: Bool
    @AccessibilityFocusState private var calendarFocused: Bool
    @State private var referenceDate = Date.now
    @State private var historicalDate: Date?
    @State private var period: MomentReviewPeriod = .week
    @State private var recordFilter: ReviewRecordFilter?
    @State private var showingDatePicker = false
    @State private var dateToView = Date.now
    @State private var isComparing = false
    @State private var recordJumpID = UUID()
    @State private var calendarJumpID = UUID()

    private let showsPeriodControls: Bool
    private let onOpen: (UUID) -> Void

    init(showsPeriodControls: Bool = false, onOpen: @escaping (UUID) -> Void) {
        self.showsPeriodControls = showsPeriodControls
        self.onOpen = onOpen
    }

    private var calendar: Calendar { .current }
    private var selectedDate: Date { historicalDate ?? referenceDate }
    private var currentPeriodStart: Date {
        period.interval(containing: referenceDate, calendar: calendar)?.start ?? referenceDate
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    if !store.isStorageAvailable {
                        StorageRecoveryCard(
                            message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                            onRetry: store.reload
                        )
                    } else {
                        if let errorMessage = store.errorMessage { ErrorNotice(message: errorMessage) }
                        if let review = MomentDateQuery.review(store.moments, period: period, containing: selectedDate,
                                                               calendar: calendar) {
                            reviewContent(review)
                        } else {
                            ErrorNotice(message: AppLocalization.string("Couldn't find the dates for this period."))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, AppSpacing.section)
                .padding(.bottom, 30)
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: recordJumpID) { _, _ in
                proxy.scrollTo("review.records", anchor: .top)
                recordsFocused = true
            }
            .onChange(of: calendarJumpID) { _, _ in
                proxy.scrollTo("review.monthCalendar", anchor: .top)
                calendarFocused = true
            }
        }
        .background(AppColors.homePaper.ignoresSafeArea())
        .navigationTitle(showsPeriodControls ? LocalizedStringKey("Review") : LocalizedStringKey("Week in review"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.homePaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if showsPeriodControls {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dateToView = calendar.startOfDay(for: selectedDate)
                        showingDatePicker = true
                    } label: {
                        Label("Jump to date", systemImage: "calendar.badge.clock")
                    }
                    .accessibilityIdentifier("review.jumpDate")
                    .disabled(!store.isStorageAvailable)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) { calendarSheet }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { referenceDate = .now }
            else { showingDatePicker = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            referenceDate = .now
        }
    }

    @ViewBuilder
    private func reviewContent(_ review: MomentReview) -> some View {
        overview(review)
        if showsPeriodControls, period == .month {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeading(Text("Month calendar"))
                    .accessibilityFocused($calendarFocused)
                    .id("review.monthCalendar")
                ReviewMonthCalendar(calendar: calendar, locale: locale,
                                    month: MomentMonthCalendar(review: review, calendar: calendar),
                                    selectedDay: recordFilter?.day) { date in
                    showRecords(matching: .day(date))
                }
            }
            monthHighlights(review)
        }
        if showsPeriodControls,
           let previous = MomentDateQuery.previousReview(store.moments, period: period, from: review, calendar: calendar) {
            comparison(review, previous: previous)
        }
        if review.moments.isEmpty && recordFilter == nil {
            Text(showsPeriodControls ? LocalizedStringKey("No moments in this period") : LocalizedStringKey("No moments this week"))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("weekReview.empty")
        } else {
            if !review.moments.isEmpty { feelings(review) }
            records(review)
        }
    }

    private func overview(_ review: MomentReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if showsPeriodControls {
                HStack(spacing: 8) {
                    periodButton("Week", option: .week, identifier: "review.week")
                    periodButton("Month", option: .month, identifier: "review.month")
                }
                .padding(.bottom, 10)

                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                    : AnyLayout(HStackLayout(spacing: 8))
                layout {
                    periodSummary(review).frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 4) {
                        periodArrow(period == .week ? "Previous week" : "Previous month", step: -1, enabled: true)
                            .accessibilityIdentifier("review.previous")
                        periodArrow(period == .week ? "Next week" : "Next month",
                                    step: 1, enabled: review.interval.start < currentPeriodStart)
                            .accessibilityIdentifier("review.next")
                    }
                }
            } else {
                periodSummary(review)
            }
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
                .padding(.top, 12)
                .accessibilityHidden(true)
        }
    }

    private func periodSummary(_ review: MomentReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(periodLabel(review.interval))
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("weekReview.range")
            Text(AppLocalization.momentCount(review.moments.count))
                .font(.system(.title, design: .serif).weight(.medium))
                .foregroundStyle(AppColors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("weekReview.count")
        }
    }

    private func periodButton(_ title: LocalizedStringKey, option: MomentReviewPeriod, identifier: String) -> some View {
        let isSelected = period == option
        let outline = RoundedRectangle(cornerRadius: AppRadius.control)
        return Button {
            guard period != option else { return }
            period = option
            recordFilter = nil
            isComparing = false
        } label: {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isSelected ? AppColors.accentText : AppColors.text)
                .background(isSelected ? AppColors.accentWash : Color.clear, in: outline)
                .overlay { outline.strokeBorder(isSelected ? AppColors.accentText : AppColors.separator) }
                .contentShape(outline)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func periodArrow(_ title: LocalizedStringKey, step: Int, enabled: Bool) -> some View {
        Button {
            if let date = period.date(byMoving: step, from: selectedDate, calendar: calendar) { selectDate(date) }
        } label: {
            Image(systemName: step < 0 ? "chevron.backward" : "chevron.forward")
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(enabled ? AppColors.accentText : AppColors.secondaryText)
                .opacity(enabled ? 1 : 0.5)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(title))
    }

    private func selectDate(_ date: Date) {
        historicalDate = date < currentPeriodStart ? date : nil
        recordFilter = nil
        isComparing = false
    }

    private var calendarSheet: some View {
        NavigationStack {
            ScrollView {
                Button {
                    dateToView = calendar.startOfDay(for: referenceDate)
                } label: {
                    Text("Today").frame(minHeight: 44)
                }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("review.selectToday")
                    .padding(.top)
                    .frame(maxWidth: .infinity)
                DatePicker("Jump to date", selection: $dateToView, in: ...calendar.startOfDay(for: referenceDate),
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppColors.controlTint)
                    .padding()
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("Jump to date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDatePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectDate(dateToView)
                        showingDatePicker = false
                    }
                    .accessibilityIdentifier("review.applyDate")
                }
            }
        }
    }

    private func feelings(_ review: MomentReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(Text("Feelings"))
            ForEach(review.moods) { item in
                let isSelected = recordFilter == .mood(item.mood)
                Group {
                    if showsPeriodControls {
                        Button {
                            if isSelected {
                                recordFilter = nil
                            } else {
                                showRecords(matching: .mood(item.mood))
                            }
                        } label: {
                            moodRow(item, total: review.moments.count, isSelected: isSelected)
                                .padding(.vertical, 4)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    } else {
                        moodRow(item, total: review.moments.count, isSelected: false)
                            .accessibilityElement(children: .ignore)
                    }
                }
                .accessibilityLabel(Text(item.mood.displayName))
                .accessibilityValue(Text(AppLocalization.momentCount(item.count)))
                .accessibilityIdentifier("weekReview.mood.\(item.mood.rawValue)")
            }
        }
    }

    @ViewBuilder
    private func monthHighlights(_ review: MomentReview) -> some View {
        let favoriteCount = review.favoriteCount
        let moods = review.commonMoods
        if favoriteCount > 0 || !moods.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeading(Text("Month highlights"))
                if favoriteCount > 0 {
                    highlightLink(filter: .favorites, symbol: "bookmark.fill", count: favoriteCount,
                                  identifier: "review.highlights.favorites")
                }
                if !moods.isEmpty {
                    Text("Most common feelings")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }
                ForEach(moods) { item in
                    highlightLink(filter: .mood(item.mood), symbol: "heart", count: item.count,
                                  identifier: "review.highlights.mood.\(item.mood.rawValue)")
                }
            }
        }
    }

    private func highlightLink(filter: ReviewRecordFilter, symbol: String, count: Int, identifier: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 14))
        let title = filter.title(locale: locale)
        return Button { showRecords(matching: filter) } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol).accessibilityHidden(true)
                layout {
                    title.fontWeight(.semibold)
                    Text(AppLocalization.momentCount(count)).foregroundStyle(AppColors.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward").font(.caption.weight(.semibold)).accessibilityHidden(true)
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(AppColors.journalAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(AppColors.journalNote, in: RoundedRectangle(cornerRadius: AppRadius.control))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(Text(AppLocalization.momentCount(count)))
        .accessibilityAddTraits(recordFilter == filter ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func showRecords(matching filter: ReviewRecordFilter?) {
        recordFilter = filter
        recordJumpID = UUID()
    }

    private func comparison(_ current: MomentReview, previous: MomentReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { isComparing.toggle() } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Compare with previous period")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: isComparing ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.accentText)
            .accessibilityValue(isComparing ? Text("Expanded") : Text("Collapsed"))
            .accessibilityIdentifier("review.compare")

            if isComparing {
                comparisonPeriod(current, isPrevious: false)
                Rectangle().fill(AppColors.journalRule).frame(height: 1).accessibilityHidden(true)
                comparisonPeriod(previous, isPrevious: true)
            }
        }
    }

    private func comparisonPeriod(_ review: MomentReview, isPrevious: Bool) -> some View {
        let dayCount = review.dayCount(calendar: calendar)
        let commonMoods = review.commonMoods
        let scope = isPrevious ? "previous" : "selected"
        return VStack(alignment: .leading, spacing: 8) {
            Text(isPrevious ? LocalizedStringKey("Previous period") : LocalizedStringKey("Selected period"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)
                .accessibilityAddTraits(.isHeader)
            Text(periodLabel(review.interval))
                .font(.system(.headline, design: .serif))
                .foregroundStyle(AppColors.text)
                .fixedSize(horizontal: false, vertical: true)
            comparisonLink(review, title: AppLocalization.momentCount(review.moments.count),
                           value: dayCount == 1 ? AppLocalization.string("1 day with entries")
                               : AppLocalization.format("%lld days with entries", dayCount))
                .accessibilityIdentifier("review.\(scope).records")
            if !commonMoods.isEmpty {
                Text("Most common feelings")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
                ForEach(commonMoods) { item in
                    comparisonLink(review, title: item.mood.displayName,
                                   value: AppLocalization.momentCount(item.count), mood: item.mood)
                        .accessibilityIdentifier("review.comparisonMood.\(scope).\(item.mood.rawValue)")
                }
            }
        }
    }

    private func comparisonLink(_ review: MomentReview, title: String, value: String, mood: MomentMood? = nil) -> some View {
        Button {
            selectDate(review.interval.start)
            showRecords(matching: mood.map(ReviewRecordFilter.mood))
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.text)
                    Text(value)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.accentText)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }

    private func moodRow(_ item: MomentReview.MoodCount, total: Int, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.mood.displayName)
                    .foregroundStyle(isSelected ? AppColors.accentText : AppColors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text(item.count.formatted(.number.locale(locale)))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.accentText)
                if showsPeriodControls {
                    Image(systemName: isSelected ? "checkmark" : "chevron.forward")
                        .font(.system(.caption).weight(.semibold))
                        .foregroundStyle(AppColors.accentText)
                        .accessibilityHidden(true)
                }
            }
            .font(.system(.body, design: .rounded))
            GeometryReader { geometry in
                Capsule()
                    .fill(AppColors.accentText)
                    .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(total))
            }
            .frame(height: 4)
            .background(AppColors.accentWash, in: Capsule())
            .accessibilityHidden(true)
        }
    }

    private func records(_ review: MomentReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(Text("Moments"))
                .accessibilityFocused($recordsFocused)
                .id("review.records")
            if let recordFilter {
                recordFilter.title(locale: locale).foregroundStyle(AppColors.secondaryText)
                Button {
                    self.recordFilter = nil
                    if recordFilter.day != nil { calendarJumpID = UUID() }
                } label: {
                    Text(recordFilter.day == nil ? LocalizedStringKey("Show all moments") : LocalizedStringKey("Back to month calendar"))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("review.clearMood")
            }
            LazyVStack(spacing: 9) {
                if showsPeriodControls {
                    let selectedDay = recordFilter?.day
                    let groups = review.dayGroups(matching: recordFilter?.mood,
                                                  favoritesOnly: recordFilter == .favorites, calendar: calendar)
                        .filter { selectedDay == nil || $0.date == selectedDay }
                    if groups.isEmpty {
                        if selectedDay != nil {
                            Text("No moments on this day")
                                .foregroundStyle(AppColors.secondaryText)
                                .accessibilityIdentifier("review.calendar.emptyDay")
                        } else {
                            Text(recordFilter == .favorites ? LocalizedStringKey("No favorites in this month")
                                 : LocalizedStringKey("No moments match this feeling"))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    ForEach(groups) { group in
                        if selectedDay == nil {
                            let label = group.date.formatted(.dateTime.month(.abbreviated).day().weekday(.abbreviated).locale(locale))
                            Text(label)
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("review.recordDay")
                        }
                        ForEach(group.moments) { record($0, includesDate: false) }
                    }
                } else {
                    ForEach(review.moments) { record($0, includesDate: true) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func record(_ moment: Moment, includesDate: Bool) -> some View {
        Button { onOpen(moment.id) } label: {
            MomentRow(moment: moment, fillsWidth: true, includesDate: includesDate)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the private details for this moment")
        .accessibilityIdentifier("weekReview.moment")
    }

    private func sectionHeading(_ title: Text) -> some View {
        title
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.text)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func periodLabel(_ interval: DateInterval) -> String {
        if period == .month {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.setLocalizedDateFormatFromTemplate("yMMMM")
            return formatter.string(from: interval.start)
        }
        let formatter = DateIntervalFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
        let withinYear = calendar.isDate(interval.start, equalTo: lastDay, toGranularity: .year)
        let inCurrentYear = calendar.isDate(interval.start, equalTo: referenceDate, toGranularity: .year)
        formatter.dateTemplate = withinYear && (!showsPeriodControls || inCurrentYear) ? "MMMd" : "yMMMd"
        return formatter.string(from: interval.start, to: lastDay)
    }
}

private struct ReviewMonthCalendar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingDayList = false

    let calendar: Calendar
    let locale: Locale
    let month: MomentMonthCalendar
    let selectedDay: Date?
    let onSelect: (Date) -> Void

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Button { showingDayList = true } label: {
                Label("Choose a day", systemImage: "calendar")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.journalAccent)
            .accessibilityIdentifier("review.calendar.chooseDay")
            .sheet(isPresented: $showingDayList) { dayList }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { showingDayList = false }
            }
        } else {
            grid
        }
    }

    private var grid: some View {
        var localizedCalendar = calendar
        localizedCalendar.locale = locale
        let weekdays = localizedCalendar.veryShortStandaloneWeekdaySymbols
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(weekdays.indices, id: \.self) { offset in
                Text(weekdays[(offset + calendar.firstWeekday - 1) % weekdays.count])
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
                    .accessibilityHidden(true)
            }
            ForEach(0..<month.firstDayOffset, id: \.self) { _ in Color.clear.accessibilityHidden(true) }
            ForEach(month.days) { day in
                dayButton(day, inList: false)
            }
        }
    }

    private var dayList: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(month.days) { day in dayButton(day, inList: true) }
                }
                .padding(AppSpacing.page)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(AppColors.homePaper.ignoresSafeArea())
            .navigationTitle("Choose a day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { showingDayList = false } label: {
                        Label("Cancel", systemImage: "xmark").labelStyle(.iconOnly)
                    }
                }
            }
        }
    }

    private func dayButton(_ day: MomentMonthCalendar.Day, inList: Bool) -> some View {
        let number = calendar.component(.day, from: day.date)
        let date = day.date.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale))
        let count = AppLocalization.momentCount(day.count)
        let isSelected = day.date == selectedDay
        return Button {
            showingDayList = false
            onSelect(day.date)
        } label: {
            if inList {
                VStack(alignment: .leading, spacing: 3) {
                    Text(date).font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Text(count).font(.system(.caption, design: .rounded)).foregroundStyle(AppColors.secondaryText)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(isSelected ? AppColors.journalSelection : Color.clear, in: RoundedRectangle(cornerRadius: AppRadius.control))
                .contentShape(Rectangle())
            } else {
                VStack(spacing: 3) {
                    Text(number.formatted(.number.locale(locale)))
                        .font(.system(.callout, design: .rounded).weight(day.count == 0 ? .regular : .semibold))
                        .monospacedDigit()
                    Circle()
                        .fill(day.count == 0 ? Color.clear : AppColors.journalAccent)
                        .frame(width: 4, height: 4)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? AppColors.journalSelection : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? AppColors.journalAccent : AppColors.text)
        .accessibilityLabel(Text(date))
        .accessibilityValue(Text(count))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("review.calendar.day.\(number)")
    }
}
