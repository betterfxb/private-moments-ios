import SwiftUI
import UIKit
#if DEBUG
import OSLog
#endif

private enum MomentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case together = "Together"
    case solo = "Solo"

    var id: String { rawValue }
    var displayName: String { AppLocalization.string(rawValue) }
    var kind: MomentKind? { MomentKind(rawValue: rawValue) }
}

struct MomentTimelineView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(MomentStore.self) private var store
    let onOpen: (UUID) -> Void

    @State private var searchText = ""
    @State private var filter: MomentFilter = .all
    @State private var favoritesOnly = false
    @State private var dateAndTag = TimelineDateAndTag()
    @State private var showingDateAndTag = false
    @State private var isSearchPresented = false
    @FocusState private var isSearchFocused: Bool
    @State private var searchSubmissionID = UUID()
    #if DEBUG
    @State private var searchTiming = TimelinePerformance.enabled ? TimelineSearchTiming() : nil
    #endif

    private var searchInput: Binding<String> {
        #if DEBUG
        if let searchTiming {
            return Binding(get: { searchText }, set: { value in
                if value != searchText { searchTiming.receiveInput(length: value.count) }
                searchText = value
            })
        }
        #endif
        return $searchText
    }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasActiveFilters: Bool { filter != .all || favoritesOnly || dateAndTag.isActive || !query.isEmpty }

    private var showsAccessibilitySearchScope: Bool {
        guard dynamicTypeSize.isAccessibilitySize else { return false }
        if #available(iOS 18.0, *) { return isSearchFocused }
        return isSearchPresented
    }

    private var results: [Moment] {
        #if DEBUG
        let started = TimelinePerformance.start()
        #endif
        let currentQuery = query
        let moments = store.moments
        #if DEBUG
        defer {
            if let started {
                TimelinePerformance.logger.notice("filter input=\(moments.count, privacy: .public) queryLength=\(currentQuery.count, privacy: .public) ms=\(TimelinePerformance.elapsed(since: started), privacy: .public)")
            }
        }
        #endif
        return MomentTimelineQuery(kind: filter.kind, favoritesOnly: favoritesOnly,
                                   days: dateAndTag.days, tag: dateAndTag.tag, text: currentQuery).matching(moments)
    }

    private func dayGroups(for matches: [Moment]) -> [MomentDayGroup] {
        #if DEBUG
        let started = TimelinePerformance.start()
        defer {
            if let started {
                TimelinePerformance.logger.notice("group matches=\(matches.count, privacy: .public) queryLength=\(query.count, privacy: .public) ms=\(TimelinePerformance.elapsed(since: started), privacy: .public)")
            }
        }
        #endif
        let calendar = Calendar.current
        return Dictionary(grouping: matches, by: { calendar.startOfDay(for: $0.occurredAt) })
            .map { MomentDayGroup(date: $0.key, moments: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    let putsResultsFirst = isSearchPresented || dynamicTypeSize.isAccessibilitySize
                    if !putsResultsFirst {
                        searchControls
                    }

                    if !store.isStorageAvailable {
                        StorageRecoveryCard(
                            message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                            onRetry: store.reload
                        )
                    } else {
                        let matches = results
                        if let errorMessage = store.errorMessage {
                            ErrorNotice(message: errorMessage)
                        }

                        resultSummary(matches.count)
                            .id("timeline.results")
                        if showsAccessibilitySearchScope {
                            searchScope
                        }
                        if dateAndTag.isActive && !isSearchFocused {
                            Text(verbatim: dateAndTag.summary)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(AppColors.journalAccent)
                                .accessibilityIdentifier("timeline.dateAndTag.summary")
                        }

                        if putsResultsFirst {
                            searchControls
                        }

                        if matches.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(dayGroups(for: matches)) { group in
                                    Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(.subheadline, design: .serif).weight(.medium))
                                        .foregroundStyle(AppColors.secondaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 12)
                                        .padding(.bottom, 8)
                                        .accessibilityAddTraits(.isHeader)
                                    ForEach(group.moments) { moment in
                                        Button { onOpen(moment.id) } label: {
                                            TimelineEntry(moment: moment)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityHint("Opens the private details for this moment")
                                        .accessibilityIdentifier("moment.row")
                                        #if DEBUG
                                        .modifier(TimelineSearchLayoutTiming(
                                            timing: matches.count == 1 ? searchTiming : nil,
                                            sequence: searchTiming?.pendingSequence,
                                            results: matches.count, element: .row
                                        ))
                                        #endif
                                    }
                                }
                            }
                            .id("timeline.resultsBody")
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            #if DEBUG
            .modifier(TimelineScrollTiming())
            #endif
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: isSearchPresented) { _, presented in
                if presented, store.isStorageAvailable {
                    proxy.scrollTo("timeline.results", anchor: .top)
                }
            }
            .onChange(of: isSearchFocused) { _, focused in
                if focused, store.isStorageAvailable {
                    proxy.scrollTo("timeline.results", anchor: .top)
                }
            }
            .onChange(of: searchSubmissionID) { _, _ in
                // Submission ends typing. Reveal the explanation or record
                // list, with filter/reset controls still available above it.
                proxy.scrollTo(results.isEmpty ? "timeline.emptyState" : "timeline.resultsBody", anchor: .top)
            }
        }
        .background(AppColors.homePaper.ignoresSafeArea())
        .navigationTitle("Your moments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.homePaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingDateAndTag = true } label: {
                    Label("Dates and tags", systemImage: dateAndTag.isActive
                          ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .tint(AppColors.journalAccent)
                .accessibilityValue(Text(verbatim: dateAndTag.summary))
                .accessibilityAddTraits(dateAndTag.isActive ? .isSelected : [])
                .accessibilityIdentifier("timeline.dateAndTag")
                .disabled(!store.isStorageAvailable)
            }
        }
        .sheet(isPresented: $showingDateAndTag) {
            TimelineDateAndTagSheet(selection: dateAndTag, moments: store.moments) { selection in
                dateAndTag = selection
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { showingDateAndTag = false }
        }
        .searchable(text: searchInput, isPresented: $isSearchPresented, prompt: "Search moments")
        .modifier(TimelineSearchSubmission(focus: $isSearchFocused) {
            searchSubmissionID = UUID()
        })
        .task { store.reload() }
        #if DEBUG
        .onDisappear { searchTiming?.reset() }
        #endif
    }

    @ViewBuilder
    private func resultSummary(_ count: Int) -> some View {
        let countLabel = Text(AppLocalization.momentCount(count))
            .font(.system(.footnote, design: .rounded).weight(.medium))
            .foregroundStyle(AppColors.secondaryText)
            .accessibilityIdentifier("timeline.resultCount")
            #if DEBUG
            .modifier(TimelineSearchLayoutTiming(
                timing: searchTiming, sequence: searchTiming?.pendingSequence,
                results: count, element: .count
            ))
            #endif
        if hasActiveFilters {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    countLabel.fixedSize()
                    Spacer(minLength: 0)
                    clearButton.fixedSize()
                }
                VStack(alignment: .leading, spacing: 2) {
                    countLabel
                    clearButton
                }
            }
        } else {
            countLabel
        }
    }

    private var clearButton: some View {
        Button {
            isSearchFocused = false
            if #unavailable(iOS 18.0) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil)
            }
            #if DEBUG
            searchTiming?.reset()
            #endif
            searchText = ""
            filter = .all
            favoritesOnly = false
            dateAndTag = TimelineDateAndTag()
            isSearchPresented = false
        } label: {
            Text(dynamicTypeSize.isAccessibilitySize ? LocalizedStringKey("Clear") : LocalizedStringKey("Clear filters"))
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .padding(.horizontal, 6)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .tint(AppColors.journalAccent)
        .accessibilityLabel("Clear filters")
        .accessibilityIdentifier("timeline.clearFilters")
    }

    @ViewBuilder
    private var emptyState: some View {
        if isSearchPresented {
            // Give results priority over decorative artwork while typing.
            VStack(alignment: .leading, spacing: 8) {
                Text(emptyTitle)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.text)
                    .accessibilityIdentifier("timeline.emptyTitle")
                Text(emptyMessage)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
                    .accessibilityIdentifier("timeline.emptyMessage")
            }
            .fixedSize(horizontal: false, vertical: true)
            .id("timeline.emptyState")
        } else {
            EmptyStateCard(title: emptyTitle, message: emptyMessage, symbol: "calendar")
                .id("timeline.emptyState")
        }
    }

    private var emptyTitle: LocalizedStringKey {
        if favoritesOnly, filter == .all, query.isEmpty, !dateAndTag.isActive { return "No favorites yet" }
        return hasActiveFilters ? "No matching moments" : "No moments here yet"
    }

    private var emptyMessage: LocalizedStringKey {
        if favoritesOnly, filter == .all, query.isEmpty, !dateAndTag.isActive { return "Bookmark a moment from its details to find it here." }
        return hasActiveFilters
            ? "Try another word or change the selected filter."
            : "Your timeline will appear here after you save a moment."
    }

    @ViewBuilder
    private var searchControls: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                filterPicker.pickerStyle(.menu)
                    .frame(minHeight: 44)
                Spacer(minLength: 0)
                favoritesButton
            }
            .tint(AppColors.journalAccent)
        } else {
            filterPicker.pickerStyle(.segmented)

            if store.isStorageAvailable {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        searchScope.fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 0)
                        favoritesButton.fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        searchScope
                        favoritesButton
                    }
                }
            }
        }
    }

    private var searchScope: some View {
        Text("Date, type, mood, or tag")
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(AppColors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("timeline.searchScope")
    }

    private var favoritesButton: some View {
        Button { favoritesOnly.toggle() } label: {
            let symbol = favoritesOnly ? "bookmark.fill" : "bookmark"
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol).font(.system(size: 19, weight: .semibold))
                        .frame(minWidth: 24)
                } else {
                    Label("Favorites only", systemImage: symbol)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                }
            }
                .foregroundStyle(favoritesOnly ? AppColors.journalAccent : AppColors.secondaryText)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(favoritesOnly ? AppColors.journalSelection : Color.clear, in: Capsule())
                .overlay { Capsule().strokeBorder(favoritesOnly ? Color.clear : AppColors.journalRule) }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Favorites only")
        .accessibilityAddTraits(favoritesOnly ? .isSelected : [])
        .accessibilityIdentifier("timeline.favorites")
    }

    private var filterPicker: some View {
        Picker("Filter moments", selection: $filter) {
            ForEach(MomentFilter.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .accessibilityHint("Filters your private records by moment type")
        .disabled(!store.isStorageAvailable)
        .accessibilityIdentifier("timeline.filter")
    }
}

private struct TimelineDateAndTag {
    var days: MomentDayRange?
    var tag: String?

    var isActive: Bool { days != nil || tag != nil }

    var summary: String {
        let dateSummary = days.map { range in
            let start = range.start.formatted(date: .abbreviated, time: .omitted)
            if Calendar.current.isDate(range.start, inSameDayAs: range.end) { return start }
            let end = range.end.formatted(date: .abbreviated, time: .omitted)
            return AppLocalization.format("%@ – %@", start, end)
        }
        return [dateSummary, tag.map(AppLocalization.localizedTag)].compactMap { $0 }.joined(separator: " · ")
    }
}

private struct TimelineDateAndTagSheet: View {
    private enum DateBound: String, Identifiable {
        case start, end

        var id: Self { self }
        var title: LocalizedStringKey { self == .start ? "Start date" : "End date" }
        var identifier: String { "timeline.dateRange.\(rawValue)" }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var dateRangeEnabled: Bool
    @State private var dateRange: MomentDayRange
    @State private var selectedTag: String?
    @State private var editingDate: DateBound?
    @State private var pendingDate = Date.now
    private let tags: [String]
    private let onApply: (TimelineDateAndTag) -> Void

    init(selection: TimelineDateAndTag, moments: [Moment], onApply: @escaping (TimelineDateAndTag) -> Void) {
        let today = Calendar.current.startOfDay(for: .now)
        _dateRangeEnabled = State(initialValue: selection.days != nil)
        _dateRange = State(initialValue: selection.days ?? MomentDayRange(start: today, end: today))
        _selectedTag = State(initialValue: selection.tag)
        let tags = MomentTags.distinct([selection.tag].compactMap { $0 } + moments.flatMap(\.tags))
        self.tags = tags.sorted { AppLocalization.localizedTag($0).localizedStandardCompare(AppLocalization.localizedTag($1)) == .orderedAscending }
        self.onApply = onApply
    }

    private var validDates: Bool {
        !dateRangeEnabled || dateRange.interval(calendar: .current) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { dateRangeEnabled.toggle() } label: {
                        Label(dateRangeEnabled ? "Remove date range" : "Date range",
                              systemImage: dateRangeEnabled ? "calendar.badge.minus" : "calendar")
                            .foregroundStyle(AppColors.journalAccent)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("timeline.dateRange.enabled")
                    if dateRangeEnabled {
                        dateRow(.start, selection: $dateRange.start)
                        dateRow(.end, selection: $dateRange.end)
                        if !validDates {
                            Text("The end date must be on or after the start date.")
                                .font(.footnote)
                                .foregroundStyle(AppColors.destructive)
                        }
                    }
                }
                Section {
                    Picker("Tags", selection: $selectedTag) {
                        Text("All tags").tag(nil as String?)
                        ForEach(tags, id: \.self) { tag in
                            Text(AppLocalization.localizedTag(tag)).tag(Optional(tag))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.journalAccent)
                    .accessibilityIdentifier("timeline.tagFilter")
                }
            }
            .navigationTitle(dynamicTypeSize.isAccessibilitySize
                ? LocalizedStringKey("Filters") : LocalizedStringKey("Dates and tags"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        if dynamicTypeSize.isAccessibilitySize {
                            Label("Cancel", systemImage: "xmark").labelStyle(.iconOnly)
                        } else {
                            Text("Cancel")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onApply(TimelineDateAndTag(days: dateRangeEnabled ? dateRange : nil, tag: selectedTag))
                        dismiss()
                    } label: {
                        if dynamicTypeSize.isAccessibilitySize {
                            Label("Done", systemImage: "checkmark").labelStyle(.iconOnly)
                        } else {
                            Text("Done")
                        }
                    }
                    .disabled(!validDates)
                    .accessibilityIdentifier("timeline.dateAndTag.apply")
                }
            }
        }
        .sheet(item: $editingDate) { bound in
            NavigationStack {
                ScrollView {
                    DatePicker(bound.title, selection: $pendingDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(AppColors.controlTint)
                        .padding()
                        .frame(maxWidth: 520)
                        .frame(maxWidth: .infinity)
                }
                .navigationTitle(bound.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingDate = nil }
                            .accessibilityIdentifier("timeline.dateRange.calendarCancel")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            switch bound {
                            case .start: dateRange.start = pendingDate
                            case .end: dateRange.end = pendingDate
                            }
                            editingDate = nil
                        }
                        .accessibilityIdentifier("timeline.dateRange.calendarDone")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dateRow(_ bound: DateBound, selection: Binding<Date>) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            let date = selection.wrappedValue.formatted(date: .long, time: .omitted)
            Button {
                pendingDate = selection.wrappedValue
                editingDate = bound
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(bound.title)
                        .foregroundStyle(AppColors.journalAccent)
                    Text(date)
                        .foregroundStyle(AppColors.text)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(bound.title))
            .accessibilityValue(Text(date))
            .accessibilityIdentifier(bound.identifier)
        } else {
            DatePicker(bound.title, selection: selection, displayedComponents: .date)
                .accessibilityIdentifier(bound.identifier)
        }
    }
}

private struct TimelineEntry: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let moment: Moment

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 5) {
                Text(moment.mood.displayName)
                    .font(.system(.title3, design: .serif).weight(.medium))
                    .foregroundStyle(AppColors.text)
                Text(AppLocalization.format("%@ · %@", moment.kind.displayName,
                                            moment.occurredAt.formatted(date: .omitted, time: .shortened)))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 4) {
                Text(SessionClock.durationText(moment.durationSeconds))
                    .font(.system(.subheadline, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.text)
                HStack(spacing: 6) {
                    Label {
                        Text(moment.rating.formatted() + "/5")
                    } icon: {
                        Image(systemName: "star.fill")
                    }
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                        .accessibilityLabel(AppLocalization.format("%lld of 5", moment.rating))
                    if moment.isFavorite {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(AppColors.journalAccent)
                            .accessibilityLabel("Favorite moment")
                    }
                }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.journalAccent)
                    .accessibilityHidden(true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            Rectangle().fill(AppColors.journalRule).frame(height: 1).accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
private enum TimelinePerformance {
    static let enabled = PrivateStoreFactory.uiTestStoreIdentifier() != nil
        && ProcessInfo.processInfo.arguments.contains("-pm-ui-test-performance-trace")
    static let logger = Logger(subsystem: "PrivateMoments", category: "timeline-performance")

    static func start() -> TimeInterval? { enabled ? ProcessInfo.processInfo.systemUptime : nil }

    static func elapsed(since start: TimeInterval) -> Double {
        (ProcessInfo.processInfo.systemUptime - start) * 1_000
    }
}

@MainActor
private final class TimelineSearchTiming: NSObject {
    enum Element: String { case count, row }

    private struct Input {
        let length: Int
        let started: TimeInterval
    }

    private struct ResultUpdate {
        let sequence: Int
        let input: Input
        let results: Int
        let observedAt: TimeInterval
    }

    private var sequence = 0
    private var lastResultUpdateSequence = 0
    private var input: Input?
    private var observedElements: Set<Element> = []
    private var displayLink: CADisplayLink?
    private var pendingRefreshes: [ResultUpdate] = []

    var pendingSequence: Int? { input == nil ? nil : sequence }

    func receiveInput(length: Int) {
        guard length > 0 else { reset(); return }
        sequence += 1
        observedElements.removeAll()
        let started = ProcessInfo.processInfo.systemUptime
        input = Input(length: length, started: started)
        TimelinePerformance.logger.notice("input sequence=\(self.sequence, privacy: .public) queryLength=\(length, privacy: .public) uptimeMs=\(started * 1_000, privacy: .public)")
    }

    func recordLayout(sequence: Int, results: Int, element: Element) {
        guard sequence == self.sequence, let input, observedElements.insert(element).inserted else { return }
        let now = ProcessInfo.processInfo.systemUptime
        TimelinePerformance.logger.notice("layout element=\(element.rawValue, privacy: .public) sequence=\(sequence, privacy: .public) queryLength=\(input.length, privacy: .public) results=\(results, privacy: .public) ms=\((now - input.started) * 1_000, privacy: .public)")
    }

    func recordResultUpdate(sequence: Int, results: Int) {
        guard sequence == self.sequence, sequence > lastResultUpdateSequence, let input else { return }
        lastResultUpdateSequence = sequence
        let now = ProcessInfo.processInfo.systemUptime
        TimelinePerformance.logger.notice("result-update sequence=\(sequence, privacy: .public) queryLength=\(input.length, privacy: .public) results=\(results, privacy: .public) ms=\((now - input.started) * 1_000, privacy: .public)")
        pendingRefreshes.append(ResultUpdate(sequence: sequence, input: input, results: results, observedAt: now))
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(nextRefresh(_:)))
        displayLink = link
        link.add(to: .main, forMode: .common)
    }

    @objc private func nextRefresh(_ link: CADisplayLink) {
        link.invalidate()
        displayLink = nil
        let now = ProcessInfo.processInfo.systemUptime
        // Several updates can precede one refresh callback.
        for update in pendingRefreshes {
            TimelinePerformance.logger.notice("refresh sequence=\(update.sequence, privacy: .public) queryLength=\(update.input.length, privacy: .public) results=\(update.results, privacy: .public) ms=\((now - update.input.started) * 1_000, privacy: .public) afterUpdateMs=\((now - update.observedAt) * 1_000, privacy: .public)")
        }
        pendingRefreshes.removeAll()
    }

    func reset() {
        displayLink?.invalidate()
        displayLink = nil
        input = nil
        pendingRefreshes.removeAll()
        observedElements.removeAll()
    }
}

private struct TimelineSearchLayoutTiming: ViewModifier {
    let timing: TimelineSearchTiming?
    let sequence: Int?
    let results: Int
    let element: TimelineSearchTiming.Element

    func body(content: Content) -> some View {
        if let timing {
            content.onGeometryChange(for: Int?.self) { geometry in
                geometry.size.height > 0 ? sequence : nil
            } action: { sequence in
                if let sequence { timing.recordLayout(sequence: sequence, results: results, element: element) }
            }
            .onChange(of: sequence, initial: true) { _, sequence in
                if element == .count, let sequence { timing.recordResultUpdate(sequence: sequence, results: results) }
            }
        } else {
            content
        }
    }
}

private struct TimelineScrollTiming: ViewModifier {
    @State private var scrollStarted: TimeInterval?
    @State private var decelerationStarted: TimeInterval?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), TimelinePerformance.enabled {
            content.onScrollPhaseChange { _, phase in
                if phase == .interacting, scrollStarted == nil {
                    scrollStarted = TimelinePerformance.start()
                } else if phase == .decelerating, scrollStarted != nil {
                    decelerationStarted = TimelinePerformance.start()
                } else if phase == .idle, let started = scrollStarted {
                    let deceleration = decelerationStarted.map(TimelinePerformance.elapsed(since:)) ?? 0
                    TimelinePerformance.logger.notice("scroll settledMs=\(TimelinePerformance.elapsed(since: started), privacy: .public) decelerationMs=\(deceleration, privacy: .public)")
                    scrollStarted = nil
                    decelerationStarted = nil
                }
            }
        } else {
            content
        }
    }
}
#endif

private struct MomentDayGroup: Identifiable {
    let date: Date
    let moments: [Moment]
    var id: Date { date }
}

/// Ending search presentation resets the native query. Submission should only
/// release input focus so the result and editable query remain intact.
private struct TimelineSearchSubmission: ViewModifier {
    var focus: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .searchFocused(focus)
                .onSubmit(of: .search) {
                    focus.wrappedValue = false
                    onSubmit()
                }
        } else {
            content.onSubmit(of: .search) {
                // iOS 17 has no searchFocused binding. Ask the active responder
                // to release focus without ending or clearing native search.
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil)
                onSubmit()
            }
        }
    }
}
