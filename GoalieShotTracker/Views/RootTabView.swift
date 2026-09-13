import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \GoalieProfileEntity.name) private var goalies: [GoalieProfileEntity]

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ShotLoggerView()
                .tabItem { Label("Log Shot", systemImage: "hockey.puck.fill") }

            GameHistoryListView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.xaxis") }

            RosterView()
                .tabItem { Label("Roster", systemImage: "person.2.fill") }
        }
        .tint(Theme.iceBlue)
        .onAppear {
            HapticsManager.prepare()
            if appState.selectedGoalieID == nil {
                appState.selectedGoalieID = goalies.first?.id
            }
        }
        .onChange(of: goalies.map(\.id)) { _, ids in
            if let selected = appState.selectedGoalieID, ids.contains(selected) { return }
            appState.selectedGoalieID = ids.first
        }
    }
}
