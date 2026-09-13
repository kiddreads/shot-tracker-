import Foundation

/// Shared helper so Dashboard, History, and Analytics all slice the same
/// SwiftData query results down to "this goalie's games and shots" the
/// same way before handing them to `StatsEngine`.
enum GoalieStatsProvider {
    static func summaries(
        goalieID: UUID?,
        games: [GameSessionEntity],
        shots: [ShotEventEntity]
    ) -> [GameSummary] {
        guard let goalieID else { return [] }
        let goalieGames = games
            .filter { $0.goalieIDs.contains(goalieID) }
            .map(\.asCoreModel)
        let goalieShots = shots
            .filter { $0.goalieID == goalieID }
            .map(\.asCoreModel)
        return StatsEngine.summarize(games: goalieGames, shots: goalieShots)
    }
}
