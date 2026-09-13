import SwiftUI
import SwiftData

@main
struct GoalieShotTrackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let container: ModelContainer
    @State private var appState = AppState()

    init() {
        container = PersistenceController.makeContainer(cloudSyncEnabled: CloudSyncSettings.isEnabled)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(onFinish: { hasCompletedOnboarding = true })
                }
            }
            .preferredColorScheme(.dark)
            .environment(appState)
        }
        .modelContainer(container)
    }
}
