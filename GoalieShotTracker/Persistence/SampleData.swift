import Foundation
import SwiftData

/// Deterministic sample data used only by SwiftUI previews and the
/// onboarding "try a demo" path — never inserted into the real store.
enum SampleData {
    @MainActor
    static func populate(_ context: ModelContext) {
        let goalie = GoalieProfileEntity(name: "Jordan Cole", jerseyNumber: 31, catchHandRaw: CatchHand.left.rawValue, teamName: "Falcons")
        context.insert(goalie)

        let team = TeamEntity(name: "Falcons", colorHex: "#1E88E5")
        context.insert(team)

        let opponents = ["Wolves", "Ice Hawks", "Renegades", "Blizzard"]
        opponents.forEach { context.insert(OpponentEntity(name: $0)) }

        let calendar = Calendar.current
        for gameIndex in 0..<6 {
            let date = calendar.date(byAdding: .day, value: -7 * (6 - gameIndex), to: Date()) ?? Date()
            let game = GameSessionEntity(
                date: date,
                teamName: "Falcons",
                opponentName: opponents[gameIndex % opponents.count],
                isHome: gameIndex % 2 == 0,
                goalieIDs: [goalie.id]
            )
            context.insert(game)

            let shotCount = Int.random(in: 18...34)
            var goalsAllowed = 0
            for shotIndex in 0..<shotCount {
                let zone = NetZone.allCases.randomElement() ?? .midCenter
                let shotType = ShotType.allCases.randomElement() ?? .wristShot
                let isGoal = Double.random(in: 0...1) < 0.08
                if isGoal { goalsAllowed += 1 }
                let outcome: ShotOutcome = isGoal ? .goal : [.savedFrozen, .savedRebound].randomElement()!
                let shot = ShotEventEntity(
                    goalieID: goalie.id,
                    timestamp: date,
                    period: (shotIndex / 12) + 1,
                    zoneRaw: zone.rawValue,
                    shotTypeRaw: shotType.rawValue,
                    outcomeRaw: outcome.rawValue,
                    strengthStateRaw: StrengthState.evenStrength.rawValue,
                    game: game
                )
                context.insert(shot)
            }
            game.finalScoreFor = Int.random(in: 1...5)
            game.finalScoreAgainst = goalsAllowed
        }

        try? context.save()
    }
}
