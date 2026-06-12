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
@MainActor
class QuestModel {
    private(set) var todayQuests: [Quest] = []
    private var claimedIds: Set<String> = []

    var claimedCount: Int { claimedIds.count }

    init() {
        refreshIfNeeded()
    }

    func refreshIfNeeded() {
        let today = Self.todayString()
        let storedDate = UserDefaults.standard.string(forKey: "cruxpet.quest.claimedDate") ?? ""
        if storedDate != today {
            claimedIds = []
            UserDefaults.standard.set(today, forKey: "cruxpet.quest.claimedDate")
            UserDefaults.standard.set(false, forKey: "cruxpet.quest.allClearClaimed")
            UserDefaults.standard.removeObject(forKey: "cruxpet.quest.claimedIds")
        } else {
            let saved = UserDefaults.standard.stringArray(forKey: "cruxpet.quest.claimedIds") ?? []
            claimedIds = Set(saved)
        }
        todayQuests = Self.questsForDate(today)
    }

    @discardableResult
    func claimCompleted(pet: PetModel) -> Bool {
        var gained = false
        for quest in todayQuests {
            guard !claimedIds.contains(quest.id) else { continue }
            guard Self.isCompleted(quest,
                                   commitCount: pet.todayCommitCount,
                                   pomodoroCount: pet.todayPomodoroCount,
                                   streakDays: pet.streakDays) else { continue }
            claimedIds.insert(quest.id)
            pet.gainQuestExp(quest.expReward)
            gained = true
        }
        if gained {
            UserDefaults.standard.set(Array(claimedIds), forKey: "cruxpet.quest.claimedIds")
        }
        let allDone = todayQuests.allSatisfy { claimedIds.contains($0.id) }
        let alreadyClaimed = UserDefaults.standard.bool(forKey: "cruxpet.quest.allClearClaimed")
        if allDone && !alreadyClaimed {
            UserDefaults.standard.set(true, forKey: "cruxpet.quest.allClearClaimed")
            pet.gainQuestExp(100)
            pet.incrementQuestClear()
            return true
        }
        return false
    }

    func isCompleted(_ quest: Quest, pet: PetModel) -> Bool {
        Self.isCompleted(quest,
                         commitCount: pet.todayCommitCount,
                         pomodoroCount: pet.todayPomodoroCount,
                         streakDays: pet.streakDays)
    }

    func isClaimed(_ quest: Quest) -> Bool {
        claimedIds.contains(quest.id)
    }

    func progress(for quest: Quest, pet: PetModel) -> (current: Int, total: Int) {
        Self.progress(for: quest,
                      commitCount: pet.todayCommitCount,
                      pomodoroCount: pet.todayPomodoroCount,
                      streakDays: pet.streakDays)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayString() -> String {
        return dateFormatter.string(from: Date())
    }

    static let easyPool: [Quest] = [
        Quest(id: "commit_1",   type: .commit(1),   difficulty: .easy),
        Quest(id: "commit_2",   type: .commit(2),   difficulty: .easy),
        Quest(id: "pomodoro_1", type: .pomodoro(1), difficulty: .easy),
        Quest(id: "pomodoro_2", type: .pomodoro(2), difficulty: .easy),
        Quest(id: "combo_1_1",  type: .combo(1, 1), difficulty: .easy),
    ]

    static let hardPool: [Quest] = [
        Quest(id: "commit_5",   type: .commit(5),   difficulty: .hard),
        Quest(id: "pomodoro_3", type: .pomodoro(3), difficulty: .hard),
        Quest(id: "combo_3_1",  type: .combo(3, 1), difficulty: .hard),
        Quest(id: "combo_2_2",  type: .combo(2, 2), difficulty: .hard),
    ]

    static func questsForDate(_ dateString: String) -> [Quest] {
        let seed = dateString.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        let easy = Array(seededShuffle(easyPool, seed: seed).prefix(3))
        let hard = Array(seededShuffle(hardPool, seed: seed &+ 1).prefix(2))
        return easy + hard
    }

    static func seededShuffle(_ array: [Quest], seed: Int) -> [Quest] {
        var arr = array
        var state = seed
        for i in stride(from: arr.count - 1, through: 1, by: -1) {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let j = (state & Int.max) % (i + 1)
            arr.swapAt(i, j)
        }
        return arr
    }

    static func isCompleted(_ quest: Quest, commitCount: Int, pomodoroCount: Int, streakDays: Int) -> Bool {
        switch quest.type {
        case .commit(let n):        return commitCount >= n
        case .pomodoro(let n):      return pomodoroCount >= n
        case .combo(let c, let p):  return commitCount >= c && pomodoroCount >= p
        case .streak(let n):        return streakDays >= n
        }
    }

    static func progress(for quest: Quest, commitCount: Int, pomodoroCount: Int, streakDays: Int) -> (current: Int, total: Int) {
        switch quest.type {
        case .commit(let n):
            return (min(commitCount, n), n)
        case .pomodoro(let n):
            return (min(pomodoroCount, n), n)
        case .combo(let c, let p):
            return (min(commitCount, c) + min(pomodoroCount, p), c + p)
        case .streak(let n):
            return (min(streakDays, n), n)
        }
    }
}
