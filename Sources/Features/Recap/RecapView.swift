import SwiftUI

struct RecapView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(MomentStore.self) private var store
    @Environment(RecapDraftStore.self) private var drafts
    @Environment(\.scenePhase) private var scenePhase
    let durationSeconds: Int
    let startedAt: Date
    let existingMoment: Moment?
    let isManualEntry: Bool
    private let isCalendarEntry: Bool
    let isQuickRecord: Bool
    let tagsOnly: Bool
    let onCancel: () -> Void
    let onSaved: (Moment) -> Void

    @State private var mood: MomentMood
    @State private var kind: MomentKind
    @State private var rating: Int
    @State private var selectedTags: Set<String>
    @State private var privateNote: String
    @State private var timing: MomentTimingDraft
    @State private var draftID: UUID
    @State private var draftWriteFailed = false
    @State private var showingDraftRemovalError = false
    @State private var showingSaveError = false
    @State private var showingDiscardConfirmation = false
    @State private var showingOccurrencePicker = false
    @State private var pendingOccurrence = Date.now
    @State private var showsQuickDetails = false
    @State private var showsTagEditor = false
    @State private var tagInput = ""
    @State private var tagMessage: String?
    private let initialReflection: ReflectionSnapshot
    private let inheritedTags: [String]
    private enum InputField: Hashable { case note, minutes, seconds, tag }
    @FocusState private var focusedField: InputField?
    @ScaledMetric(relativeTo: .body) private var noteMinimumHeight: CGFloat = 112
    private let keyboardDismissTargetSize: CGFloat = 44
    private var usesJournalPalette: Bool { isQuickRecord || tagsOnly || isCalendarEntry }
    private var actionColor: Color { usesJournalPalette ? AppColors.journalAccent : AppColors.accentText }
    private var actionBackground: Color { usesJournalPalette ? AppColors.journalSelection : AppColors.accentWash }

    private struct ReflectionSnapshot: Equatable {
        let mood: MomentMood
        let kind: MomentKind
        let rating: Int
        let tags: Set<String>
        let note: String
    }

    private var canSave: Bool {
        noteValidationMessage == nil && timingValidationMessage == nil && store.isStorageAvailable
    }

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
        // A finished timer is valuable even before the reflection is changed.
        let hasRecordedSession = existingMoment == nil && !isManualEntry
        let reflection = ReflectionSnapshot(mood: mood, kind: kind, rating: rating,
                                            tags: selectedTags, note: privateNote)
        return hasRecordedSession || timing.hasChanges || reflection != initialReflection
    }

    private var availableTags: [String] {
        let visible = MomentTags.distinct(MomentTags.builtIn + inheritedTags + selectedTags.sorted())
        // Older records can contain multiple spellings. Leave each selected
        // spelling editable until the user chooses to remove it.
        return visible + selectedTags.subtracting(visible).sorted()
    }

    init(durationSeconds: Int, startedAt: Date = .now, existingMoment: Moment? = nil,
         isManualEntry: Bool = false, isCalendarEntry: Bool = false, isQuickRecord: Bool = false, tagsOnly: Bool = false,
         repeatPreset: MomentRepeatPreset? = nil, recoveredDraft: RecapDraft? = nil,
         onCancel: @escaping () -> Void, onSaved: @escaping (Moment) -> Void) {
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.existingMoment = existingMoment
        self.isManualEntry = isManualEntry
        self.isCalendarEntry = isCalendarEntry
        self.isQuickRecord = isQuickRecord
        self.tagsOnly = tagsOnly
        self.onCancel = onCancel
        self.onSaved = onSaved
        inheritedTags = (existingMoment?.tags ?? []) + (repeatPreset?.tags ?? []) + (recoveredDraft?.tags ?? [])
        let reflection = ReflectionSnapshot(mood: existingMoment?.mood ?? .calm,
                                            kind: existingMoment?.kind ?? repeatPreset?.kind ?? .together,
                                            rating: existingMoment?.rating ?? 4,
                                            tags: Set(existingMoment?.tags ?? repeatPreset?.tags ?? (isQuickRecord ? [] : ["Connected"])),
                                            note: existingMoment?.privateNote ?? "")
        initialReflection = reflection
        _draftID = State(initialValue: recoveredDraft?.id ?? UUID())
        _showsTagEditor = State(initialValue: tagsOnly)
        _mood = State(initialValue: recoveredDraft?.mood ?? reflection.mood)
        _kind = State(initialValue: recoveredDraft?.kind ?? reflection.kind)
        _rating = State(initialValue: recoveredDraft?.rating ?? reflection.rating)
        _selectedTags = State(initialValue: recoveredDraft.map { Set($0.tags) } ?? reflection.tags)
        _privateNote = State(initialValue: recoveredDraft?.note ?? reflection.note)
        var draftTiming = MomentTimingDraft(startedAt: startedAt, durationSeconds: durationSeconds,
                                            existingMoment: existingMoment)
        if let recoveredDraft {
            draftTiming.occurredAt = recoveredDraft.occurredAt
            draftTiming.minutes = recoveredDraft.minutes
            draftTiming.seconds = recoveredDraft.seconds
        }
        _timing = State(initialValue: draftTiming)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                if tagsOnly {
                    tagsSection.modifier(JournalPanel(usesJournalPalette: true))
                } else if isQuickRecord && !showsQuickDetails {
                    quickContent
                } else {
                    headerSection
                    timingSection
                    VStack(alignment: .leading, spacing: 20) {
                        moodSection
                        Divider()
                        kindSection
                        Divider()
                        ratingSection
                    }
                    .modifier(JournalPanel(usesJournalPalette: isCalendarEntry))
                    VStack(alignment: .leading, spacing: 20) {
                        tagsSection
                        Divider()
                        noteSection
                    }
                    .modifier(JournalPanel(usesJournalPalette: isCalendarEntry))
                }
                if !tagsOnly || focusedField != .tag { saveSection }
            }
            .padding(.horizontal, AppSpacing.page)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background((usesJournalPalette ? AppColors.homePaper : AppColors.background).ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel", action: requestCancel)
                    .accessibilityIdentifier("recap.cancel")
                    .foregroundStyle(actionColor)
                    .alert("Discard changes?", isPresented: $showingDiscardConfirmation) {
                        Button("Discard", role: .destructive, action: discardAndClose)
                        Button("Edit", role: .cancel) { }
                    } message: {
                        Text("Unsaved edits will be lost.")
                    }
            }
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarTrailing) { toolbarSave }
                    .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarTrailing) { toolbarSave }
            }
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField == .tag {
                    Button { addTag(tagInput) } label: {
                        Label("Add tag", systemImage: "plus")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: keyboardDismissTargetSize, height: keyboardDismissTargetSize)
                            .background(actionBackground, in: Circle())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(actionColor)
                    .accessibilityLabel("Add tag")
                    .accessibilityIdentifier("recap.addTagKeyboard")
                }
                Spacer()
                Button { focusedField = nil } label: {
                    Label("Done", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: keyboardDismissTargetSize, height: keyboardDismissTargetSize)
                        .background(actionBackground, in: Circle())
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(actionColor)
                .accessibilityLabel("Done")
                .accessibilityIdentifier("recap.dismissKeyboard")
            }
        }
        .accessibilityAction(.escape) { requestCancel() }
        .onChange(of: draftSnapshot, initial: true) { _, snapshot in
            if hasUnsavedContent {
                draftWriteFailed = !drafts.save(snapshot)
            } else {
                draftWriteFailed = !drafts.discard(id: snapshot.id)
            }
        }
        .alert("Couldn't remove draft", isPresented: $showingDraftRemovalError) {
            Button("OK", role: .cancel) { }
        }
        .alert("Not saved", isPresented: $showingSaveError) {
            if !store.isStorageAvailable {
                Button("Reload") { store.reload() }
            }
            Button("Edit", role: .cancel) { }
        } message: {
            Text(!store.isStorageAvailable
                ? AppLocalization.string("Your draft is here. Reload, then save.")
                : (store.errorMessage ?? AppLocalization.string("Couldn't save this moment. Your existing entries are unchanged.")))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { showingOccurrencePicker = false }
        }
        .sheet(isPresented: $showingOccurrencePicker) {
            NavigationStack {
                ScrollView {
                    DatePicker("Occurrence date", selection: $pendingOccurrence,
                               in: ...latestSelectableDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(AppColors.controlTint)
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
    }

    private var navigationTitle: LocalizedStringKey {
        if tagsOnly { return "Edit tags" }
        if isQuickRecord { return "Quick record" }
        return isManualEntry ? "Add past moment" : "Quick recap"
    }

    private var quickContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                quickChoice(AppLocalization.string("Feeling"), selection: $mood) {
                    ForEach(MomentMood.allCases) { choice in Text(choice.displayName).tag(choice) }
                }
                Rectangle().fill(AppColors.journalRule).frame(height: 1).accessibilityHidden(true)
                quickChoice(AppLocalization.string("Type"), selection: $kind) {
                    ForEach(MomentKind.allCases) { choice in Text(choice.displayName).tag(choice) }
                }
            }
            .modifier(JournalPanel(usesJournalPalette: true))
            Text("Now · 0 min · 4/5 rating")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("recap.quickDefaults")
            Button { showsQuickDetails = true } label: {
                Label("Add details", systemImage: "pencil")
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(actionColor)
            .accessibilityIdentifier("recap.quickDetails")
        }
    }

    private func quickChoice<Selection: Hashable, Options: View>(
        _ title: String, selection: Binding<Selection>, @ViewBuilder options: () -> Options
    ) -> some View {
        adaptiveLayout(spacing: 4).callAsFunction {
            Text(verbatim: title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.text)
                .accessibilityHidden(true)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
            Picker(title, selection: selection, content: options)
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(actionColor)
                .accessibilityLabel(Text(title))
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(existingMoment == nil ? "A moment to remember" : "Edit your reflection")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.text)
            Text(AppLocalization.format("%@ · %@", timing.occurredAt.formatted(date: .abbreviated, time: .shortened), SessionClock.durationText((try? timing.durationSeconds()) ?? durationSeconds)))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
            Text(draftWriteFailed
                ? LocalizedStringKey("Draft recovery is unavailable. Save before closing the app.")
                : LocalizedStringKey("Unfinished drafts stay on this device."))
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    private var toolbarSave: some View {
        let isReloading = !store.isStorageAvailable
        let isEnabled = isReloading || canSave
        let title = isReloading
            ? AppLocalization.string("Reload journal")
            : AppLocalization.string(existingMoment == nil ? "Save privately" : "Save changes")
        return Button {
            if isReloading { store.reload() }
            else { saveMoment() }
        } label: {
            Label(title, systemImage: isReloading ? "arrow.clockwise" : "checkmark")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .background(actionBackground, in: Circle())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? actionColor : AppColors.secondaryText)
        .disabled(!isEnabled)
        .accessibilityIdentifier(isReloading ? "recap.reloadToolbar" : "recap.saveToolbar")
        .accessibilityHint(isReloading
            ? "Reloads your journal without discarding this draft."
            : "Saves this record on this device.")
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Date and duration")
                .padding(.horizontal, timingContentInset)
            occurrenceDateControl
            startTimeControl
            if isManualEntry, !isCalendarEntry, let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) {
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
                        .modifier(JournalInput())
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seconds")
                    TextField("Seconds", text: $timing.seconds)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .seconds)
                        .accessibilityIdentifier("recap.seconds")
                        .modifier(JournalInput())
                }
            }
            .textFieldStyle(.plain)
            .font(.body.monospacedDigit())
            .padding(.horizontal, timingContentInset)
            if let timingValidationMessage {
                ErrorNotice(message: timingValidationMessage)
                    .padding(.horizontal, timingContentInset)
            }
        }
        .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 0 : 16)
        .padding(.vertical, 16)
        .background(isCalendarEntry ? AppColors.journalNote : AppColors.surface,
                    in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
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
                        SelectionPill(title: option.displayName, symbol: option.symbol, isSelected: mood == option)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(mood == option ? .isSelected : [])
                    .accessibilityIdentifier("recap.mood.\(option.rawValue)")
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
                        SelectionPill(title: option.displayName,
                                      symbol: option == .together ? "person.2" : "person",
                                      isSelected: kind == option)
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
                            .foregroundStyle(value <= rating ? AppColors.accentText : AppColors.secondaryText)
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
        let visible = availableTags
        let visibleKeys = Set(visible.map(MomentTags.key(for:)))
        let recent = Array(MomentTags.distinct(store.moments.flatMap(\.tags)).lazy
            .filter { !visibleKeys.contains(MomentTags.key(for: $0)) }.prefix(8))
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("A few tags")
            FlowTags(tags: visible, selection: $selectedTags)
            Button { showsTagEditor.toggle() } label: {
                Label("Custom tags", systemImage: showsTagEditor ? "chevron.up" : "chevron.down")
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(actionColor)
            .accessibilityValue(showsTagEditor ? Text("Expanded") : Text("Collapsed"))
            .accessibilityIdentifier("recap.customTags")
            if showsTagEditor { tagEditor(recent: recent) }
            if selectedTags.count >= MomentValidator.maximumTagCount {
                Text("A moment can have up to 20 tags.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    private func tagEditor(recent: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("New tag", text: $tagInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(minHeight: 44)
                    .focused($focusedField, equals: .tag)
                    .submitLabel(.done)
                    .onSubmit { addTag(tagInput) }
                    .onChange(of: tagInput) { _, _ in tagMessage = nil }
                    .accessibilityIdentifier("recap.newTag")
                    .privacySensitive()
                    .tint(actionColor)
                Button { addTag(tagInput) } label: {
                    if dynamicTypeSize.isAccessibilitySize {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(actionBackground, in: Circle())
                            .contentShape(Rectangle())
                    } else {
                        Label("Add tag", systemImage: "plus")
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(actionColor)
                .accessibilityLabel("Add tag")
                .accessibilityIdentifier("recap.addTag")
            }
            if !recent.isEmpty {
                Menu("Recent tags") {
                    ForEach(recent, id: \.self) { tag in
                        Button(AppLocalization.localizedTag(tag)) { addTag(tag) }
                    }
                }
                .frame(minHeight: 44, alignment: .leading)
                .tint(actionColor)
                .accessibilityIdentifier("recap.recentTags")
                .privacySensitive()
            }
            if let tagMessage {
                Text(tagMessage)
                    .font(.footnote)
                    .foregroundStyle(AppColors.destructive)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("recap.tagError")
            }
        }
    }

    private func addTag(_ input: String) {
        let identity = MomentTags.key(for: input)
        let builtIn = MomentTags.builtIn.first { MomentTags.key(for: AppLocalization.localizedTag($0)) == identity }
        let saved = MomentTags.builtIn + inheritedTags + store.moments.flatMap(\.tags)
        do {
            selectedTags = try MomentTags.adding(builtIn ?? input, to: selectedTags, stored: saved)
            tagInput = ""
            tagMessage = nil
            focusedField = nil
        } catch {
            tagMessage = error.localizedDescription
            focusedField = nil
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            adaptiveLayout(spacing: 8).callAsFunction {
                sectionTitle("Private note")
                Spacer()
                Text("Included in backups")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.accentText)
            }
            TextEditor(text: $privateNote)
                .font(.system(.body, design: .rounded))
                .focused($focusedField, equals: .note)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: min(max(noteMinimumHeight, 112), 220))
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.control).stroke(AppColors.separator, lineWidth: 1))
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
                            ? AppColors.accentText
                            : AppColors.secondaryText
                    )
                    .accessibilityLabel(AppLocalization.format("Private note, %lld of %lld characters", privateNote.count, MomentValidator.maximumNoteLength))
                    .accessibilityIdentifier("recap.noteCount")
            }
            // The native keyboard accessory floats over the trailing edge.
            // Keep metadata clear of its target without reducing text size.
            .padding(.trailing,
                focusedField != nil && horizontalSizeClass == .compact
                    ? keyboardDismissTargetSize + AppSpacing.card : 0)
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
        .buttonStyle(PrimaryActionButtonStyle(
            fill: usesJournalPalette ? AppColors.homeCoverAction : AppColors.accent,
            text: usesJournalPalette ? AppColors.homeCoverActionText : AppColors.onAccent
        ))
        .disabled(!canSave)
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
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.text)
    }

    private func adaptiveLayout(spacing: CGFloat) -> AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
    }

    private func saveMoment() {
        guard canSave else { return }
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
            id: existingMoment?.id ?? draftID,
            occurredAt: timing.occurredAt,
            durationSeconds: seconds,
            mood: mood,
            kind: kind,
            rating: rating,
            tags: selectedTags.sorted(),
            privateNote: privateNote.trimmingCharacters(in: .whitespacesAndNewlines),
            approximatePlace: existingMoment?.approximatePlace,
            favorite: existingMoment?.favorite
        )
        showingSaveError = !store.add(moment)
        if !showingSaveError {
            drafts.discard(id: draftID)
            onSaved(moment)
        }
    }

    private var draftSnapshot: RecapDraft {
        RecapDraft(id: draftID, editingID: existingMoment?.id, isManualEntry: isManualEntry,
                   startedAt: startedAt, originalDuration: durationSeconds, occurredAt: timing.occurredAt,
                   minutes: timing.minutes, seconds: timing.seconds, mood: mood, kind: kind,
                   rating: rating, tags: selectedTags.sorted(), note: privateNote)
    }

    private func discardAndClose() {
        if drafts.discard(id: draftID) { onCancel() }
        else { showingDraftRemovalError = true }
    }

    private func requestCancel() {
        if hasUnsavedContent {
            showingDiscardConfirmation = true
        } else {
            discardAndClose()
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
        let isDuplicate = !isSelected && selection.contains { MomentTags.key(for: $0) == MomentTags.key(for: tag) }
        return Button {
            if isSelected { selection.remove(tag) }
            else { selection.insert(tag) }
        } label: {
            Text(AppLocalization.localizedTag(tag))
                .font(.system(.caption, design: .rounded).weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(minHeight: 44)
                .foregroundStyle(isSelected ? AppColors.accentText : AppColors.secondaryText)
                .background(isSelected ? AppColors.accentWash.opacity(0.22) : AppColors.surface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? AppColors.accentWash : AppColors.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDuplicate || (!isSelected && selection.count >= MomentValidator.maximumTagCount))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("recap.tag.\(tag)")
    }
}
