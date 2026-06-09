// CruxPetTests/AchievementModelTests.swift
import XCTest
@testable import CruxPet

final class AchievementModelTests: XCTestCase {

    // MARK: - commitMilestones

    func testCommitMilestones_atZero() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 0), [1])
    }

    func testCommitMilestones_at1() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 1), [1, 10])
    }

    func testCommitMilestones_at10() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 10), [1, 10, 50])
    }

    func testCommitMilestones_at99() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 99), [1, 10, 50, 100])
    }

    func testCommitMilestones_at100() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 100), [1, 10, 50, 100, 250])
    }

    func testCommitMilestones_nextIsFirstBeyondCount() {
        let m = AchievementModel.commitMilestones(upTo: 50)
        XCTAssertEqual(m.last, 100)
    }

    // MARK: - pomodoroMilestones

    func testPomodoroMilestones_atZero() {
        XCTAssertEqual(AchievementModel.pomodoroMilestones(upTo: 0), [1])
    }

    func testPomodoroMilestones_at25() {
        XCTAssertEqual(AchievementModel.pomodoroMilestones(upTo: 25), [1, 10, 25, 50])
    }

    // MARK: - streakMilestones

    func testStreakMilestones_atZero() {
        XCTAssertEqual(AchievementModel.streakMilestones(upTo: 0), [3])
    }

    func testStreakMilestones_at3() {
        XCTAssertEqual(AchievementModel.streakMilestones(upTo: 3), [3, 7])
    }

    func testStreakMilestones_at730() {
        let m = AchievementModel.streakMilestones(upTo: 730)
        XCTAssertTrue(m.contains(730))
        XCTAssertEqual(m.last, 1095) // 730 + 365
    }

    // MARK: - levelMilestones

    func testLevelMilestones_atZero() {
        XCTAssertEqual(AchievementModel.levelMilestones(upTo: 0), [10])
    }

    func testLevelMilestones_at100() {
        let m = AchievementModel.levelMilestones(upTo: 100)
        XCTAssertTrue(m.contains(100))
        XCTAssertEqual(m.last, 150)
    }

    // MARK: - questClearMilestones

    func testQuestClearMilestones_atZero() {
        XCTAssertEqual(AchievementModel.questClearMilestones(upTo: 0), [1])
    }

    func testQuestClearMilestones_at365() {
        let m = AchievementModel.questClearMilestones(upTo: 365)
        XCTAssertTrue(m.contains(365))
        XCTAssertEqual(m.last, 730)
    }

    // MARK: - make() factory

    func testMake_commit10_id() {
        XCTAssertEqual(AchievementModel.make(.commit(10)).id, "commit_10")
    }

    func testMake_pomodoro50_id() {
        XCTAssertEqual(AchievementModel.make(.pomodoro(50)).id, "pomodoro_50")
    }

    func testMake_streak30_id() {
        XCTAssertEqual(AchievementModel.make(.streak(30)).id, "streak_30")
    }

    func testMake_level20_id() {
        XCTAssertEqual(AchievementModel.make(.level(20)).id, "level_20")
    }

    func testMake_questClear7_id() {
        XCTAssertEqual(AchievementModel.make(.questClear(7)).id, "questclear_7")
    }

    func testMake_nightOwl_id() {
        XCTAssertEqual(AchievementModel.make(.special(.nightOwl)).id, "special_nightOwl")
    }

    func testMake_sprinter_id() {
        XCTAssertEqual(AchievementModel.make(.special(.sprinter)).id, "special_sprinter")
    }

    func testMake_focusKing_id() {
        XCTAssertEqual(AchievementModel.make(.special(.focusKing)).id, "special_focusKing")
    }
}
