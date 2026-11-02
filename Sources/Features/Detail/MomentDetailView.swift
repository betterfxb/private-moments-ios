import SwiftUI

struct MomentDetailView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
    let momentID: UUID
    let onEdit: (Moment) -> Void
    let onDeleted: () -> Void

    @State private var showingDeleteConfirmation = false

    private var moment: Moment? {
        store.moments.first { $0.id == momentID }
    }

    var body: some View {
        Group {
            if let moment {
                detailContent(moment)
            } else if !store.isStorageAvailable {
                ScrollView {
                    StorageRecoveryCard(
                        message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                        onRetry: store.reload
                    )
                    .padding(AppSpacing.page)
                }
            } else {
                ContentUnavailableView(
                    "Moment unavailable",
                    systemImage: "heart.slash",
                    description: Text("This entry may have been removed from this device.")
                )
            }
        }
        .background(AppColors.cream.ignoresSafeArea())
        .navigationTitle("Moment details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this moment?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete moment", role: .destructive) {
                if store.delete(id: momentID) { onDeleted() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the entry from this app's local journal. Any JSON backup you created remains unchanged.")
        }
    }

    @ViewBuilder
    private func detailContent(_ moment: Moment) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                PrivateBadge()

                if !store.isStorageAvailable {
                    StorageRecoveryCard(
                        message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                        onRetry: store.reload
                    )
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("A moment to remember")
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(AppColors.ink)
                    Text(moment.occurredAt.formatted(date: .complete, time: .shortened))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                    Text(SessionClock.durationText(moment.durationSeconds))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppColors.terracottaDark)
                }

                infoLayout {
                    infoCard(title: "Type", value: moment.kind.displayName, symbol: "circle.grid.2x2")
                    infoCard(title: "Feeling", value: moment.mood.displayName, symbol: "face.smiling")
                }
                infoCard(title: "Rating", value: AppLocalization.format("%lld of 5", moment.rating), symbol: "star.fill")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tags")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(AppColors.ink)
                    if moment.tags.isEmpty {
                        Text("No tags added")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppColors.inkSoft)
                    } else {
                        Text(moment.tags.map(AppLocalization.localizedTag).joined(separator: " · "))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppColors.inkSoft)
                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    Label("Private note", systemImage: "lock.fill")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(AppColors.terracottaDark)
                    Group {
                        if moment.privateNote.isEmpty {
                            Text("No note added.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppColors.ink)
                        } else {
                            Text(moment.privateNote)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppColors.ink)
                        }
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                        .textSelection(.enabled)
                        .accessibilityIdentifier("detail.note")
                        .privacySensitive()
                    Text("Private notes are not part of sharing in this MVP.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppColors.inkSoft)
                }

                if store.isStorageAvailable, let errorMessage = store.errorMessage {
                    ErrorNotice(message: errorMessage)
                }

                Button {
                    onEdit(moment)
                } label: {
                    Label("Edit reflection", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.terracottaDark)
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("detail.edit")

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete this moment", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.terracottaDark)
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("detail.delete")
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    private var infoLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private func infoCard(title: LocalizedStringKey, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(AppColors.terracotta)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppColors.inkSoft)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AppColors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
    }
}
