import Foundation
import SwiftData

// SwiftData `@Model` entities mirror the pure `GoalieTrackerCore` value types
// one-for-one, but as persisted reference types. Every entity exposes
// `asCoreModel` / `init(from:)` so the rest of the app (views, StatsEngine)
// only ever deals in the plain Core structs — SwiftData never leaks past
// this file.

@Model
final class GoalieProfileEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var jerseyNumber: Int?
    var catchHandRaw: String
    var teamName: String?
    var birthDate: Date?
    var notes: String?

    init(id: UUID = UUID(), name: String, jerseyNumber: Int? = nil, catchHandRaw: String = CatchHand.left.rawValue, teamName: String? = nil, birthDate: Date? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.jerseyNumber = jerseyNumber
        self.catchHandRaw = catchHandRaw
        self.teamName = teamName
        self.birthDate = birthDate
        self.notes = notes
    }

    convenience init(from model: GoalieProfile) {
        self.init(
            id: model.id,
            name: model.name,
            jerseyNumber: model.jerseyNumber,
            catchHandRaw: model.catchHand.rawValue,
            teamName: model.teamName,
            birthDate: model.birthDate,
            notes: model.notes
        )
    }

    func update(from model: GoalieProfile) {
        name = model.name
        jerseyNumber = model.jerseyNumber
        catchHandRaw = model.catchHand.rawValue
        teamName = model.teamName
        birthDate = model.birthDate
        notes = model.notes
    }

    var asCoreModel: GoalieProfile {
        GoalieProfile(
            id: id,
            name: name,
            jerseyNumber: jerseyNumber,
            catchHand: CatchHand(rawValue: catchHandRaw) ?? .left,
            teamName: teamName,
            birthDate: birthDate,
            notes: notes
        )
    }
}

@Model
final class TeamEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String?

    init(id: UUID = UUID(), name: String, colorHex: String? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    var asCoreModel: Team { Team(id: id, name: name, colorHex: colorHex) }
}

@Model
final class OpponentEntity {
    @Attribute(.unique) var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    var asCoreModel: Opponent { Opponent(id: id, name: name) }
}

@Model
final class GameSessionEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sessionTypeRaw: String
    var teamName: String
    var opponentName: String
    var isHome: Bool
    var periodCount: Int
    var goalieIDs: [UUID]
    var finalScoreFor: Int?
    var finalScoreAgainst: Int?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \ShotEventEntity.game)
    var shots: [ShotEventEntity] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sessionTypeRaw: String = SessionType.game.rawValue,
        teamName: String,
        opponentName: String,
        isHome: Bool = true,
        periodCount: Int = 3,
        goalieIDs: [UUID] = [],
        finalScoreFor: Int? = nil,
        finalScoreAgainst: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sessionTypeRaw = sessionTypeRaw
        self.teamName = teamName
        self.opponentName = opponentName
        self.isHome = isHome
        self.periodCount = periodCount
        self.goalieIDs = goalieIDs
        self.finalScoreFor = finalScoreFor
        self.finalScoreAgainst = finalScoreAgainst
        self.notes = notes
    }

    convenience init(from model: GameSession) {
        self.init(
            id: model.id,
            date: model.date,
            sessionTypeRaw: model.sessionType.rawValue,
            teamName: model.teamName,
            opponentName: model.opponentName,
            isHome: model.isHome,
            periodCount: model.periodCount,
            goalieIDs: model.goalieIDs,
            finalScoreFor: model.finalScoreFor,
            finalScoreAgainst: model.finalScoreAgainst,
            notes: model.notes
        )
    }

    func update(from model: GameSession) {
        date = model.date
        sessionTypeRaw = model.sessionType.rawValue
        teamName = model.teamName
        opponentName = model.opponentName
        isHome = model.isHome
        periodCount = model.periodCount
        goalieIDs = model.goalieIDs
        finalScoreFor = model.finalScoreFor
        finalScoreAgainst = model.finalScoreAgainst
        notes = model.notes
    }

    var asCoreModel: GameSession {
        GameSession(
            id: id,
            date: date,
            sessionType: SessionType(rawValue: sessionTypeRaw) ?? .game,
            teamName: teamName,
            opponentName: opponentName,
            isHome: isHome,
            periodCount: periodCount,
            goalieIDs: goalieIDs,
            finalScoreFor: finalScoreFor,
            finalScoreAgainst: finalScoreAgainst,
            notes: notes
        )
    }
}

@Model
final class ShotEventEntity {
    @Attribute(.unique) var id: UUID
    var goalieID: UUID
    var timestamp: Date
    var period: Int
    var zoneRaw: String
    var shotTypeRaw: String
    var outcomeRaw: String
    var strengthStateRaw: String
    var isRushOrOddMan: Bool
    var shooterName: String?
    var notes: String?

    var game: GameSessionEntity?

    init(
        id: UUID = UUID(),
        goalieID: UUID,
        timestamp: Date = Date(),
        period: Int = 1,
        zoneRaw: String,
        shotTypeRaw: String,
        outcomeRaw: String,
        strengthStateRaw: String = StrengthState.evenStrength.rawValue,
        isRushOrOddMan: Bool = false,
        shooterName: String? = nil,
        notes: String? = nil,
        game: GameSessionEntity? = nil
    ) {
        self.id = id
        self.goalieID = goalieID
        self.timestamp = timestamp
        self.period = period
        self.zoneRaw = zoneRaw
        self.shotTypeRaw = shotTypeRaw
        self.outcomeRaw = outcomeRaw
        self.strengthStateRaw = strengthStateRaw
        self.isRushOrOddMan = isRushOrOddMan
        self.shooterName = shooterName
        self.notes = notes
        self.game = game
    }

    convenience init(from model: ShotEvent, game: GameSessionEntity?) {
        self.init(
            id: model.id,
            goalieID: model.goalieID,
            timestamp: model.timestamp,
            period: model.period,
            zoneRaw: model.zone.rawValue,
            shotTypeRaw: model.shotType.rawValue,
            outcomeRaw: model.outcome.rawValue,
            strengthStateRaw: model.strengthState.rawValue,
            isRushOrOddMan: model.isRushOrOddMan,
            shooterName: model.shooterName,
            notes: model.notes,
            game: game
        )
    }

    var asCoreModel: ShotEvent {
        ShotEvent(
            id: id,
            gameID: game?.id ?? UUID(),
            goalieID: goalieID,
            timestamp: timestamp,
            period: period,
            zone: NetZone(rawValue: zoneRaw) ?? .midCenter,
            shotType: ShotType(rawValue: shotTypeRaw) ?? .wristShot,
            outcome: ShotOutcome(rawValue: outcomeRaw) ?? .savedFrozen,
            strengthState: StrengthState(rawValue: strengthStateRaw) ?? .evenStrength,
            isRushOrOddMan: isRushOrOddMan,
            shooterName: shooterName,
            notes: notes
        )
    }
}
