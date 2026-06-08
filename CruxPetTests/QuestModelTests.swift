import XCTest
@testable import CruxPet

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
        XCTAssertEqual(QuestModel.easyPool.count, 6)
    }

    func testHardPoolCount() {
        XCTAssertEqual(QuestModel.hardPool.count, 5)
    }

    func testPoolIdsAreUnique() {
        let allIds = (QuestModel.easyPool + QuestModel.hardPool).map(\.id)
        XCTAssertEqual(allIds.count, Set(allIds).count)
    }
}
