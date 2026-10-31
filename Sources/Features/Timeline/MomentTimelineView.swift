import SwiftUI

private enum MomentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case together = "Together"
    case solo = "Solo"

    var id: String { rawValue }
    var displayName: String { AppLocalization.string(rawValue) }
}

struct MomentTimelineView: View {
    @Environment(MomentStore.self) private var store
    let onOpen: (UUID) -> Void

    @State private var searchText = ""
    @State private var filter: MomentFilter = .all

    private var results: [Moment] {
        store.moments.filter { moment in
            let matchesKind = filter == .all || moment.kind.rawValue == filter.rawValue
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Filter moments", selection: $filter) {
                    ForEach(MomentFilter.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Filters your private records by moment type")
                .disabled(!store.isStorageAvailable)

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
                        .foregroundStyle(AppColors.inkSoft)

                    if results.isEmpty {
                        EmptyStateCard(
                            title: searchText.isEmpty ? "No moments here yet" : "No matching moments",
                            message: searchText.isEmpty
                                ? "Your timeline will appear here after you save a moment."
                                : "Try another word or change the selected filter.",
                            symbol: "calendar"
                        )
                    } else {
                        LazyVStack(spacing: 9) {
                            ForEach(results) { moment in
                                Button { onOpen(moment.id) } label: {
                                    MomentRow(moment: moment)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens the private details for this moment")
                                .accessibilityIdentifier("moment.row")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 16)
            .padding(.bottom, 28)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.cream.ignoresSafeArea())
        .navigationTitle("Your moments")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Date, type, mood, or tag")
        .task { store.reload() }
    }
}
