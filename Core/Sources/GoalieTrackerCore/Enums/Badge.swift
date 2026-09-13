import Foundation

/// Achievements computed from a goalie's game log by `StatsEngine.badgesEarned`.
/// Each case is self-contained (no associated thresholds) so the type stays
/// trivially `Codable` and `CaseIterable`; the thresholds themselves live in
/// `StatsEngine` alongside the rest of the scoring logic.
public enum Badge: String, CaseIterable, Codable, Identifiable, Sendable {
    case shutout
    case backToBackShutouts
    case thirtyPlusSaveGame
    case fortyPlusSaveGame
    case ninetyFivePercentGame
    case perfectHighDangerGame
    case ironWallSeason
    case workhorseSeason
    case qualityStartStreak5

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .shutout: return "Shutout"
        case .backToBackShutouts: return "Back-to-Back Shutouts"
        case .thirtyPlusSaveGame: return "30-Save Game"
        case .fortyPlusSaveGame: return "40-Save Game"
        case .ninetyFivePercentGame: return ".950+ Game"
        case .perfectHighDangerGame: return "High-Danger Wall"
        case .ironWallSeason: return "Iron Wall"
        case .workhorseSeason: return "Workhorse"
        case .qualityStartStreak5: return "5 Straight Quality Starts"
        }
    }

    public var detail: String {
        switch self {
        case .shutout: return "Faced at least one shot and allowed zero goals in a game."
        case .backToBackShutouts: return "Posted shutouts in two consecutive games."
        case .thirtyPlusSaveGame: return "Made 30 or more saves in a single game."
        case .fortyPlusSaveGame: return "Made 40 or more saves in a single game."
        case .ninetyFivePercentGame: return "Posted a .950 save percentage or better in a game with 10+ shots faced."
        case .perfectHighDangerGame: return "Stopped every high-danger shot faced in a game with at least 3 high-danger shots."
        case .ironWallSeason: return "Season save percentage of .920 or better across 5+ games."
        case .workhorseSeason: return "Played in 10 or more games in a season."
        case .qualityStartStreak5: return "Posted 5 consecutive quality starts."
        }
    }
}
