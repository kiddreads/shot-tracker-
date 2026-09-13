import Foundation

public struct ShotEvent: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var gameID: UUID
    public var goalieID: UUID
    public var timestamp: Date
    public var period: Int
    public var zone: NetZone
    public var shotType: ShotType
    public var outcome: ShotOutcome
    public var strengthState: StrengthState
    public var isRushOrOddMan: Bool
    public var shooterName: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        gameID: UUID,
        goalieID: UUID,
        timestamp: Date = Date(),
        period: Int = 1,
        zone: NetZone,
        shotType: ShotType,
        outcome: ShotOutcome,
        strengthState: StrengthState = .evenStrength,
        isRushOrOddMan: Bool = false,
        shooterName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.gameID = gameID
        self.goalieID = goalieID
        self.timestamp = timestamp
        self.period = period
        self.zone = zone
        self.shotType = shotType
        self.outcome = outcome
        self.strengthState = strengthState
        self.isRushOrOddMan = isRushOrOddMan
        self.shooterName = shooterName
        self.notes = notes
    }

    public var isGoal: Bool { outcome.isGoal }
    public var isSave: Bool { outcome.isSave }
    public var countsAsShotOnGoal: Bool { outcome.reachedGoalie }

    public var dangerLevel: DangerLevel {
        DangerLevel.compute(
            zone: zone,
            shotType: shotType,
            isRushOrOddMan: isRushOrOddMan,
            strengthState: strengthState
        )
    }
}
