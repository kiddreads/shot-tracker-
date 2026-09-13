import Foundation

public struct GoalieProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var jerseyNumber: Int?
    public var catchHand: CatchHand
    public var teamName: String?
    public var birthDate: Date?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        jerseyNumber: Int? = nil,
        catchHand: CatchHand = .left,
        teamName: String? = nil,
        birthDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.jerseyNumber = jerseyNumber
        self.catchHand = catchHand
        self.teamName = teamName
        self.birthDate = birthDate
        self.notes = notes
    }
}
