import SwiftUI

struct RecapView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(MomentStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    let durationSeconds: Int
    let startedAt: Date
    let existingMoment: Moment?
    let isManualEntry: Bool
    let onCancel: () -> Void
    let onSaved: (Moment) -> Void

    @State private var mood: MomentMood
    @State private var kind: MomentKind
    @State private var rating: Int
    @State private var selectedTags: Set<String>
    @State private var privateNote: String
    @State private var timing: MomentTimingDraft
    @State private var showingSaveError = false
    @State private var showingDiscardConfirmation = false
    @State private var showingOccurrencePicker = false
    @State private var pendingOccurrence = Date.now
    private enum InputField: Hashable { case note, minutes, seconds }
    @FocusState private var focusedField: InputField?

    private var timingValidationMessage: String? {
        do {
            try timing.validate()
            return nil
        } catch { return error.localizedDescription }
    }

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
        return timing.hasChanges
            || mood != existingMoment.mood
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

    init(durationSeconds: Int, startedAt: Date = .now, existingMoment: Moment? = nil, isManualEntry: Bool = false, onCancel: @escaping () -> Void, onSaved: @escaping (Moment) -> Void) {
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.existingMoment = existingMoment
        self.isManualEntry = isManualEntry
        self.onCancel = onCancel
        self.onSaved = onSaved
        _mood = State(initialValue: existingMoment?.mood ?? .calm)
        _kind = State(initialValue: existingMoment?.kind ?? .together)
        _rating = State(initialValue: existingMoment?.rating ?? 4)
        _selectedTags = State(initialValue: Set(existingMoment?.tags ?? ["Connected"]))
        _privateNote = State(initialValue: existingMoment?.privateNote ?? "")
        _timing = State(initialValue: MomentTimingDraft(startedAt: startedAt, durationSeconds: durationSeconds, existingMoment: existingMoment))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                headerSection
                timingSection
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
        .navigationTitle(isManualEntry ? LocalizedStringKey("Add past moment") : LocalizedStringKey("Quick recap"))
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
                Button("Done") { focusedField = nil }
                    .accessibilityIdentifier("recap.dismissKeyboard")
            }
        }
        .accessibilityAction(.escape) { requestCancel() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { showingOccurrencePicker = false }
        }
        .sheet(isPresented: $showingOccurrencePicker) {
            NavigationStack {
                ScrollView {
                    DatePicker("Occurrence date", selection: $pendingOccurrence,
                               in: ...latestSelectableDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .frame(maxWidth: 520)
                        .frame(maxWidth: .infinity)
                }
                .navigationTitle("Occurrence date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingOccurrencePicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            timing.occurredAt = pendingOccurrence
                            showingOccurrencePicker = false
                        }
                        .accessibilityIdentifier("recap.date.done")
                    }
                }
            }
        }
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
            Text(AppLocalization.format("%@ · %@", timing.occurredAt.formatted(date: .abbreviated, time: .shortened), SessionClock.durationText((try? timing.durationSeconds()) ?? durationSeconds)))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.inkSoft)
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Date and duration")
                .padding(.horizontal, timingContentInset)
            occurrenceDateControl
            startTimeControl
            if isManualEntry, let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) {
                Button("Yesterday") { timing.occurredAt = yesterday }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("recap.yesterday")
                    .padding(.horizontal, timingContentInset)
            }
            adaptiveLayout(spacing: 12).callAsFunction {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Minutes")
                    TextField("Minutes", text: $timing.minutes)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .minutes)
                        .accessibilityIdentifier("recap.minutes")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seconds")
                    TextField("Seconds", text: $timing.seconds)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .seconds)
                        .accessibilityIdentifier("recap.seconds")
                }
            }
            .textFieldStyle(.roundedBorder)
            .font(.body.monospacedDigit())
            .padding(.horizontal, timingContentInset)
            if let timingValidationMessage {
                ErrorNotice(message: timingValidationMessage)
                    .padding(.horizontal, timingContentInset)
            }
        }
        .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 0 : 16)
        .padding(.vertical, 16)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private var timingContentInset: CGFloat { dynamicTypeSize.isAccessibilitySize ? 16 : 0 }
    private var latestSelectableDate: Date { max(.now, existingMoment?.occurredAt ?? .now) }

    @ViewBuilder
    private var occurrenceDateControl: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Button {
                focusedField = nil
                pendingOccurrence = timing.occurredAt
                showingOccurrencePicker = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Occurrence date")
                    Text(timing.occurredAt.formatted(date: .long, time: .omitted))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("recap.date.open")
            .padding(.horizontal, timingContentInset)
        } else {
            DatePicker("Occurrence date", selection: $timing.occurredAt,
                       in: ...latestSelectableDate, displayedComponents: .date)
                .accessibilityIdentifier("recap.date")
        }
    }

    @ViewBuilder
    private var startTimeControl: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text("Start time")
                .padding(.horizontal, timingContentInset)
            DatePicker("Start time", selection: $timing.occurredAt,
                       in: ...latestSelectableDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, timingContentInset)
                .accessibilityIdentifier("recap.time")
        } else {
            DatePicker("Start time", selection: $timing.occurredAt,
                       in: ...latestSelectableDate, displayedComponents: .hourAndMinute)
                .accessibilityIdentifier("recap.time")
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
                .focused($focusedField, equals: .note)
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
        .disabled(noteValidationMessage != nil || timingValidationMessage != nil || !store.isStorageAvailable)
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
        focusedField = nil
        let seconds: Int
        do {
            try timing.validate()
            seconds = try timing.durationSeconds()
        } catch {
            // Validation is also visible next to the timing fields; never coerce input.
            return
        }
        let moment = Moment(
            id: existingMoment?.id ?? UUID(),
            occurredAt: timing.occurredAt,
            durationSeconds: seconds,
            mood: mood,
            kind: kind,
            rating: rating,
            tags: selectedTags.sorted(),
            privateNote: privateNote.trimmingCharacters(in: .whitespacesAndNewlines),
            approximatePlace: existingMoment?.approximatePlace
        )
        showingSaveError = !store.add(moment)
        if !showingSaveError { onSaved(moment) }
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
