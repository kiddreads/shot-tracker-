import SwiftUI
import SwiftData

struct GameHistoryListView: View {
    @Environment(AppState.self) private var appState
    @Query private var games: [GameSessionEntity]
    @Query private var shots: [ShotEventEntity]

    private var summaries: [GameSummary] {
        GoalieStatsProvider.summaries(goalieID: appState.selectedGoalieID, games: games, shots: shots)
            .sorted { $0.game.date > $1.game.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if summaries.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.arrow.circlepath",
                        title: "No Games Logged",
                        message: "Games you log will show up here with a full shot-by-shot breakdown."
                    )
                } else {
                    List(summaries) { summary in
                        NavigationLink(value: summary.id) {
                            GameSummaryRow(summary: summary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.rinkBackground)
            .navigationTitle("History")
            .navigationDestination(for: UUID.self) { gameID in
                if let game = games.first(where: { $0.id == gameID }) {
                    GameDetailView(game: game)
                }
            }
        }
    }
}
