import Foundation

public enum ShotOutcome: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Puck stopped, no rebound of consequence (frozen, covered, or held).
    case savedFrozen
    /// Puck stopped, but a rebound was kicked/dropped into play.
    case savedRebound
    /// Puck went in.
    case goal
    /// Puck went in directly off a rebound the goalie had just given up.
    case goalOnRebound
    /// Shot missed the net entirely (wide or over).
    case missedNet
    /// Shot was blocked by a skater before reaching the goalie.
    case blockedShot
    /// Shot hit iron and stayed out.
    case postOrCrossbar

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .savedFrozen: return "Save (Frozen)"
        case .savedRebound: return "Save (Rebound)"
        case .goal: return "Goal"
        case .goalOnRebound: return "Goal (Rebound)"
        case .missedNet: return "Missed Net"
        case .blockedShot: return "Blocked"
        case .postOrCrossbar: return "Post / Crossbar"
        }
    }

    public var isGoal: Bool {
        self == .goal || self == .goalOnRebound
    }

    public var isSave: Bool {
        self == .savedFrozen || self == .savedRebound
    }

    /// Whether this event should be counted in the shots-on-goal denominator
    /// (i.e. it reached the goalie, unlike a miss or a shot-block).
    public var reachedGoalie: Bool {
        switch self {
        case .savedFrozen, .savedRebound, .goal, .goalOnRebound:
            return true
        case .missedNet, .blockedShot, .postOrCrossbar:
            return false
        }
    }

    /// Whether a controlled rebound was given up on this play, for
    /// rebound-control tracking independent of the eventual outcome.
    public var isUncontrolledRebound: Bool {
        self == .savedRebound || self == .goalOnRebound
    }
}
