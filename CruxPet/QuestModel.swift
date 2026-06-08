import Foundation
import Observation

enum QuestDifficulty {
    case easy, hard
}

enum QuestType {
    case commit(Int)
    case pomodoro(Int)
    case combo(Int, Int)
    case streak(Int)
}

struct Quest: Identifiable {
    let id: String
    let type: QuestType
    let difficulty: QuestDifficulty

    var expReward: Int { difficulty == .easy ? 30 : 80 }

    var description: String {
        switch type {
        case .commit(let n):        return "커밋 \(n)회"
        case .pomodoro(let n):      return "포모도로 \(n)회"
        case .combo(let c, let p):  return "커밋 \(c)회 + 포모도로 \(p)회"
        case .streak(let n):        return "\(n)일 이상 연속 활동"
        }
    }
}

@Observable
class QuestModel {
    private(set) var todayQuests: [Quest] = []
    private var claimedIds: Set<String> = []

    var claimedCount: Int { claimedIds.count }

    // MARK: - Static Pure Logic

    static let easyPool: [Quest] = [
        Quest(id: "commit_1",   type: .commit(1),   difficulty: .easy),
        Quest(id: "commit_2",   type: .commit(2),   difficulty: .easy),
        Quest(id: "pomodoro_1", type: .pomodoro(1), difficulty: .easy),
        Quest(id: "pomodoro_2", type: .pomodoro(2), difficulty: .easy),
        Quest(id: "combo_1_1",  type: .combo(1, 1), difficulty: .easy),
        Quest(id: "streak_3",   type: .streak(3),   difficulty: .easy),
    ]

    static let hardPool: [Quest] = [
        Quest(id: "commit_5",   type: .commit(5),   difficulty: .hard),
        Quest(id: "pomodoro_3", type: .pomodoro(3), difficulty: .hard),
        Quest(id: "combo_3_1",  type: .combo(3, 1), difficulty: .hard),
        Quest(id: "combo_2_2",  type: .combo(2, 2), difficulty: .hard),
        Quest(id: "streak_7",   type: .streak(7),   difficulty: .hard),
    ]
}
