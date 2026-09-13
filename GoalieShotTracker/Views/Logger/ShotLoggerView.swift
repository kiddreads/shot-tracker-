import SwiftUI
import SwiftData

struct ShotLoggerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var allGames: [GameSessionEntity]
    @Query(sort: \ShotEventEntity.timestamp) private var allShots: [ShotEventEntity]
    @Query(sort: \GoalieProfileEntity.name) private var goalies: [GoalieProfileEntity]

    @State private var showingStartGame = false
    @State private var pendingZone: NetZone?
    @State private var currentPeriod = 1
    @State private var lastLoggedShotID: UUID?
    @State private var undoCount = 0

    private var activeGame: GameSessionEntity? {
        guard let id = appState.activeGameID else { return nil }
        return allGames.first { $0.id == id }
    }

    private var activeShots: [ShotEventEntity] {
        guard let activeGame else { return [] }
        return allShots.filter { $0.game?.id == activeGame.id }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let activeGame {
                    liveLogger(for: activeGame)
                } else {
                    startPrompt
                }
            }
            .background(Theme.rinkBackground)
            .navigationTitle("Log Shot")
            .sheet(isPresented: $showingStartGame) {
                StartGameSheet(
                    defaultTeamName: goalies.first(where: { $0.id == appState.selectedGoalieID })?.teamName ?? "My Team",
                    preselectedGoalieID: appState.selectedGoalieID
                ) { game in
                    appState.activeGameID = game.id
                    currentPeriod = 1
                }
            }
            .sheet(item: $pendingZone) { zone in
                LogShotSheet(zone: zone) { draft in
                    logShot(zone: zone, draft: draft)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: undoCount)
    }

    private var startPrompt: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                systemImage: "sportscourt.fill",
                title: "No Active Session",
                message: "Start a game or practice to begin logging shots in real time."
            )
            Button("Start New Session") { showingStartGame = true }
                .buttonStyle(.borderedProminent)
                .tint(Theme.iceBlue)
        }
    }

    private func liveLogger(for game: GameSessionEntity) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                gameHeader(game)

                NetDiagramView(zoneStats: zoneStatsDict) { zone in
                    pendingZone = zone
                }
                .padding(.horizontal)

                runningTally

                if !activeShots.isEmpty {
                    recentShotsList
                }

                Button(role: .destructive) {
                    endGame(game)
                } label: {
                    Text("End Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func gameHeader(_ game: GameSessionEntity) -> some View {
        VStack(spacing: 8) {
            Text("\(game.isHome ? "vs" : "@") \(game.opponentName)")
                .font(.title3.weight(.semibold))
            Stepper("Period \(currentPeriod)", value: $currentPeriod, in: 1...game.periodCount)
                .frame(maxWidth: 220)
        }
        .padding(.horizontal)
    }

    private var runningTally: some View {
        let stats = StatsEngine.shotStats(for: activeShots.map(\.asCoreModel))
        return HStack(spacing: 12) {
            StatTileView(title: "Shots", value: "\(stats.shotsFaced)")
            StatTileView(title: "Saves", value: "\(stats.saves)", valueColor: Theme.saveGreen)
            StatTileView(title: "Goals", value: "\(stats.goals)", valueColor: stats.goals > 0 ? Theme.goalRed : .primary)
            StatTileView(
                title: "Save %",
                value: stats.shotsFaced > 0 ? String(format: "%.3f", stats.savePercentage) : "—",
                valueColor: Theme.savePercentageColor(stats.savePercentage)
            )
        }
        .padding(.horizontal)
    }

    private var recentShotsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Shots")
                    .font(.headline)
                Spacer()
                if let last = activeShots.last {
                    Button("Undo Last") { undo(last) }
                        .font(.caption)
                }
            }
            ForEach(activeShots.suffix(5).reversed()) { shot in
                HStack {
                    Circle()
                        .fill(shot.asCoreModel.isGoal ? Theme.goalRed : Theme.saveGreen)
                        .frame(width: 8, height: 8)
                    Text(NetZone(rawValue: shot.zoneRaw)?.displayName ?? shot.zoneRaw)
                    Spacer()
                    Text(ShotOutcome(rawValue: shot.outcomeRaw)?.displayName ?? shot.outcomeRaw)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .font(.subheadline)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }

    private var zoneStatsDict: [NetZone: ShotStats] {
        Dictionary(uniqueKeysWithValues:
            StatsEngine.zoneBreakdown(for: activeShots.map(\.asCoreModel)).map { ($0.zone, $0.stats) }
        )
    }

    private func logShot(zone: NetZone, draft: ShotDraft) {
        guard let activeGame, let goalieID = appState.selectedGoalieID ?? goalies.first?.id else { return }
        let shot = ShotEventEntity(
            goalieID: goalieID,
            period: currentPeriod,
            zoneRaw: zone.rawValue,
            shotTypeRaw: draft.shotType.rawValue,
            outcomeRaw: draft.outcome.rawValue,
            strengthStateRaw: draft.strengthState.rawValue,
            isRushOrOddMan: draft.isRushOrOddMan,
            game: activeGame
        )
        modelContext.insert(shot)
        try? modelContext.save()
        lastLoggedShotID = shot.id
    }

    private func undo(_ shot: ShotEventEntity) {
        undoCount += 1
        modelContext.delete(shot)
        try? modelContext.save()
    }

    private func endGame(_ game: GameSessionEntity) {
        appState.activeGameID = nil
    }
}
