// CruxPet/AchievementModel.swift
import Foundation
import Observation

enum AchievementType {
    case commit(Int)
    case pomodoro(Int)
    case streak(Int)
    case level(Int)
    case questClear(Int)
    case special(SpecialKind)
}

enum SpecialKind: String {
    case nightOwl   // 자정(00:00~03:59) 커밋
    case sprinter   // 하루 커밋 5회
    case focusKing  // 하루 포모도로 3회
}

struct Achievement: Identifiable {
    let id: String
    let type: AchievementType
    let emoji: String
    let title: String
    let unlocksItemId: String? = nil
}

@Observable
class AchievementModel {
    private(set) var claimedIds: Set<String> = []

    var claimedCount: Int { claimedIds.count }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "cruxpet.achievements.claimedIds") ?? []
        claimedIds = Set(saved)
    }

    // MARK: - Milestone generators (static, 테스트 가능)

    static func commitMilestones(upTo count: Int) -> [Int] {
        generateMilestones(seed: [1, 10, 50, 100, 250, 500, 1000, 2500, 5000, 10000], upTo: count) { last in
            max(last + 1, Int((Double(last) * 2.5 / 100).rounded()) * 100)
        }
    }

    static func pomodoroMilestones(upTo count: Int) -> [Int] {
        generateMilestones(seed: [1, 10, 25, 50, 100, 250, 500, 1000], upTo: count) { last in
            max(last + 1, Int((Double(last) * 2.5 / 100).rounded()) * 100)
        }
    }

    static func streakMilestones(upTo days: Int) -> [Int] {
        generateMilestones(seed: [3, 7, 14, 30, 60, 100, 200, 365, 730], upTo: days) { $0 + 365 }
    }

    static func levelMilestones(upTo level: Int) -> [Int] {
        generateMilestones(seed: [10, 20, 30, 50, 75, 100], upTo: level) { $0 + 50 }
    }

    static func questClearMilestones(upTo count: Int) -> [Int] {
        generateMilestones(seed: [1, 7, 30, 100, 365], upTo: count) { $0 + 365 }
    }

    // 시드 이후 공식으로 연장. 결과: 달성한 마일스톤 전부 + 다음 미달성 1개
    private static func generateMilestones(seed: [Int], upTo count: Int, next: (Int) -> Int) -> [Int] {
        var result: [Int] = []
        for m in seed {
            result.append(m)
            if m > count { return result }
        }
        var last = seed.last!
        while true {
            last = next(last)
            result.append(last)
            if last > count { return result }
        }
    }

    // MARK: - Achievement factory

    static func make(_ type: AchievementType) -> Achievement {
        switch type {
        case .commit(let n):
            return Achievement(id: "commit_\(n)", type: type, emoji: "⚡", title: "커밋 \(n)회")
        case .pomodoro(let n):
            return Achievement(id: "pomodoro_\(n)", type: type, emoji: "🍅", title: "포모도로 \(n)회")
        case .streak(let n):
            return Achievement(id: "streak_\(n)", type: type, emoji: "🔥", title: "\(n)일 연속")
        case .level(let n):
            return Achievement(id: "level_\(n)", type: type, emoji: "⭐", title: "레벨 \(n) 달성")
        case .questClear(let n):
            return Achievement(id: "questclear_\(n)", type: type, emoji: "📋", title: "퀘스트 올클리어 \(n)회")
        case .special(let kind):
            switch kind {
            case .nightOwl:  return Achievement(id: "special_nightOwl",  type: type, emoji: "🌙", title: "밤샘 코더")
            case .sprinter:  return Achievement(id: "special_sprinter",   type: type, emoji: "⚡", title: "스프린터")
            case .focusKing: return Achievement(id: "special_focusKing",  type: type, emoji: "🎯", title: "집중왕")
            }
        }
    }
}
