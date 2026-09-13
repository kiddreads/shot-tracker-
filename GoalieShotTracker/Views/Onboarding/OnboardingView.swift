import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    var onFinish: () -> Void

    @State private var page = 0
    @State private var name = ""
    @State private var jerseyNumberText = ""
    @State private var catchHand: CatchHand = .left
    @State private var teamName = ""

    var body: some View {
        VStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                featuresPage.tag(1)
                profilePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(Theme.rinkBackground)
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 72))
                .foregroundStyle(Theme.iceBlue)
            Text("Goalie Shot Tracker")
                .font(.largeTitle.weight(.bold))
            Text("The most complete shot tracker built for goalies, coaches, and stat nerds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            nextButton
        }
        .padding()
    }

    private var featuresPage: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            featureRow(icon: "hand.tap.fill", title: "Log Shots in Real Time", detail: "Tap the net diagram during the game — done in one motion.")
            featureRow(icon: "chart.bar.xaxis", title: "Deep Analytics", detail: "Zone heatmaps, danger-level breakdowns, and save% trends.")
            featureRow(icon: "shield.fill", title: "Badges & Streaks", detail: "Shutouts, quality starts, and season milestones tracked automatically.")
            featureRow(icon: "icloud.fill", title: "Synced Everywhere", detail: "iCloud keeps your stats current across every device.")
            Spacer()
            nextButton
        }
        .padding(.horizontal, 32)
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.iceBlue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var profilePage: some View {
        VStack(spacing: 16) {
            Text("Create Your Goalie Profile")
                .font(.title2.weight(.bold))
                .padding(.top, 40)
            Form {
                TextField("Name", text: $name)
                TextField("Jersey Number", text: $jerseyNumberText)
                    .keyboardType(.numberPad)
                Picker("Catch Hand", selection: $catchHand) {
                    ForEach(CatchHand.allCases) { Text($0.displayName).tag($0) }
                }
                TextField("Team", text: $teamName)
            }
            .scrollContentBackground(.hidden)
            Button("Start Tracking") { finish() }
                .buttonStyle(.borderedProminent)
                .tint(Theme.iceBlue)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.bottom, 24)
        }
    }

    private var nextButton: some View {
        Button("Continue") { withAnimation { page += 1 } }
            .buttonStyle(.borderedProminent)
            .tint(Theme.iceBlue)
            .padding(.bottom, 24)
    }

    private func finish() {
        let profile = GoalieProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            jerseyNumber: Int(jerseyNumberText),
            catchHand: catchHand,
            teamName: teamName.isEmpty ? nil : teamName
        )
        let entity = GoalieProfileEntity(from: profile)
        modelContext.insert(entity)
        try? modelContext.save()
        appState.selectedGoalieID = entity.id
        onFinish()
    }
}
