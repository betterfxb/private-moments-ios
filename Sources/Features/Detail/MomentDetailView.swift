import SwiftUI

struct MomentDetailView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
    @Environment(RecapDraftStore.self) private var drafts
    let momentID: UUID
    let onEdit: (Moment) -> Void
    let onDeleted: () -> Void

    @State private var showingDeleteConfirmation = false
    @State private var showingDraftRemovalError = false

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
        .background(AppColors.homePaper.ignoresSafeArea())
        .navigationTitle("Moment details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.homePaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if let moment {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarTrailing) { toolbarFavorite(moment) }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .topBarTrailing) { toolbarEdit(moment) }
                        .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarTrailing) { toolbarFavorite(moment) }
                    ToolbarItem(placement: .topBarTrailing) { toolbarEdit(moment) }
                }
            }
        }
        .confirmationDialog(
            "Delete this moment?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete moment", role: .destructive) {
                if let draft = drafts.draft, draft.editingID == momentID, !drafts.discard(id: draft.id) {
                    showingDraftRemovalError = true
                } else if store.delete(id: momentID) {
                    onDeleted()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the entry and its unfinished edit. Any JSON backup you created remains unchanged.")
        }
        .alert("Couldn't remove draft", isPresented: $showingDraftRemovalError) {
            Button("OK", role: .cancel) { }
        }
    }

    private func toolbarEdit(_ moment: Moment) -> some View {
        detailToolbarButton("Edit reflection", symbol: "pencil") { onEdit(moment) }
            .accessibilityIdentifier("detail.editToolbar")
    }

    private func toolbarFavorite(_ moment: Moment) -> some View {
        detailToolbarButton(moment.isFavorite ? "Remove from favorites" : "Add to favorites",
                            symbol: moment.isFavorite ? "bookmark.fill" : "bookmark") {
            store.toggleFavorite(id: moment.id)
        }
        .accessibilityIdentifier("detail.favorite")
    }

    private func detailToolbarButton(_ title: LocalizedStringKey, symbol: String,
                                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .background(AppColors.accentWash, in: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(store.isStorageAvailable ? AppColors.accentText : AppColors.secondaryText)
        .disabled(!store.isStorageAvailable)
    }

    @ViewBuilder
    private func detailContent(_ moment: Moment) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                if !store.isStorageAvailable {
                    StorageRecoveryCard(
                        message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                        onRetry: store.reload
                    )
                }

                pageHeading(moment)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Private note", systemImage: "lock")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppColors.accentText)
                    Text(moment.privateNote.isEmpty ? AppLocalization.string("No note added.") : moment.privateNote)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppColors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("detail.note")
                        .privacySensitive()
                    if !moment.privateNote.isEmpty {
                        Text("Private notes are included in exported backups.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppSpacing.card)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.journalNote, in: RoundedRectangle(cornerRadius: AppRadius.control))
                .overlay { RoundedRectangle(cornerRadius: AppRadius.control).strokeBorder(AppColors.journalRule) }

                VStack(alignment: .leading, spacing: 7) {
                    Label("Tags", systemImage: "tag")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                    Text(moment.tags.isEmpty
                        ? AppLocalization.string("No tags added")
                        : moment.tags.map(AppLocalization.localizedTag).joined(separator: " · "))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppColors.text)
                        .fixedSize(horizontal: false, vertical: true)
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
                .tint(AppColors.accentText)
                .disabled(!store.isStorageAvailable)
                .accessibilityIdentifier("detail.edit")

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete this moment", systemImage: "trash")
                        .foregroundStyle(AppColors.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .tint(AppColors.destructive)
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

    private func pageHeading(_ moment: Moment) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(moment.occurredAt.formatted(date: dynamicTypeSize.isAccessibilitySize ? .abbreviated : .complete,
                                            time: .shortened))
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .accessibilityLabel(moment.occurredAt.formatted(date: .complete, time: .shortened))
            Text(moment.mood.displayName)
                .font(.system(.largeTitle, design: .serif).weight(.medium))
                .foregroundStyle(AppColors.text)
                .accessibilityAddTraits(.isHeader)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 16))
            layout {
                Text(moment.kind.displayName)
                Text(SessionClock.durationText(moment.durationSeconds)).monospacedDigit()
                Label {
                    Text(moment.rating.formatted() + "/5")
                } icon: {
                    Image(systemName: "star.fill").foregroundStyle(AppColors.accentText)
                }
                .accessibilityLabel(AppLocalization.format("%lld of 5", moment.rating))
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(AppColors.secondaryText)
            Rectangle()
                .fill(AppColors.journalRule)
                .frame(height: 1)
                .padding(.top, 8)
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
