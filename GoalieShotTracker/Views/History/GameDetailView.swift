import SwiftUI
import SwiftData

struct GameDetailView: View {
    let game: GameSessionEntity
    @Query private var allShots: [ShotEventEntity]

    private var shots: [ShotEvent] {
        allShots.filter { $0.game?.id == game.id }.map(\.asCoreModel).sorted { $0.timestamp < $1.timestamp }
    }

    private var exportURL: URL? {
        CSVExporter.writeTempFile(
            csv: CSVExporter.export(shots: shots, games: [game.asCoreModel]),
            filename: "\(game.opponentName)-shots.csv"
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                zoneHeatmap
                periodBreakdown
                shotTimeline
            }
            .padding(.vertical)
        }
        .background(Theme.rinkBackground)
        .navigationTitle("\(game.isHome ? "vs" : "@") \(game.opponentName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        let stats = StatsEngine.shotStats(for: shots)
        return HStack(spacing: 12) {
            StatTileView(title: "Shots", value: "\(stats.shotsFaced)")
            StatTileView(title: "Saves", value: "\(stats.saves)", valueColor: Theme.saveGreen)
            StatTileView(title: "Goals", value: "\(stats.goals)")
            StatTileView(
                title: "Save %",
                value: stats.shotsFaced > 0 ? String(format: "%.3f", stats.savePercentage) : "—",
                valueColor: Theme.savePercentageColor(stats.savePercentage)
            )
        }
        .padding(.horizontal)
    }

    private var zoneHeatmap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zone Breakdown")
                .font(.headline)
                .padding(.horizontal)
            ZoneHeatmapView(zoneStats: Dictionary(uniqueKeysWithValues: StatsEngine.zoneBreakdown(for: shots).map { ($0.zone, $0.stats) }))
                .padding(.horizontal)
        }
    }

    private var periodBreakdown: some View {
        let periods = Set(shots.map(\.period)).sorted()
        return VStack(alignment: .leading, spacing: 8) {
            Text("By Period")
                .font(.headline)
                .padding(.horizontal)
            ForEach(periods, id: \.self) { period in
                let periodStats = StatsEngine.shotStats(for: shots.filter { $0.period == period })
                HStack {
                    Text("Period \(period)")
                    Spacer()
                    Text("\(periodStats.saves)/\(periodStats.shotsFaced)")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .font(.subheadline)
            }
        }
    }

    private var shotTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shot Log")
                .font(.headline)
                .padding(.horizontal)
            ForEach(shots) { shot in
                HStack {
                    Circle()
                        .fill(shot.isGoal ? Theme.goalRed : Theme.saveGreen)
                        .frame(width: 8, height: 8)
                    Text("P\(shot.period)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)
                    Text(shot.zone.displayName)
                    Spacer()
                    Text(shot.shotType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(shot.outcome.displayName)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal)
                .font(.subheadline)
            }
        }
    }
}
