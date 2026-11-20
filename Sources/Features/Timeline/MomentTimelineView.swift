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
    @State private var isSearchPresented = false
    @FocusState private var isSearchFocused: Bool
    @State private var searchSubmissionID = UUID()

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasActiveFilters: Bool { filter != .all || !query.isEmpty }

    private var results: [Moment] {
        #if DEBUG
        let started = TimelinePerformance.start()
        defer {
            if let started {
                TimelinePerformance.logger.notice("filter input=\(store.moments.count, privacy: .public) queryLength=\(query.count, privacy: .public) ms=\(TimelinePerformance.elapsed(since: started), privacy: .public)")
            }
        }
        #endif
        return store.moments.filter { moment in
            let matchesKind = filter == .all || moment.kind.rawValue == filter.rawValue
            guard matchesKind, !query.isEmpty else { return matchesKind }
            let searchable = [
                moment.occurredAt.formatted(date: .abbreviated, time: .shortened),
                moment.mood.rawValue,
                moment.mood.displayName,
                moment.kind.rawValue,
                moment.kind.displayName
            ] + moment.tags.flatMap { [$0, AppLocalization.localizedTag($0)] }
            return searchable.joined(separator: " ").localizedCaseInsensitiveContains(query)
        }
    }

    private var dayGroups: [MomentDayGroup] {
        let matches = results
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
                VStack(alignment: .leading, spacing: 18) {
                    if !isSearchPresented {
                        searchControls
                    }

                    if !store.isStorageAvailable {
                        StorageRecoveryCard(
                            message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                            onRetry: store.reload
                        )
                    } else {
                        if let errorMessage = store.errorMessage {
                            ErrorNotice(message: errorMessage)
                        }

                        Text(AppLocalization.momentCount(results.count))
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(AppColors.secondaryText)
                            .accessibilityIdentifier("timeline.resultCount")
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
                                searchText = ""
                                filter = .all
                                isSearchPresented = false
                            } label: {
                                Label("Clear filters", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            .buttonStyle(SecondaryActionButtonStyle())
                            .accessibilityIdentifier("timeline.clearFilters")
                        }

                        if results.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 9) {
                                ForEach(dayGroups) { group in
                                    Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundStyle(AppColors.accentText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 8)
                                        .accessibilityAddTraits(.isHeader)
                                    ForEach(group.moments) { moment in
                                        Button { onOpen(moment.id) } label: {
                                            MomentRow(moment: moment)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityHint("Opens the private details for this moment")
                                        .accessibilityIdentifier("moment.row")
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
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Your moments")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search moments")
        .modifier(TimelineSearchSubmission(focus: $isSearchFocused) {
            searchSubmissionID = UUID()
        })
        .task { store.reload() }
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
        hasActiveFilters ? "No matching moments" : "No moments here yet"
    }

    private var emptyMessage: LocalizedStringKey {
        hasActiveFilters
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
            Text("Date, type, mood, or tag")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("timeline.searchScope")
        }
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

private struct TimelineScrollTiming: ViewModifier {
    @State private var scrollStarted: TimeInterval?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), TimelinePerformance.enabled {
            content.onScrollPhaseChange { _, phase in
                if phase == .interacting, scrollStarted == nil {
                    scrollStarted = TimelinePerformance.start()
                } else if phase == .idle, let started = scrollStarted {
                    TimelinePerformance.logger.notice("scroll settledMs=\(TimelinePerformance.elapsed(since: started), privacy: .public)")
                    scrollStarted = nil
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
