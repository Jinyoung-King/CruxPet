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

    // MARK: - isCompleted

    private func notCompleted(_ a: Achievement) -> Bool {
        !AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
    }

    func testIsCompleted_commit_notYet() {
        let a = AchievementModel.make(.commit(10))
        XCTAssertFalse(AchievementModel.isCompleted(a,
            totalCommitCount: 9, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0))
    }

    func testIsCompleted_commit_exact() {
        let a = AchievementModel.make(.commit(10))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 10, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0))
    }

    func testIsCompleted_nightOwl_false() {
        let a = AchievementModel.make(.special(.nightOwl))
        XCTAssertTrue(notCompleted(a))
    }

    func testIsCompleted_nightOwl_true() {
        let a = AchievementModel.make(.special(.nightOwl))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: true, todayCommitCount: 0, todayPomodoroCount: 0))
    }

    func testIsCompleted_sprinter_notYet() {
        let a = AchievementModel.make(.special(.sprinter))
        XCTAssertFalse(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 4, todayPomodoroCount: 0))
    }

    func testIsCompleted_sprinter_exact() {
        let a = AchievementModel.make(.special(.sprinter))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 5, todayPomodoroCount: 0))
    }

    func testIsCompleted_focusKing_notYet() {
        let a = AchievementModel.make(.special(.focusKing))
        XCTAssertFalse(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 2))
    }

    func testIsCompleted_focusKing_exact() {
        let a = AchievementModel.make(.special(.focusKing))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 3))
    }

    // MARK: - progress

    func testProgress_commit_partial() {
        let a = AchievementModel.make(.commit(10))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 7, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 7)
        XCTAssertEqual(total, 10)
    }

    func testProgress_commit_capped() {
        let a = AchievementModel.make(.commit(10))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 15, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 10)
        XCTAssertEqual(total, 10)
    }

    func testProgress_nightOwl_unclaimed() {
        let a = AchievementModel.make(.special(.nightOwl))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 0)
        XCTAssertEqual(total, 1)
    }

    func testProgress_nightOwl_claimed() {
        let a = AchievementModel.make(.special(.nightOwl))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: true, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 1)
        XCTAssertEqual(total, 1)
    }

    func testProgress_sprinter_partial() {
        let a = AchievementModel.make(.special(.sprinter))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 3, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 3)
        XCTAssertEqual(total, 5)
    }

    func testProgress_focusKing_partial() {
        let a = AchievementModel.make(.special(.focusKing))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 2)
        XCTAssertEqual(cur, 2)
        XCTAssertEqual(total, 3)
    }
}
