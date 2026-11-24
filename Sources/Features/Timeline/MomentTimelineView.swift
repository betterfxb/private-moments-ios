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
}

struct MomentTimelineView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
    let onOpen: (UUID) -> Void

    @State private var searchText = ""
    @State private var filter: MomentFilter = .all
    @State private var favoritesOnly = false
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
    private var hasActiveFilters: Bool { filter != .all || favoritesOnly || !query.isEmpty }

    private var results: [Moment] {
        #if DEBUG
        let started = TimelinePerformance.start()
        #endif
        let currentQuery = query
        let currentFilter = filter
        let moments = store.moments
        #if DEBUG
        defer {
            if let started {
                TimelinePerformance.logger.notice("filter input=\(moments.count, privacy: .public) queryLength=\(currentQuery.count, privacy: .public) ms=\(TimelinePerformance.elapsed(since: started), privacy: .public)")
            }
        }
        #endif
        guard currentFilter != .all || favoritesOnly || !currentQuery.isEmpty else { return moments }
        return moments.filter { moment in
            let matchesKind = currentFilter == .all || moment.kind.rawValue == currentFilter.rawValue
            guard matchesKind, !favoritesOnly || moment.isFavorite else { return false }
            guard !currentQuery.isEmpty else { return true }
            let searchable = [
                moment.occurredAt.formatted(date: .abbreviated, time: .shortened),
                moment.mood.rawValue,
                moment.mood.displayName,
                moment.kind.rawValue,
                moment.kind.displayName
            ] + moment.tags.flatMap { [$0, AppLocalization.localizedTag($0)] }
            return searchable.joined(separator: " ").localizedCaseInsensitiveContains(currentQuery)
        }
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
                VStack(alignment: .leading, spacing: 14) {
                    if !isSearchPresented {
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

                        Text(AppLocalization.momentCount(matches.count))
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundStyle(AppColors.secondaryText)
                            .accessibilityIdentifier("timeline.resultCount")
                            #if DEBUG
                            .modifier(TimelineSearchLayoutTiming(
                                timing: searchTiming, sequence: searchTiming?.pendingSequence,
                                results: matches.count, element: .count
                            ))
                            #endif
                            .id("timeline.results")

                        // Keep supporting controls before an unbounded result
                        // list; the live count still comes first while typing.
                        if isSearchPresented {
                            searchControls
                        }

                        if hasActiveFilters {
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
                                isSearchPresented = false
                            } label: {
                                Label("Clear filters", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            .buttonStyle(SecondaryActionButtonStyle())
                            .accessibilityIdentifier("timeline.clearFilters")
                        }

                        if matches.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(dayGroups(for: matches)) { group in
                                    Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(.headline, design: .serif).weight(.medium))
                                        .foregroundStyle(AppColors.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 16)
                                        .padding(.bottom, 9)
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
        if favoritesOnly, filter == .all, query.isEmpty { return "No favorites yet" }
        return hasActiveFilters ? "No matching moments" : "No moments here yet"
    }

    private var emptyMessage: LocalizedStringKey {
        if favoritesOnly, filter == .all, query.isEmpty { return "Bookmark a moment from its details to find it here." }
        return hasActiveFilters
            ? "Try another word or change the selected filter."
            : "Your timeline will appear here after you save a moment."
    }

    @ViewBuilder
    private var searchControls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                filterPicker.pickerStyle(.menu)
            } else {
                filterPicker.pickerStyle(.segmented)
            }
        }
        .accessibilityHint("Filters your private records by moment type")
        .disabled(!store.isStorageAvailable)

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

    private var searchScope: some View {
        Text("Date, type, mood, or tag")
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(AppColors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("timeline.searchScope")
    }

    private var favoritesButton: some View {
        Button { favoritesOnly.toggle() } label: {
            Label("Favorites only", systemImage: favoritesOnly ? "bookmark.fill" : "bookmark")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.accentText)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(favoritesOnly ? AppColors.accentWash : Color.clear, in: Capsule())
                .overlay { Capsule().strokeBorder(favoritesOnly ? AppColors.accentText : AppColors.journalRule) }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(favoritesOnly ? .isSelected : [])
        .accessibilityIdentifier("timeline.favorites")
    }

    private var filterPicker: some View {
        Picker("Filter moments", selection: $filter) {
            ForEach(MomentFilter.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .accessibilityIdentifier("timeline.filter")
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
                            .foregroundStyle(AppColors.accentText)
                            .accessibilityLabel("Favorite moment")
                    }
                }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.accentText)
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
