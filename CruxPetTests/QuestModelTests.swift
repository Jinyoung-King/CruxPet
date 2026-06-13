import XCTest
@testable import CruxPet

@MainActor
final class QuestModelTests: XCTestCase {

    func testQuestDescription_commit1() {
        let q = Quest(id: "commit_1", type: .commit(1), difficulty: .easy)
        XCTAssertEqual(q.description, "커밋 1회")
    }

    func testQuestDescription_pomodoro3() {
        let q = Quest(id: "pomodoro_3", type: .pomodoro(3), difficulty: .hard)
        XCTAssertEqual(q.description, "포모도로 3회")
    }

    func testQuestDescription_combo3_1() {
        let q = Quest(id: "combo_3_1", type: .combo(3, 1), difficulty: .hard)
        XCTAssertEqual(q.description, "커밋 3회 + 포모도로 1회")
    }

    func testQuestDescription_streak7() {
        let q = Quest(id: "streak_7", type: .streak(7), difficulty: .hard)
        XCTAssertEqual(q.description, "7일 이상 연속 활동")
    }

    func testQuestExpReward_easy() {
        let q = Quest(id: "commit_1", type: .commit(1), difficulty: .easy)
        XCTAssertEqual(q.expReward, 30)
    }

    func testQuestExpReward_hard() {
        let q = Quest(id: "commit_5", type: .commit(5), difficulty: .hard)
        XCTAssertEqual(q.expReward, 80)
    }

    func testEasyPoolCount() {
        XCTAssertEqual(QuestModel.easyPool.count, 5)
    }

    func testHardPoolCount() {
        XCTAssertEqual(QuestModel.hardPool.count, 4)
    }

    func testPoolIdsAreUnique() {
        let allIds = (QuestModel.easyPool + QuestModel.hardPool).map(\.id)
        XCTAssertEqual(allIds.count, Set(allIds).count)
    }

    func testQuestsForDate_returns5() {
        let quests = QuestModel.questsForDate("2026-06-08")
        XCTAssertEqual(quests.count, 5)
    }

    func testQuestsForDate_3Easy2Hard() {
        let quests = QuestModel.questsForDate("2026-06-08")
        XCTAssertEqual(quests.filter { $0.difficulty == .easy }.count, 3)
        XCTAssertEqual(quests.filter { $0.difficulty == .hard }.count, 2)
    }

    func testQuestsForDate_isDeterministic() {
        let a = QuestModel.questsForDate("2026-06-08")
        let b = QuestModel.questsForDate("2026-06-08")
        XCTAssertEqual(a.map(\.id), b.map(\.id))
    }

    func testQuestsForDate_differentDates() {
        let a = QuestModel.questsForDate("2026-06-08").map(\.id)
        let b = QuestModel.questsForDate("2026-06-09").map(\.id)
        XCTAssertNotEqual(a, b)
    }

    func testSeededShuffle_isDeterministic() {
        let a = QuestModel.seededShuffle(QuestModel.easyPool, seed: 42)
        let b = QuestModel.seededShuffle(QuestModel.easyPool, seed: 42)
        XCTAssertEqual(a.map(\.id), b.map(\.id))
    }

    func testSeededShuffle_differentSeed() {
        let a = QuestModel.seededShuffle(QuestModel.easyPool, seed: 42)
        let b = QuestModel.seededShuffle(QuestModel.easyPool, seed: 99)
        XCTAssertNotEqual(a.map(\.id), b.map(\.id))
    }

    func testQuestsForDate_idsAreUnique() {
        let quests = QuestModel.questsForDate("2026-06-08")
        let ids = quests.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testIsCompleted_commit_met() {
        let q = Quest(id: "commit_2", type: .commit(2), difficulty: .easy)
        XCTAssertTrue(QuestModel.isCompleted(q, commitCount: 2, pomodoroCount: 0, streakDays: 0))
    }

    func testIsCompleted_commit_notMet() {
        let q = Quest(id: "commit_2", type: .commit(2), difficulty: .easy)
        XCTAssertFalse(QuestModel.isCompleted(q, commitCount: 1, pomodoroCount: 0, streakDays: 0))
    }

    func testIsCompleted_combo_bothRequired() {
        let q = Quest(id: "combo_2_2", type: .combo(2, 2), difficulty: .hard)
        XCTAssertFalse(QuestModel.isCompleted(q, commitCount: 2, pomodoroCount: 1, streakDays: 0))
        XCTAssertTrue(QuestModel.isCompleted(q,  commitCount: 2, pomodoroCount: 2, streakDays: 0))
    }

    func testIsCompleted_streak() {
        let q = Quest(id: "streak_7", type: .streak(7), difficulty: .hard)
        XCTAssertFalse(QuestModel.isCompleted(q, commitCount: 0, pomodoroCount: 0, streakDays: 6))
        XCTAssertTrue(QuestModel.isCompleted(q,  commitCount: 0, pomodoroCount: 0, streakDays: 7))
    }

    func testProgress_commit() {
        let q = Quest(id: "commit_2", type: .commit(2), difficulty: .easy)
        let (cur, total) = QuestModel.progress(for: q, commitCount: 1, pomodoroCount: 0, streakDays: 0)
        XCTAssertEqual(cur, 1)
        XCTAssertEqual(total, 2)
    }

    func testProgress_combo() {
        let q = Quest(id: "combo_2_2", type: .combo(2, 2), difficulty: .hard)
        let (cur, total) = QuestModel.progress(for: q, commitCount: 1, pomodoroCount: 2, streakDays: 0)
        XCTAssertEqual(cur, 3)   // min(1,2) + min(2,2) = 1 + 2 = 3
        XCTAssertEqual(total, 4) // 2 + 2 = 4
    }

    func testProgress_doesNotExceedTotal() {
        let q = Quest(id: "commit_2", type: .commit(2), difficulty: .easy)
        let (cur, total) = QuestModel.progress(for: q, commitCount: 99, pomodoroCount: 0, streakDays: 0)
        XCTAssertLessThanOrEqual(cur, total)
    }
}
