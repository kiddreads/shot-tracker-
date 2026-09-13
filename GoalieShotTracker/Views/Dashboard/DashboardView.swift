import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \GoalieProfileEntity.name) private var goalies: [GoalieProfileEntity]
    @Query private var games: [GameSessionEntity]
    @Query private var shots: [ShotEventEntity]

    private var summaries: [GameSummary] {
        GoalieStatsProvider.summaries(goalieID: appState.selectedGoalieID, games: games, shots: shots)
    }

    private var selectedGoalie: GoalieProfileEntity? {
        goalies.first { $0.id == appState.selectedGoalieID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if goalies.isEmpty {
                    EmptyStateView(
                        systemImage: "person.fill.questionmark",
                        title: "No Goalie Yet",
                        message: "Add a goalie profile in the Roster tab to start tracking stats."
                    )
                } else {
                    VStack(spacing: 20) {
                        header
                        seasonGrid
                        badgesSection
                        recentGamesSection
                    }
                    .padding(.vertical)
                }
            }
            .background(Theme.rinkBackground)
            .navigationTitle("Home")
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(selectedGoalie?.name ?? "Goalie")
                .font(.title2.weight(.bold))
            if let jersey = selectedGoalie?.jerseyNumber {
                Text("#\(jersey) · \(selectedGoalie?.teamName ?? "")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var seasonGrid: some View {
        let season = StatsEngine.seasonStats(from: summaries)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTileView(title: "Games Played", value: "\(summaries.count)")
            StatTileView(
                title: "Save %",
                value: season.shotsFaced > 0 ? String(format: "%.3f", season.savePercentage) : "—",
                valueColor: Theme.savePercentageColor(season.savePercentage)
            )
            StatTileView(title: "Shots Faced", value: "\(season.shotsFaced)")
            StatTileView(title: "Goals Against", value: "\(season.goals)")
            StatTileView(title: "Shutouts", value: "\(summaries.filter(\.isShutout).count)", valueColor: Theme.saveGreen)
            StatTileView(title: "Quality Starts", value: "\(summaries.filter(\.isQualityStart).count)")
        }
        .padding(.horizontal)
    }

    private var badgesSection: some View {
        let badges = StatsEngine.badgesEarned(from: summaries).sorted { $0.title < $1.title }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Badges")
                .font(.headline)
                .padding(.horizontal)
            if badges.isEmpty {
                Text("Keep logging games to start earning badges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(badges) { BadgeChipView(badge: $0) }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Games")
                .font(.headline)
                .padding(.horizontal)
            ForEach(summaries.sorted { $0.game.date > $1.game.date }.prefix(5)) { summary in
                GameSummaryRow(summary: summary)
                    .padding(.horizontal)
            }
        }
    }
}

struct GameSummaryRow: View {
    let summary: GameSummary
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(summary.game.isHome ? "vs" : "@") \(summary.game.opponentName)")
                    .font(.subheadline.weight(.semibold))
                Text(dateFormatter.string(from: summary.game.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(summary.overall.saves)/\(summary.overall.shotsFaced)")
                    .font(.subheadline.weight(.semibold))
                Text(String(format: "%.3f", summary.overall.savePercentage))
                    .font(.caption)
                    .foregroundStyle(Theme.savePercentageColor(summary.overall.savePercentage))
            }
            if summary.isShutout {
                Image(systemName: "shield.fill")
                    .foregroundStyle(Theme.iceBlue)
            }
        }
        .cardStyle()
    }
}
