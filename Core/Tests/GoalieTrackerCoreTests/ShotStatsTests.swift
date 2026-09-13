import XCTest
@testable import GoalieTrackerCore

final class ShotStatsTests: XCTestCase {
    private let gameID = UUID()
    private let goalieID = UUID()

    private func shot(
        zone: NetZone = .midCenter,
        shotType: ShotType = .wristShot,
        outcome: ShotOutcome,
        strength: StrengthState = .evenStrength,
        rush: Bool = false
    ) -> ShotEvent {
        ShotEvent(
            gameID: gameID,
            goalieID: goalieID,
            zone: zone,
            shotType: shotType,
            outcome: outcome,
            strengthState: strength,
            isRushOrOddMan: rush
        )
    }

    func testSavePercentageBasicMath() {
        let shots = [
            shot(outcome: .savedFrozen),
            shot(outcome: .savedFrozen),
            shot(outcome: .savedRebound),
            shot(outcome: .goal)
        ]
        let stats = ShotStats.compute(from: shots)
        XCTAssertEqual(stats.shotsFaced, 4)
        XCTAssertEqual(stats.saves, 3)
        XCTAssertEqual(stats.goals, 1)
        XCTAssertEqual(stats.savePercentage, 0.75, accuracy: 0.0001)
    }

    func testZeroShotsProducesZeroNotNaN() {
        let stats = ShotStats.compute(from: [])
        XCTAssertEqual(stats.shotsFaced, 0)
        XCTAssertEqual(stats.savePercentage, 0)
    }

    func testMissedAndBlockedShotsDoNotCountAsShotsOnGoal() {
        let shots = [
            shot(outcome: .missedNet),
            shot(outcome: .blockedShot),
            shot(outcome: .postOrCrossbar),
            shot(outcome: .savedFrozen)
        ]
        let stats = ShotStats.compute(from: shots)
        XCTAssertEqual(stats.shotsFaced, 1)
        XCTAssertEqual(stats.saves, 1)
    }

    func testGoalOnReboundCountsAsGoalAndShotOnGoal() {
        let shots = [shot(outcome: .goalOnRebound)]
        let stats = ShotStats.compute(from: shots)
        XCTAssertEqual(stats.shotsFaced, 1)
        XCTAssertEqual(stats.goals, 1)
        XCTAssertEqual(stats.saves, 0)
    }

    func testAggregateSumsRawCountsRatherThanAveragingPercentages() {
        // 1/1 in game A (100%) and 0/9 in game B (0%) must NOT average to 50%.
        let gameA = ShotStats(shotsFaced: 1, saves: 1, goals: 0, savePercentage: 1.0)
        let gameB = ShotStats(shotsFaced: 9, saves: 0, goals: 9, savePercentage: 0.0)
        let combined = ShotStats.aggregate([gameA, gameB])
        XCTAssertEqual(combined.shotsFaced, 10)
        XCTAssertEqual(combined.saves, 1)
        XCTAssertEqual(combined.savePercentage, 0.1, accuracy: 0.0001)
    }
}
