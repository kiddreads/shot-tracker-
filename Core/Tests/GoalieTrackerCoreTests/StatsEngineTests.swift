import XCTest
@testable import GoalieTrackerCore

final class StatsEngineTests: XCTestCase {
    private let goalieID = UUID()
    private let calendar = Calendar(identifier: .gregorian)

    private func makeGame(daysAgo: Int) -> GameSession {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return GameSession(date: date, teamName: "Falcons", opponentName: "Wolves", goalieIDs: [goalieID])
    }

    private func shot(
        gameID: UUID,
        zone: NetZone = .midCenter,
        shotType: ShotType = .wristShot,
        outcome: ShotOutcome
    ) -> ShotEvent {
        ShotEvent(gameID: gameID, goalieID: goalieID, zone: zone, shotType: shotType, outcome: outcome)
    }

    // MARK: - Breakdowns

    func testZoneBreakdownCoversAllNineZonesEvenWithNoShotsThere() {
        let game = makeGame(daysAgo: 0)
        let shots = [shot(gameID: game.id, zone: .fiveHole, outcome: .goal)]
        let breakdown = StatsEngine.zoneBreakdown(for: shots)
        XCTAssertEqual(breakdown.count, NetZone.allCases.count)
        let fiveHole = breakdown.first { $0.zone == .fiveHole }
        XCTAssertEqual(fiveHole?.stats.goals, 1)
        let untouched = breakdown.first { $0.zone == .highBlocker }
        XCTAssertEqual(untouched?.stats.shotsFaced, 0)
    }

    // MARK: - Shutouts & quality starts

    func testShutoutRequiresAtLeastOneShotFaced() {
        XCTAssertFalse(StatsEngine.isShutout(for: []), "No shots faced shouldn't count as a shutout.")
    }

    func testShutoutTrueWithZeroGoalsAllowed() {
        let game = makeGame(daysAgo: 0)
        let shots = (0..<15).map { _ in shot(gameID: game.id, outcome: .savedFrozen) }
        XCTAssertTrue(StatsEngine.isShutout(for: shots))
    }

    func testQualityStartUnderTwentyShotsAllowsAtMostTwoGoals() {
        let game = makeGame(daysAgo: 0)
        let shots = (0..<10).map { i in shot(gameID: game.id, outcome: i < 8 ? .savedFrozen : .goal) }
        XCTAssertTrue(StatsEngine.isQualityStart(for: shots), "8/10 with 2 goals on light volume should still be a quality start.")
    }

    func testQualityStartAtHighVolumeNeedsLeagueAverageSavePercentage() {
        let game = makeGame(daysAgo: 0)
        // 25 shots, 3 goals => .880, just under the .885 default bar.
        let shots = (0..<25).map { i in shot(gameID: game.id, outcome: i < 22 ? .savedFrozen : .goal) }
        XCTAssertFalse(StatsEngine.isQualityStart(for: shots))
    }

    // MARK: - Season roll-up & trend

    func testSeasonStatsAggregatesAcrossGames() {
        let gameA = makeGame(daysAgo: 2)
        let gameB = makeGame(daysAgo: 1)
        let shots = (0..<10).map { _ in shot(gameID: gameA.id, outcome: .savedFrozen) }
            + (0..<10).map { i in shot(gameID: gameB.id, outcome: i < 8 ? .savedFrozen : .goal) }
        let summaries = StatsEngine.summarize(games: [gameA, gameB], shots: shots)
        let season = StatsEngine.seasonStats(from: summaries)
        XCTAssertEqual(season.shotsFaced, 20)
        XCTAssertEqual(season.goals, 2)
        XCTAssertEqual(season.savePercentage, 0.9, accuracy: 0.0001)
    }

    func testTrendIsSortedByDateAscending() {
        let older = makeGame(daysAgo: 10)
        let newer = makeGame(daysAgo: 1)
        let summaries = StatsEngine.summarize(
            games: [newer, older],
            shots: [shot(gameID: older.id, outcome: .savedFrozen), shot(gameID: newer.id, outcome: .goal)]
        )
        let trend = StatsEngine.trend(from: summaries)
        XCTAssertEqual(trend.map(\.gameID), [older.id, newer.id])
    }

    // MARK: - Badges

    func testShutoutBadgeAndBackToBackRequireTwoConsecutiveShutouts() {
        let g1 = makeGame(daysAgo: 3)
        let g2 = makeGame(daysAgo: 2)
        let g3 = makeGame(daysAgo: 1)
        let shots = (0..<10).map { _ in shot(gameID: g1.id, outcome: .savedFrozen) }
            + (0..<10).map { i in shot(gameID: g2.id, outcome: i < 8 ? .savedFrozen : .goal) }
            + (0..<10).map { _ in shot(gameID: g3.id, outcome: .savedFrozen) }
        let summaries = StatsEngine.summarize(games: [g1, g2, g3], shots: shots)
        let badges = StatsEngine.badgesEarned(from: summaries)
        XCTAssertTrue(badges.contains(.shutout))
        XCTAssertFalse(badges.contains(.backToBackShutouts), "g2 breaks the streak, so back-to-back shouldn't fire.")
    }

    func testBackToBackShutoutsFireOnTwoConsecutiveCleanSheets() {
        let g1 = makeGame(daysAgo: 2)
        let g2 = makeGame(daysAgo: 1)
        let shots = (0..<10).map { _ in shot(gameID: g1.id, outcome: .savedFrozen) }
            + (0..<10).map { _ in shot(gameID: g2.id, outcome: .savedFrozen) }
        let summaries = StatsEngine.summarize(games: [g1, g2], shots: shots)
        let badges = StatsEngine.badgesEarned(from: summaries)
        XCTAssertTrue(badges.contains(.backToBackShutouts))
    }

    func testPerfectHighDangerBadgeRequiresThreeHighDangerShotsAllStopped() {
        let game = makeGame(daysAgo: 0)
        let shots = [
            shot(gameID: game.id, zone: .fiveHole, outcome: .savedFrozen),
            shot(gameID: game.id, zone: .lowGlove, outcome: .savedFrozen),
            shot(gameID: game.id, zone: .lowBlocker, outcome: .savedFrozen),
            shot(gameID: game.id, zone: .highCenter, outcome: .savedFrozen)
        ]
        let summaries = StatsEngine.summarize(games: [game], shots: shots)
        let badges = StatsEngine.badgesEarned(from: summaries)
        XCTAssertTrue(badges.contains(.perfectHighDangerGame))
    }

    func testIronWallSeasonNeedsFiveGamesAndHighSavePercentage() {
        let games = (0..<5).map { makeGame(daysAgo: $0) }
        let shots = games.flatMap { game in
            (0..<20).map { i in shot(gameID: game.id, outcome: i < 19 ? .savedFrozen : .goal) }
        }
        let summaries = StatsEngine.summarize(games: games, shots: shots)
        let badges = StatsEngine.badgesEarned(from: summaries)
        XCTAssertTrue(badges.contains(.ironWallSeason))
        XCTAssertFalse(badges.contains(.workhorseSeason), "Only 5 games played, workhorse needs 10.")
    }

    func testEmptyLogEarnsNoBadges() {
        XCTAssertTrue(StatsEngine.badgesEarned(from: []).isEmpty)
    }
}
