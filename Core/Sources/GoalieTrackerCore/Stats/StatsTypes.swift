import Foundation

/// A simple shots/saves/goals/save% bundle. The one building block every
/// other stats view (zone, shot type, danger, per-game, season) is made of.
public struct ShotStats: Codable, Hashable, Sendable {
    public var shotsFaced: Int
    public var saves: Int
    public var goals: Int
    public var savePercentage: Double

    public init(shotsFaced: Int, saves: Int, goals: Int, savePercentage: Double) {
        self.shotsFaced = shotsFaced
        self.saves = saves
        self.goals = goals
        self.savePercentage = savePercentage
    }

    public static let zero = ShotStats(shotsFaced: 0, saves: 0, goals: 0, savePercentage: 0)

    public static func compute(from shots: [ShotEvent]) -> ShotStats {
        let onGoal = shots.filter(\.countsAsShotOnGoal)
        let saves = onGoal.filter(\.isSave).count
        let goals = onGoal.filter(\.isGoal).count
        let faced = onGoal.count
        let pct = faced > 0 ? Double(saves) / Double(faced) : 0
        return ShotStats(shotsFaced: faced, saves: saves, goals: goals, savePercentage: pct)
    }

    /// Sums the raw counts across several stat lines and recomputes save%
    /// from the totals (never averages percentages directly).
    public static func aggregate(_ lines: [ShotStats]) -> ShotStats {
        let faced = lines.reduce(0) { $0 + $1.shotsFaced }
        let saves = lines.reduce(0) { $0 + $1.saves }
        let goals = lines.reduce(0) { $0 + $1.goals }
        let pct = faced > 0 ? Double(saves) / Double(faced) : 0
        return ShotStats(shotsFaced: faced, saves: saves, goals: goals, savePercentage: pct)
    }
}

public struct ZoneStat: Identifiable, Codable, Hashable, Sendable {
    public var zone: NetZone
    public var stats: ShotStats
    public var id: String { zone.rawValue }

    public init(zone: NetZone, stats: ShotStats) {
        self.zone = zone
        self.stats = stats
    }
}

public struct ShotTypeStat: Identifiable, Codable, Hashable, Sendable {
    public var shotType: ShotType
    public var stats: ShotStats
    public var id: String { shotType.rawValue }

    public init(shotType: ShotType, stats: ShotStats) {
        self.shotType = shotType
        self.stats = stats
    }
}

public struct DangerStat: Identifiable, Codable, Hashable, Sendable {
    public var danger: DangerLevel
    public var stats: ShotStats
    public var id: String { danger.rawValue }

    public init(danger: DangerLevel, stats: ShotStats) {
        self.danger = danger
        self.stats = stats
    }
}

public struct StrengthStat: Identifiable, Codable, Hashable, Sendable {
    public var strengthState: StrengthState
    public var stats: ShotStats
    public var id: String { strengthState.rawValue }

    public init(strengthState: StrengthState, stats: ShotStats) {
        self.strengthState = strengthState
        self.stats = stats
    }
}

public struct GameSummary: Identifiable, Codable, Hashable, Sendable {
    public var game: GameSession
    public var overall: ShotStats
    public var highDanger: ShotStats
    public var isShutout: Bool
    public var isQualityStart: Bool

    public var id: UUID { game.id }

    public init(game: GameSession, overall: ShotStats, highDanger: ShotStats, isShutout: Bool, isQualityStart: Bool) {
        self.game = game
        self.overall = overall
        self.highDanger = highDanger
        self.isShutout = isShutout
        self.isQualityStart = isQualityStart
    }
}

public struct TrendPoint: Identifiable, Codable, Hashable, Sendable {
    public var gameID: UUID
    public var date: Date
    public var savePercentage: Double
    public var shotsFaced: Int

    public var id: UUID { gameID }

    public init(gameID: UUID, date: Date, savePercentage: Double, shotsFaced: Int) {
        self.gameID = gameID
        self.date = date
        self.savePercentage = savePercentage
        self.shotsFaced = shotsFaced
    }
}
