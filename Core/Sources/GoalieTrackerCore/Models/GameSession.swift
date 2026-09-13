import Foundation

public struct GameSession: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var sessionType: SessionType
    public var teamName: String
    public var opponentName: String
    public var isHome: Bool
    public var periodCount: Int
    /// Goalies who appeared in this session, in the order they entered.
    public var goalieIDs: [UUID]
    public var finalScoreFor: Int?
    public var finalScoreAgainst: Int?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        sessionType: SessionType = .game,
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
        self.sessionType = sessionType
        self.teamName = teamName
        self.opponentName = opponentName
        self.isHome = isHome
        self.periodCount = periodCount
        self.goalieIDs = goalieIDs
        self.finalScoreFor = finalScoreFor
        self.finalScoreAgainst = finalScoreAgainst
        self.notes = notes
    }
}
