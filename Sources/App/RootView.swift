import SwiftData
import SwiftUI

private enum AppRoute: Hashable {
    case session
    case manual(startedAt: Date)
    case recap(startedAt: Date, durationSeconds: Int, editingID: UUID?)
    case detail(id: UUID)
}

private enum AppTab: Hashable {
    case today
    case timeline
    case settings
}

@MainActor
struct RootView: View {
    @State private var store: MomentStore
    @State private var sessionClock = SessionClock()
    @State private var todayPath: [AppRoute] = []
    @State private var timelinePath: [AppRoute] = []
    @State private var selectedTab: AppTab = .today
    @State private var selectedTodayDate: Date?
    @Environment(AppLockController.self) private var privacyLock
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSceneShielded = true

    init(modelContext: ModelContext) {
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        _store = State(initialValue: MomentStore(repository: repository))
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                navigationStack(path: $todayPath) {
                    TodayView(
                        selectedDate: $selectedTodayDate,
                        onStart: {
                            sessionClock.startFresh()
                            todayPath.append(.session)
                        },
                        onOpen: { id in todayPath.append(.detail(id: id)) },
                        onAddRecord: { date in todayPath.append(.manual(startedAt: date)) }
                    )
                }
                .tabItem { Label("Today", systemImage: "heart.text.square") }
                .tag(AppTab.today)

                navigationStack(path: $timelinePath) {
                    MomentTimelineView(onOpen: { id in timelinePath.append(.detail(id: id)) })
                }
                .tabItem { Label("Timeline", systemImage: "calendar") }
                .tag(AppTab.timeline)

                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                    .tag(AppTab.settings)
            }
            .environment(store)
            .environment(sessionClock)

            if isSceneShielded || privacyLock.isLocked {
                PrivacyLockView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .tint(AppColors.terracottaDark)
        .onAppear { isSceneShielded = scenePhase != .active }
        .onChange(of: scenePhase) { _, newPhase in
            isSceneShielded = newPhase != .active
            if newPhase != .active { privacyLock.lockForBackground() }
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
        case .detail(let id):
            MomentDetailView(
                momentID: id,
                onEdit: { moment in
                    path.wrappedValue.append(.recap(
                        startedAt: moment.occurredAt,
                        durationSeconds: moment.durationSeconds,
                        editingID: moment.id
                    ))
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

    private func pop(_ path: Binding<[AppRoute]>) {
        if !path.wrappedValue.isEmpty { path.wrappedValue.removeLast() }
    }
}
