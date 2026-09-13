import Foundation

/// Pure, stateless functions that turn a flat shot log into every stat view
/// the app surfaces. Nothing here touches persistence or UI, so it can be
/// exercised directly by unit tests.
public enum StatsEngine {

    // MARK: - Breakdowns

    public static func shotStats(for shots: [ShotEvent]) -> ShotStats {
        ShotStats.compute(from: shots)
    }

    public static func zoneBreakdown(for shots: [ShotEvent]) -> [ZoneStat] {
        NetZone.allCases.map { zone in
            ZoneStat(zone: zone, stats: ShotStats.compute(from: shots.filter { $0.zone == zone }))
        }
    }

    public static func shotTypeBreakdown(for shots: [ShotEvent]) -> [ShotTypeStat] {
        ShotType.allCases.map { type in
            ShotTypeStat(shotType: type, stats: ShotStats.compute(from: shots.filter { $0.shotType == type }))
        }
    }

    public static func dangerBreakdown(for shots: [ShotEvent]) -> [DangerStat] {
        DangerLevel.allCases.map { level in
            DangerStat(danger: level, stats: ShotStats.compute(from: shots.filter { $0.dangerLevel == level }))
        }
    }

    public static func strengthBreakdown(for shots: [ShotEvent]) -> [StrengthStat] {
        StrengthState.allCases.map { state in
            StrengthStat(strengthState: state, stats: ShotStats.compute(from: shots.filter { $0.strengthState == state }))
        }
    }

    // MARK: - Per-game evaluation

    /// League-average save percentage used as the "quality start" bar for
    /// games with a normal shot volume. Mirrors the NHL's own quality-start
    /// methodology: meet the average save% for the shot volume you saw, or
    /// (on a light night) keep the goals against to 2 or fewer.
    public static let defaultQualityStartThreshold = 0.885

    public static func isShutout(for shots: [ShotEvent]) -> Bool {
        let stats = ShotStats.compute(from: shots)
        return stats.shotsFaced > 0 && stats.goals == 0
    }

    public static func isQualityStart(
        for shots: [ShotEvent],
        leagueAverageSavePercentage: Double = defaultQualityStartThreshold
    ) -> Bool {
        let stats = ShotStats.compute(from: shots)
        guard stats.shotsFaced > 0 else { return false }
        if stats.shotsFaced < 20 {
            return stats.goals <= 2
        }
        return stats.savePercentage >= leagueAverageSavePercentage
    }

    public static func summarize(game: GameSession, shots: [ShotEvent]) -> GameSummary {
        let gameShots = shots.filter { $0.gameID == game.id }
        let overall = ShotStats.compute(from: gameShots)
        let highDanger = ShotStats.compute(from: gameShots.filter { $0.dangerLevel == .high })
        return GameSummary(
            game: game,
            overall: overall,
            highDanger: highDanger,
            isShutout: isShutout(for: gameShots),
            isQualityStart: isQualityStart(for: gameShots)
        )
    }

    public static func summarize(games: [GameSession], shots: [ShotEvent]) -> [GameSummary] {
        games
            .map { summarize(game: $0, shots: shots) }
            .sorted { $0.game.date < $1.game.date }
    }

    // MARK: - Trend

    public static func trend(from summaries: [GameSummary]) -> [TrendPoint] {
        summaries
            .sorted { $0.game.date < $1.game.date }
            .map {
                TrendPoint(
                    gameID: $0.game.id,
                    date: $0.game.date,
                    savePercentage: $0.overall.savePercentage,
                    shotsFaced: $0.overall.shotsFaced
                )
            }
    }

    // MARK: - Season roll-up

    public static func seasonStats(from summaries: [GameSummary]) -> ShotStats {
        ShotStats.aggregate(summaries.map(\.overall))
    }

    // MARK: - Badges

    public static func badgesEarned(from summaries: [GameSummary]) -> Set<Badge> {
        let sorted = summaries.sorted { $0.game.date < $1.game.date }
        var earned = Set<Badge>()

        if sorted.contains(where: \.isShutout) {
            earned.insert(.shutout)
        }
        if hasConsecutiveRun(sorted, minLength: 2, matching: \.isShutout) {
            earned.insert(.backToBackShutouts)
        }
        if sorted.contains(where: { $0.overall.saves >= 30 }) {
            earned.insert(.thirtyPlusSaveGame)
        }
        if sorted.contains(where: { $0.overall.saves >= 40 }) {
            earned.insert(.fortyPlusSaveGame)
        }
        if sorted.contains(where: { $0.overall.shotsFaced >= 10 && $0.overall.savePercentage >= 0.95 }) {
            earned.insert(.ninetyFivePercentGame)
        }
        if sorted.contains(where: { $0.highDanger.shotsFaced >= 3 && $0.highDanger.goals == 0 }) {
            earned.insert(.perfectHighDangerGame)
        }

        let season = seasonStats(from: sorted)
        if sorted.count >= 5 && season.savePercentage >= 0.920 {
            earned.insert(.ironWallSeason)
        }
        if sorted.count >= 10 {
            earned.insert(.workhorseSeason)
        }
        if hasConsecutiveRun(sorted, minLength: 5, matching: \.isQualityStart) {
            earned.insert(.qualityStartStreak5)
        }

        return earned
    }

    private static func hasConsecutiveRun(
        _ summaries: [GameSummary],
        minLength: Int,
        matching predicate: (GameSummary) -> Bool
    ) -> Bool {
        var run = 0
        for summary in summaries {
            run = predicate(summary) ? run + 1 : 0
            if run >= minLength { return true }
        }
        return false
    }
}
