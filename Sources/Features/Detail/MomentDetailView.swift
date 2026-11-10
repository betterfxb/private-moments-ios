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
        .background(AppColors.background.ignoresSafeArea())
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

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: moment.kind == .together ? "person.2.fill" : "person.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.accentText)
                            .frame(width: 52, height: 52)
                            .background(AppColors.accentWash, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("A moment to remember")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(AppColors.secondaryText)
                            Text(moment.kind.displayName)
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppColors.text)
                        }
                    }
                    Divider()
                    Text(SessionClock.durationText(moment.durationSeconds))
                        .font(.system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppColors.accentText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(moment.occurredAt.formatted(date: .complete, time: .shortened))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .modifier(JournalPanel())

                infoLayout {
                    infoCard(title: "Feeling", value: moment.mood.displayName, symbol: moment.mood.symbol)
                    infoCard(title: "Rating", value: AppLocalization.format("%lld of 5", moment.rating), symbol: "star.fill")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Tags", systemImage: "tag")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppColors.accentText)
                    Text(moment.tags.isEmpty
                        ? AppLocalization.string("No tags added")
                        : moment.tags.map(AppLocalization.localizedTag).joined(separator: " · "))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .modifier(JournalPanel())

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
                    Text("Private notes are included in exported backups.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .modifier(JournalPanel())

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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.accentText)
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
                .foregroundStyle(AppColors.accent)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AppColors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(JournalPanel())
    }
}
