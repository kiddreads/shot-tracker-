import Foundation

/// The game situation the goalie's team was in when a shot was faced.
public enum StrengthState: String, CaseIterable, Codable, Identifiable, Sendable {
    case evenStrength
    case powerPlayAgainst   // goalie's team is shorthanded (penalty kill)
    case shortHandedFor     // goalie's team has the man advantage
    case fourOnFour
    case threeOnThree
    case penaltyShot
    case shootout

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .evenStrength: return "Even Strength"
        case .powerPlayAgainst: return "Penalty Kill"
        case .shortHandedFor: return "Power Play"
        case .fourOnFour: return "4-on-4"
        case .threeOnThree: return "3-on-3"
        case .penaltyShot: return "Penalty Shot"
        case .shootout: return "Shootout"
        }
    }

    public var shortLabel: String {
        switch self {
        case .evenStrength: return "EV"
        case .powerPlayAgainst: return "PK"
        case .shortHandedFor: return "PP"
        case .fourOnFour: return "4v4"
        case .threeOnThree: return "3v3"
        case .penaltyShot: return "PS"
        case .shootout: return "SO"
        }
    }
}

public enum DangerLevel: String, CaseIterable, Codable, Identifiable, Sendable, Comparable {
    case low, medium, high

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .low: return "Low Danger"
        case .medium: return "Medium Danger"
        case .high: return "High Danger"
        }
    }

    private var rank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    public static func < (lhs: DangerLevel, rhs: DangerLevel) -> Bool {
        lhs.rank < rhs.rank
    }

    /// Combines a zone's baseline danger with situational modifiers
    /// (shot type, rush/odd-man play, and short-handed situations all
    /// raise danger) to produce a single effective danger level.
    public static func compute(
        zone: NetZone,
        shotType: ShotType,
        isRushOrOddMan: Bool,
        strengthState: StrengthState
    ) -> DangerLevel {
        var level = zone.baselineDanger

        if shotType.isHighDangerByNature {
            level = max(level, .high)
        }
        if isRushOrOddMan {
            level = max(level, .medium)
        }
        if strengthState == .powerPlayAgainst, level == .low {
            level = .medium
        }
        return level
    }
}

public enum SessionType: String, CaseIterable, Codable, Identifiable, Sendable {
    case game, practice, scrimmage

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .game: return "Game"
        case .practice: return "Practice"
        case .scrimmage: return "Scrimmage"
        }
    }
}

public enum CatchHand: String, CaseIterable, Codable, Identifiable, Sendable {
    case left, right

    public var id: String { rawValue }

    public var displayName: String { self == .left ? "Left" : "Right" }
}
