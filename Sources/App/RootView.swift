import SwiftData
import SwiftUI

private enum AppRoute: Hashable {
    case session
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
    @State private var path: [AppRoute] = []
    @State private var selectedTab: AppTab = .today
    @Environment(AppLockController.self) private var privacyLock
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSceneShielded = true

    init(modelContext: ModelContext) {
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        _store = State(initialValue: MomentStore(repository: repository))
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                TabView(selection: $selectedTab) {
                    TodayView(
                        onStart: {
                            sessionClock.startFresh()
                            path.append(.session)
                        },
                        onOpen: { id in path.append(.detail(id: id)) }
                    )
                    .tabItem { Label("Today", systemImage: "heart.text.square") }
                    .tag(AppTab.today)

                    MomentTimelineView(onOpen: { id in path.append(.detail(id: id)) })
                        .tabItem { Label("Timeline", systemImage: "calendar") }
                        .tag(AppTab.timeline)

                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                        .tag(AppTab.settings)
                }
                .tint(AppColors.terracottaDark)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .session:
                        LiveSessionView { completedSession in
                            path.append(.recap(
                                startedAt: completedSession.startedAt,
                                durationSeconds: completedSession.durationSeconds,
                                editingID: nil
                            ))
                        }
                    case .recap(let startedAt, let durationSeconds, let editingID):
                        let existingMoment = editingID.flatMap { id in store.moments.first { $0.id == id } }
                        RecapView(
                            durationSeconds: durationSeconds,
                            startedAt: startedAt,
                            existingMoment: existingMoment,
                            onCancel: {
                                if editingID != nil {
                                    if !path.isEmpty { path.removeLast() }
                                } else {
                                    selectedTab = .today
                                    path.removeAll()
                                }
                            },
                            onSaved: {
                                if editingID != nil {
                                    if !path.isEmpty { path.removeLast() }
                                } else {
                                    selectedTab = .today
                                    path.removeAll()
                                }
                            }
                        )
                    case .detail(let id):
                        MomentDetailView(
                            momentID: id,
                            onEdit: { moment in
                                path.append(.recap(
                                    startedAt: moment.occurredAt,
                                    durationSeconds: moment.durationSeconds,
                                    editingID: moment.id
                                ))
                            },
                            onDeleted: {
                                if !path.isEmpty { path.removeLast() }
                            }
                        )
                    }
                }
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
}
