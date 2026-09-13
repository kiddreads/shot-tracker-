import Foundation

/// The net divided into a 3x3 grid, the standard layout used by goalie shot
/// charts: three vertical bands (glove / center / blocker side, as seen from
/// the goalie's perspective looking out) crossed with three heights.
public enum NetZone: String, CaseIterable, Codable, Identifiable, Sendable {
    case highGlove
    case highCenter
    case highBlocker
    case midGlove
    case midCenter
    case midBlocker
    case lowGlove
    case fiveHole
    case lowBlocker

    public var id: String { rawValue }

    public enum Row: String, Codable, Sendable {
        case high, mid, low
    }

    public enum Column: String, Codable, Sendable {
        case glove, center, blocker
    }

    public var row: Row {
        switch self {
        case .highGlove, .highCenter, .highBlocker: return .high
        case .midGlove, .midCenter, .midBlocker: return .mid
        case .lowGlove, .fiveHole, .lowBlocker: return .low
        }
    }

    public var column: Column {
        switch self {
        case .highGlove, .midGlove, .lowGlove: return .glove
        case .highCenter, .midCenter, .fiveHole: return .center
        case .highBlocker, .midBlocker, .lowBlocker: return .blocker
        }
    }

    /// (row, column) grid coordinates, 0-indexed top-left, for laying out
    /// a 3x3 heatmap grid in the UI without re-deriving positions there.
    public var gridPosition: (row: Int, column: Int) {
        let rowIndex: Int
        switch row {
        case .high: rowIndex = 0
        case .mid: rowIndex = 1
        case .low: rowIndex = 2
        }
        let colIndex: Int
        switch column {
        case .glove: colIndex = 0
        case .center: colIndex = 1
        case .blocker: colIndex = 2
        }
        return (rowIndex, colIndex)
    }

    public var displayName: String {
        switch self {
        case .highGlove: return "High Glove"
        case .highCenter: return "High Center"
        case .highBlocker: return "High Blocker"
        case .midGlove: return "Glove Side"
        case .midCenter: return "Chest"
        case .midBlocker: return "Blocker Side"
        case .lowGlove: return "Low Glove"
        case .fiveHole: return "Five-Hole"
        case .lowBlocker: return "Low Blocker"
        }
    }

    /// Baseline scoring danger for a shot landing in this zone, independent
    /// of shot type or game situation. Used as the default input to
    /// `DangerLevel.compute`.
    public var baselineDanger: DangerLevel {
        switch self {
        case .fiveHole, .lowGlove, .lowBlocker:
            return .high
        case .midGlove, .midCenter, .midBlocker:
            return .medium
        case .highGlove, .highCenter, .highBlocker:
            return .low
        }
    }
}
