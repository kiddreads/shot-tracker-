import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(AppState.self) private var appState
    @Query private var games: [GameSessionEntity]
    @Query private var shots: [ShotEventEntity]
    @State private var rangeFilter: RangeFilter = .allTime

    enum RangeFilter: String, CaseIterable, Identifiable {
        case last5, last10, allTime
        var id: String { rawValue }
        var label: String {
            switch self {
            case .last5: return "Last 5"
            case .last10: return "Last 10"
            case .allTime: return "All Time"
            }
        }
    }

    private var allSummaries: [GameSummary] {
        GoalieStatsProvider.summaries(goalieID: appState.selectedGoalieID, games: games, shots: shots)
    }

    private var filteredSummaries: [GameSummary] {
        let sorted = allSummaries.sorted { $0.game.date < $1.game.date }
        switch rangeFilter {
        case .last5: return Array(sorted.suffix(5))
        case .last10: return Array(sorted.suffix(10))
        case .allTime: return sorted
        }
    }

    private var filteredShots: [ShotEvent] {
        let gameIDs = Set(filteredSummaries.map(\.game.id))
        return shots
            .filter { shot in
                guard let goalieID = appState.selectedGoalieID else { return false }
                return shot.goalieID == goalieID && shot.game.map { gameIDs.contains($0.id) } == true
            }
            .map(\.asCoreModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Range", selection: $rangeFilter) {
                        ForEach(RangeFilter.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    section("Save % Trend") {
                        TrendChartView(points: StatsEngine.trend(from: filteredSummaries))
                    }

                    section("Zone Heatmap") {
                        ZoneHeatmapView(zoneStats: Dictionary(uniqueKeysWithValues: StatsEngine.zoneBreakdown(for: filteredShots).map { ($0.zone, $0.stats) }))
                    }

                    section("Shot Type Breakdown") {
                        ShotTypeBarChartView(stats: StatsEngine.shotTypeBreakdown(for: filteredShots))
                    }

                    section("Danger Zone Performance") {
                        dangerRows
                    }

                    section("Situational Splits") {
                        strengthRows
                    }

                    section("Home / Away") {
                        homeAwaySplit
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.rinkBackground)
            .navigationTitle("Analytics")
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            content()
                .padding(.horizontal)
        }
    }

    private var dangerRows: some View {
        VStack(spacing: 6) {
            ForEach(StatsEngine.dangerBreakdown(for: filteredShots)) { stat in
                HStack {
                    Circle().fill(Theme.dangerColor(stat.danger)).frame(width: 8, height: 8)
                    Text(stat.danger.displayName)
                    Spacer()
                    Text(stat.stats.shotsFaced > 0 ? "\(stat.stats.saves)/\(stat.stats.shotsFaced) · \(String(format: "%.3f", stat.stats.savePercentage))" : "—")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .cardStyle()
    }

    private var strengthRows: some View {
        VStack(spacing: 6) {
            ForEach(StatsEngine.strengthBreakdown(for: filteredShots).filter { $0.stats.shotsFaced > 0 }) { stat in
                HStack {
                    Text(stat.strengthState.displayName)
                    Spacer()
                    Text("\(stat.stats.saves)/\(stat.stats.shotsFaced) · \(String(format: "%.3f", stat.stats.savePercentage))")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .cardStyle()
    }

    private var homeAwaySplit: some View {
        let home = StatsEngine.shotStats(for: filteredSummaries.filter(\.game.isHome).flatMap { summary in
            filteredShots.filter { $0.gameID == summary.game.id }
        })
        let away = StatsEngine.shotStats(for: filteredSummaries.filter { !$0.game.isHome }.flatMap { summary in
            filteredShots.filter { $0.gameID == summary.game.id }
        })
        return HStack(spacing: 12) {
            StatTileView(title: "Home", value: home.shotsFaced > 0 ? String(format: "%.3f", home.savePercentage) : "—", subtitle: "\(home.saves)/\(home.shotsFaced)")
            StatTileView(title: "Away", value: away.shotsFaced > 0 ? String(format: "%.3f", away.savePercentage) : "—", subtitle: "\(away.saves)/\(away.shotsFaced)")
        }
    }
}
