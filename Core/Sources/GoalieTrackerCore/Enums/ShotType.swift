import Foundation

public enum ShotType: String, CaseIterable, Codable, Identifiable, Sendable {
    case wristShot
    case slapShot
    case snapShot
    case backhand
    case deflection
    case oneTimer
    case wraparound
    case breakaway
    case penaltyShot
    case shootout

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .wristShot: return "Wrist Shot"
        case .slapShot: return "Slap Shot"
        case .snapShot: return "Snap Shot"
        case .backhand: return "Backhand"
        case .deflection: return "Deflection / Tip"
        case .oneTimer: return "One-Timer"
        case .wraparound: return "Wraparound"
        case .breakaway: return "Breakaway"
        case .penaltyShot: return "Penalty Shot"
        case .shootout: return "Shootout"
        }
    }

    /// Shot types that inherently elevate danger regardless of zone
    /// (a clean look at the goalie with little time to react).
    public var isHighDangerByNature: Bool {
        switch self {
        case .deflection, .oneTimer, .breakaway, .penaltyShot, .wraparound:
            return true
        case .wristShot, .slapShot, .snapShot, .backhand, .shootout:
            return false
        }
    }

    /// True for shootout/penalty-shot attempts, which are tracked and
    /// scored separately from regular game shots in most stat sheets.
    public var isOneOnOneAttempt: Bool {
        self == .penaltyShot || self == .shootout
    }
}
