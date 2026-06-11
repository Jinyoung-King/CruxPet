import XCTest
@testable import CruxPet

final class CompanionModelTests: XCTestCase {

    func testBabyUnlocksAtLevel10() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 10, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("baby"))
    }

    func testBabyDoesNotUnlockBeforeLevel10() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 9, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertFalse(result.contains("baby"))
    }

    func testFlameUnlocksAtStreak7() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 7, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("flame"))
    }

    func testStarUnlocksAt5Achievements() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, claimedAchievementCount: 5,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("star"))
    }

    func testNightUnlocksWithNightOwlCommit() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: true, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("night"))
    }

    func testPomoUnlocksAt20Pomodoros() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 20,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("pomo"))
    }

    func testAlreadyUnlockedNotReturned() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 10, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: ["baby"]
        )
        XCTAssertFalse(result.contains("baby"))
    }

    func testNoConditionsMetReturnsEmpty() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testFlameDoesNotUnlockBeforeStreak7() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 6, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertFalse(result.contains("flame"))
    }

    func testStarDoesNotUnlockAt4Achievements() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, claimedAchievementCount: 4,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertFalse(result.contains("star"))
    }

    func testPomoDoesNotUnlockAt19Pomodoros() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, claimedAchievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 19,
            alreadyUnlocked: []
        )
        XCTAssertFalse(result.contains("pomo"))
    }
}
