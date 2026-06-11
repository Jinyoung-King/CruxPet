import Foundation
import Observation

struct Companion: Identifiable, Equatable {
    let id: String
    let name: String
    let bodyHex: String
    let emoji: String
}

@Observable
class CompanionModel {
    private(set) var unlockedIDs: Set<String> = []

    static let all: [Companion] = [
        Companion(id: "baby",  name: "아기 슬라임",  bodyHex: "#7EC8E3", emoji: "🐣"),
        Companion(id: "flame", name: "불꽃 슬라임", bodyHex: "#FF5722", emoji: "🔥"),
        Companion(id: "star",  name: "별빛 슬라임",  bodyHex: "#FFD700", emoji: "✨"),
        Companion(id: "night", name: "야왕 슬라임",  bodyHex: "#212121", emoji: "🌙"),
        Companion(id: "pomo",  name: "포모 슬라임",  bodyHex: "#E53935", emoji: "🍅"),
    ]

    var unlockedCompanions: [Companion] {
        CompanionModel.all.filter { unlockedIDs.contains($0.id) }
    }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "cruxpet.companions.unlocked") ?? []
        unlockedIDs = Set(saved)
    }

    /// 새로 달성된 친구를 반환하고 UserDefaults에 저장
    @discardableResult
    func checkUnlocks(level: Int, streakDays: Int, achievementCount: Int,
                      hasNightOwlCommit: Bool, totalPomodoroCount: Int) -> [Companion] {
        let newIDs = CompanionModel.newlyUnlockedIDs(
            level: level, streakDays: streakDays, achievementCount: achievementCount,
            hasNightOwlCommit: hasNightOwlCommit, totalPomodoroCount: totalPomodoroCount,
            alreadyUnlocked: unlockedIDs
        )
        guard !newIDs.isEmpty else { return [] }
        unlockedIDs.formUnion(newIDs)
        UserDefaults.standard.set(Array(unlockedIDs), forKey: "cruxpet.companions.unlocked")
        return CompanionModel.all.filter { newIDs.contains($0.id) }
    }

    static func newlyUnlockedIDs(
        level: Int, streakDays: Int, achievementCount: Int,
        hasNightOwlCommit: Bool, totalPomodoroCount: Int,
        alreadyUnlocked: Set<String>
    ) -> Set<String> {
        var result: Set<String> = []
        if level >= 10,              !alreadyUnlocked.contains("baby")  { result.insert("baby") }
        if streakDays >= 7,          !alreadyUnlocked.contains("flame") { result.insert("flame") }
        if achievementCount >= 5,    !alreadyUnlocked.contains("star")  { result.insert("star") }
        if hasNightOwlCommit,        !alreadyUnlocked.contains("night") { result.insert("night") }
        if totalPomodoroCount >= 20, !alreadyUnlocked.contains("pomo")  { result.insert("pomo") }
        return result
    }
}
