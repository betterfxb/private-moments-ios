import SwiftUI

struct RecapView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
    let durationSeconds: Int
    let startedAt: Date
    let existingMoment: Moment?
    let onCancel: () -> Void
    let onSaved: () -> Void

    @State private var mood: MomentMood
    @State private var kind: MomentKind
    @State private var rating: Int
    @State private var selectedTags: Set<String>
    @State private var privateNote: String
    @State private var showingSaveError = false
    @State private var showingDiscardConfirmation = false
    @FocusState private var isNoteFocused: Bool

    private var noteValidationMessage: String? {
        do {
            try MomentValidator.validatePrivateNote(privateNote)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private var hasUnsavedContent: Bool {
        guard let existingMoment else { return true }
        return mood != existingMoment.mood
            || kind != existingMoment.kind
            || rating != existingMoment.rating
            || selectedTags != Set(existingMoment.tags)
            || privateNote != existingMoment.privateNote
    }

    private var availableTags: [String] {
        var result = ["Relaxed", "Connected", "Better sleep"]
        for existingTag in existingMoment?.tags ?? [] where !result.contains(existingTag) {
            result.append(existingTag)
        }
        return result
    }

    init(durationSeconds: Int, startedAt: Date = .now, existingMoment: Moment? = nil, onCancel: @escaping () -> Void, onSaved: @escaping () -> Void) {
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.existingMoment = existingMoment
        self.onCancel = onCancel
        self.onSaved = onSaved
        _mood = State(initialValue: existingMoment?.mood ?? .calm)
        _kind = State(initialValue: existingMoment?.kind ?? .together)
        _rating = State(initialValue: existingMoment?.rating ?? 4)
        _selectedTags = State(initialValue: Set(existingMoment?.tags ?? ["Connected"]))
        _privateNote = State(initialValue: existingMoment?.privateNote ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                headerSection
                moodSection
                kindSection
                ratingSection
                tagsSection
                noteSection
                saveSection
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.cream.ignoresSafeArea())
        .navigationTitle("Quick recap")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel", action: requestCancel)
                    .accessibilityIdentifier("recap.cancel")
                    .foregroundStyle(AppColors.terracottaDark)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isNoteFocused = false }
                    .accessibilityIdentifier("recap.dismissKeyboard")
            }
        }
        .accessibilityAction(.escape) { requestCancel() }
        .confirmationDialog(
            "Discard this reflection?",
            isPresented: $showingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard reflection", role: .destructive, action: onCancel)
            Button("Keep editing", role: .cancel) { }
        } message: {
            Text("Your unsaved reflection will be lost. Saved journal entries will not change.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(existingMoment == nil ? "A moment to remember" : "Edit your reflection")
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(AppColors.ink)
            Text(AppLocalization.format("%@ · %@", startedAt.formatted(date: .abbreviated, time: .shortened), SessionClock.durationText(durationSeconds)))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.inkSoft)
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("How are you feeling?")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 9) {
                ForEach(MomentMood.allCases) { option in
                    Button {
                        mood = option
                    } label: {
                        Text(option.displayName)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(mood == option ? AppColors.onAccent : AppColors.ink)
                            .background(mood == option ? AppColors.terracotta : AppColors.paper, in: Capsule())
                            .overlay(Capsule().stroke(mood == option ? AppColors.terracotta : AppColors.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(mood == option ? .isSelected : [])
                }
            }
        }
    }

    private var kindSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("What kind of moment?")
                .accessibilityIdentifier("recap.kind.title")
            adaptiveLayout(spacing: 9).callAsFunction {
                ForEach(MomentKind.allCases) { option in
                    Button {
                        kind = option
                    } label: {
                        Text(option.displayName)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(kind == option ? AppColors.onAccent : AppColors.ink)
                            .background(kind == option ? AppColors.terracotta : AppColors.paper, in: Capsule())
                            .overlay(Capsule().stroke(kind == option ? AppColors.terracotta : AppColors.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("recap.kind.\(option.rawValue)")
                    .accessibilityAddTraits(kind == option ? .isSelected : [])
                }
            }
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Your reflection")
                .accessibilityIdentifier("recap.rating.title")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 3 : 5), spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(value <= rating ? AppColors.terracottaDark : AppColors.inkSoft)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.format("Rate %lld out of 5", value))
                    .accessibilityIdentifier("recap.rating.\(value)")
                    .accessibilityAddTraits(value == rating ? .isSelected : [])
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("A few tags")
            FlowTags(tags: availableTags, selection: $selectedTags)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            adaptiveLayout(spacing: 8).callAsFunction {
                sectionTitle("Private note")
                Spacer()
                Text("Included in backups")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.terracottaDark)
            }
            TextEditor(text: $privateNote)
                .focused($isNoteFocused)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 112)
                .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.control).stroke(AppColors.line, lineWidth: 1))
                .accessibilityLabel("Private note")
                .accessibilityIdentifier("recap.note")
                .autocorrectionDisabled()
                .privacySensitive()
            HStack {
                Spacer()
                Text(AppLocalization.format("%lld / %lld", privateNote.count, MomentValidator.maximumNoteLength))
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        noteValidationMessage != nil
                            ? AppColors.terracottaDark
                            : AppColors.inkSoft
                    )
                    .accessibilityLabel(AppLocalization.format("Private note, %lld of %lld characters", privateNote.count, MomentValidator.maximumNoteLength))
            }
            if let noteValidationMessage {
                ErrorNotice(message: noteValidationMessage)
            }
        }
    }

    @ViewBuilder
    private var saveSection: some View {
        if !store.isStorageAvailable {
            StorageRecoveryCard(
                message: store.errorMessage ?? AppLocalization.string("Couldn't load your moments. Please try again."),
                onRetry: store.reload
            )
        } else if showingSaveError, let errorMessage = store.errorMessage {
            ErrorNotice(message: errorMessage)
        }

        Button(action: saveMoment) {
            Label(existingMoment == nil ? "Save privately" : "Save changes", systemImage: "checkmark")
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(noteValidationMessage != nil || !store.isStorageAvailable)
        .accessibilityIdentifier("recap.save")
        .accessibilityHint(
            noteValidationMessage != nil
                ? "Shorten the private note to 10,000 characters and 60 KB or less to save."
                : (store.isStorageAvailable
                    ? "Saves this record on this device."
                    : "Load your journal before saving a record.")
        )
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(.title3, design: .serif).weight(.semibold))
            .foregroundStyle(AppColors.ink)
    }

    private func adaptiveLayout(spacing: CGFloat) -> AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
    }

    private func saveMoment() {
        let moment = Moment(
            id: existingMoment?.id ?? UUID(),
            occurredAt: existingMoment?.occurredAt ?? startedAt,
            durationSeconds: durationSeconds,
            mood: mood,
            kind: kind,
            rating: rating,
            tags: selectedTags.sorted(),
            privateNote: privateNote.trimmingCharacters(in: .whitespacesAndNewlines),
            approximatePlace: existingMoment?.approximatePlace
        )
        showingSaveError = !store.add(moment)
        if !showingSaveError { onSaved() }
    }

    private func requestCancel() {
        if hasUnsavedContent {
            showingDiscardConfirmation = true
        } else {
            onCancel()
        }
    }
}

private struct FlowTags: View {
    let tags: [String]
    @Binding var selection: Set<String>

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tagRow(spacing: 8)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in tagButton(tag) }
            }
        }
    }

    private func tagRow(spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(tags, id: \.self) { tag in tagButton(tag) }
        }
    }

    private func tagButton(_ tag: String) -> some View {
        let isSelected = selection.contains(tag)
        return Button {
            if isSelected { selection.remove(tag) }
            else { selection.insert(tag) }
        } label: {
            Text(AppLocalization.localizedTag(tag))
                .font(.system(.caption, design: .rounded).weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(minHeight: 44)
                .foregroundStyle(isSelected ? AppColors.terracottaDark : AppColors.inkSoft)
                .background(isSelected ? AppColors.blush.opacity(0.22) : AppColors.paper, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? AppColors.blush : AppColors.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
