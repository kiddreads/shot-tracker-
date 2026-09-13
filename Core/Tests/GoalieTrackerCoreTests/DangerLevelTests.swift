import XCTest
@testable import GoalieTrackerCore

final class DangerLevelTests: XCTestCase {

    func testFiveHoleWristShotIsHighDangerFromZoneAlone() {
        let level = DangerLevel.compute(
            zone: .fiveHole,
            shotType: .wristShot,
            isRushOrOddMan: false,
            strengthState: .evenStrength
        )
        XCTAssertEqual(level, .high)
    }

    func testHighGloveWristShotIsLowDanger() {
        let level = DangerLevel.compute(
            zone: .highGlove,
            shotType: .wristShot,
            isRushOrOddMan: false,
            strengthState: .evenStrength
        )
        XCTAssertEqual(level, .low)
    }

    func testHighDangerShotTypeElevatesLowZoneToHigh() {
        // A one-timer to a normally "low danger" high corner is still dangerous.
        let level = DangerLevel.compute(
            zone: .highGlove,
            shotType: .oneTimer,
            isRushOrOddMan: false,
            strengthState: .evenStrength
        )
        XCTAssertEqual(level, .high)
    }

    func testRushNeverDowngradesDanger() {
        let level = DangerLevel.compute(
            zone: .fiveHole,
            shotType: .wristShot,
            isRushOrOddMan: true,
            strengthState: .evenStrength
        )
        XCTAssertEqual(level, .high, "A rush shot into the five-hole must stay high danger, not get averaged down.")
    }

    func testPowerPlayBumpsLowZoneToMediumButNotHigherZones() {
        let bumped = DangerLevel.compute(
            zone: .highCenter,
            shotType: .wristShot,
            isRushOrOddMan: false,
            strengthState: .powerPlayAgainst
        )
        XCTAssertEqual(bumped, .medium)

        let unaffected = DangerLevel.compute(
            zone: .midCenter,
            shotType: .wristShot,
            isRushOrOddMan: false,
            strengthState: .powerPlayAgainst
        )
        XCTAssertEqual(unaffected, .medium, "Medium-danger zone shouldn't be pushed to high just for being shorthanded.")
    }

    func testDangerLevelOrdering() {
        XCTAssertLessThan(DangerLevel.low, DangerLevel.medium)
        XCTAssertLessThan(DangerLevel.medium, DangerLevel.high)
    }

    func testAllNineZonesHaveDistinctGridPositions() {
        var seen = Set<String>()
        for zone in NetZone.allCases {
            let pos = zone.gridPosition
            let key = "\(pos.row)-\(pos.column)"
            XCTAssertFalse(seen.contains(key), "Duplicate grid position for \(zone)")
            seen.insert(key)
        }
        XCTAssertEqual(seen.count, 9)
    }
}
