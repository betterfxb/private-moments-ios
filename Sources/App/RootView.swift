import SwiftData
import SwiftUI

private enum AppRoute: Hashable {
    case session
    case manual(startedAt: Date)
    case recap(startedAt: Date, durationSeconds: Int, editingID: UUID?)
    case recoveredRecap(RecapDraft)
    case detail(id: UUID)
    case weekReview
}

private enum AppTab: Hashable {
    case today
    case timeline
    case review
    case settings
}

@MainActor
struct RootView: View {
    @State private var store: MomentStore
    @State private var sessionClock = SessionClock()
    @State private var todayPath: [AppRoute] = []
    @State private var timelinePath: [AppRoute] = []
    @State private var reviewPath: [AppRoute] = []
    @State private var selectedTab: AppTab = .today
    @State private var selectedTodayDate: Date?
    @Environment(AppLockController.self) private var privacyLock
    @Environment(RecapDraftStore.self) private var drafts
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSceneShielded = true
    @State private var showingDraftConflict = false
    @State private var showingDraftDiscard = false
    @State private var showingDraftError = false

    private var showsPrivacyShield: Bool { isSceneShielded || privacyLock.isLocked }

    private var pendingDraft: RecapDraft? {
        guard let draft = drafts.draft, !draft.alreadySaved(in: store.moments) else { return nil }
        return draft
    }

    private var canResumeDraft: Bool {
        guard store.isStorageAvailable, !drafts.readFailed, let draft = pendingDraft else { return false }
        return draft.editingID.map { id in store.moments.contains { $0.id == id } } ?? true
    }

    init(modelContext: ModelContext) {
        var saveChanges: @MainActor (ModelContext) throws -> Void = { try $0.save() }
        #if DEBUG
        if PrivateStoreFactory.uiTestSaveFailureEnabled() {
            var shouldFail = true
            saveChanges = { context in
                if shouldFail {
                    shouldFail = false
                    throw CocoaError(.fileWriteUnknown)
                }
                try context.save()
            }
        }
        #endif
        let repository = SwiftDataMomentRepository(modelContext: modelContext, saveChanges: saveChanges)
        _store = State(initialValue: MomentStore(repository: repository))
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                navigationStack(path: $todayPath) {
                    TodayView(
                        selectedDate: $selectedTodayDate,
                        onStart: {
                            startWhenDraftIsClear {
                                sessionClock.startFresh()
                                todayPath.append(.session)
                            }
                        },
                        onOpen: { id in todayPath.append(.detail(id: id)) },
                        onAddRecord: { date in
                            startWhenDraftIsClear { todayPath.append(.manual(startedAt: date)) }
                        },
                        onOpenWeekReview: { todayPath.append(.weekReview) },
                        hasPendingDraft: !showsPrivacyShield && (pendingDraft != nil || drafts.readFailed),
                        canResumeDraft: canResumeDraft,
                        onResumeDraft: resumeDraft,
                        onDiscardDraft: { showingDraftDiscard = true }
                    )
                }
                .tabItem { Label("Today", systemImage: "heart.text.square") }
                .tag(AppTab.today)

                navigationStack(path: $timelinePath) {
                    MomentTimelineView(onOpen: { id in timelinePath.append(.detail(id: id)) })
                }
                .tabItem { Label("Timeline", systemImage: "calendar") }
                .tag(AppTab.timeline)

                navigationStack(path: $reviewPath) {
                    MomentReviewView(showsPeriodControls: true) { id in
                        reviewPath.append(.detail(id: id))
                    }
                }
                .tabItem { Label("Review", systemImage: "book.closed") }
                .tag(AppTab.review)

                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                    .tag(AppTab.settings)
            }
            .environment(store)
            .environment(sessionClock)
            .accessibilityHidden(privacyLock.isLocked && !isSceneShielded)

            if showsPrivacyShield {
                PrivacyLockView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .tint(AppColors.accentText)
        .onAppear { isSceneShielded = scenePhase != .active }
        .onChange(of: scenePhase) { _, newPhase in
            isSceneShielded = newPhase != .active
            if newPhase != .active { privacyLock.lockForBackground() }
            if newPhase == .background { privacyLock.cancelAuthenticationForBackground() }
            if newPhase == .active, drafts.readFailed { drafts.reload() }
        }
        .onChange(of: showsPrivacyShield) { _, isShielded in
            if isShielded {
                showingDraftConflict = false
                showingDraftDiscard = false
                showingDraftError = false
            }
        }
        .alert("Unfinished draft", isPresented: $showingDraftConflict) {
            if canResumeDraft { Button("Resume draft", action: resumeDraft) }
            Button("Discard draft", role: .destructive, action: discardDraft)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Resume or discard the unfinished draft before starting another.")
        }
        .alert("Discard draft?", isPresented: $showingDraftDiscard) {
            Button("Discard draft", role: .destructive, action: discardDraft)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The unsaved changes will be removed from this device.")
        }
        .alert("Couldn't remove draft", isPresented: $showingDraftError) {
            Button("OK", role: .cancel) { }
        }
    }

    private func navigationStack<Content: View>(
        path: Binding<[AppRoute]>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: path) {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route, path: path)
                        .toolbar(.hidden, for: .tabBar)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute, path: Binding<[AppRoute]>) -> some View {
        switch route {
        case .manual(let startedAt):
            RecapView(
                durationSeconds: 0,
                startedAt: startedAt,
                isManualEntry: true,
                onCancel: { finishRecap(editingID: nil, path: path) },
                onSaved: { moment in
                    finishRecap(editingID: nil, path: path)
                    selectedTodayDate = moment.occurredAt
                }
            )
        case .session:
            LiveSessionView { completed in
                path.wrappedValue.append(.recap(
                    startedAt: completed.startedAt,
                    durationSeconds: completed.durationSeconds,
                    editingID: nil
                ))
            }
        case .recap(let startedAt, let durationSeconds, let editingID):
            let existing = editingID.flatMap { id in store.moments.first { $0.id == id } }
            RecapView(
                durationSeconds: durationSeconds,
                startedAt: startedAt,
                existingMoment: existing,
                onCancel: { finishRecap(editingID: editingID, path: path) },
                onSaved: { _ in finishRecap(editingID: editingID, path: path, didSave: true) }
            )
        case .recoveredRecap(let draft):
            let existing = draft.editingID.flatMap { id in store.moments.first { $0.id == id } }
            RecapView(
                durationSeconds: draft.originalDuration,
                startedAt: draft.startedAt,
                existingMoment: existing,
                isManualEntry: draft.isManualEntry,
                recoveredDraft: draft,
                onCancel: { finishRecap(editingID: draft.editingID, path: path) },
                onSaved: { moment in
                    finishRecap(editingID: draft.editingID, path: path, didSave: true)
                    if draft.isManualEntry { selectedTodayDate = moment.occurredAt }
                }
            )
        case .weekReview:
            MomentReviewView { id in path.wrappedValue.append(.detail(id: id)) }
        case .detail(let id):
            MomentDetailView(
                momentID: id,
                onEdit: { moment in
                    startWhenDraftIsClear {
                        path.wrappedValue.append(.recap(
                            startedAt: moment.occurredAt,
                            durationSeconds: moment.durationSeconds,
                            editingID: moment.id
                        ))
                    }
                },
                onDeleted: { pop(path) }
            )
        }
    }

    private func finishRecap(editingID: UUID?, path: Binding<[AppRoute]>, didSave: Bool = false) {
        if editingID != nil {
            pop(path)
        } else {
            if didSave { selectedTodayDate = nil }
            selectedTab = .today
            path.wrappedValue.removeAll()
        }
    }

    private func startWhenDraftIsClear(_ action: () -> Void) {
        if pendingDraft != nil || drafts.readFailed {
            showingDraftConflict = true
        } else if let savedDraft = drafts.draft, !drafts.discard(id: savedDraft.id) {
            showingDraftError = true
        } else {
            action()
        }
    }

    private func resumeDraft() {
        guard !showsPrivacyShield, canResumeDraft, let draft = pendingDraft else { return }
        selectedTab = .today
        todayPath = draft.editingID.map { [.detail(id: $0), .recoveredRecap(draft)] } ?? [.recoveredRecap(draft)]
    }

    private func discardDraft() {
        guard !showsPrivacyShield, pendingDraft != nil || drafts.readFailed else { return }
        showingDraftError = !drafts.discard(id: pendingDraft?.id)
    }

    private func pop(_ path: Binding<[AppRoute]>) {
        if !path.wrappedValue.isEmpty { path.wrappedValue.removeLast() }
    }
}
