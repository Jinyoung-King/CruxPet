// CruxPet/ActivityHistoryModel.swift
import Foundation
import Observation

struct DailyActivity: Codable {
    let dateString: String  // "yyyy-MM-dd"
    let commits: Int
    let pomodoros: Int
}

@Observable
class ActivityHistoryModel {
    private(set) var entries: [DailyActivity] = []

    private static let storageKey = "cruxpet.activityHistory"
    private static let todayDateKey = "cruxpet.todayDate"
    private static let commitCountKey = "cruxpet.commitCount"
    private static let pomodoroCountKey = "cruxpet.pomodoroCount"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        loadEntries()
        captureYesterdayIfNeeded()
    }

    // 지난 7일 데이터 반환 (오늘은 인자로 받은 실시간 값 사용)
    func last7Days(todayCommits: Int, todayPomodoros: Int) -> [DailyActivity] {
        let today = Self.dateString(from: Date())
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset -> DailyActivity in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let ds = Self.dateString(from: date)
            if ds == today {
                return DailyActivity(dateString: ds, commits: todayCommits, pomodoros: todayPomodoros)
            }
            return entries.first(where: { $0.dateString == ds })
                ?? DailyActivity(dateString: ds, commits: 0, pomodoros: 0)
        }
    }

    func record(commits: Int, pomodoros: Int, for dateString: String) {
        guard !entries.contains(where: { $0.dateString == dateString }) else { return }
        var updated = entries + [DailyActivity(dateString: dateString, commits: commits, pomodoros: pomodoros)]
        updated.sort { $0.dateString < $1.dateString }
        entries = Array(updated.suffix(30))
        saveEntries()
    }

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    // PetModel이 init()에서 리셋하기 전에 어제 데이터를 UserDefaults에서 읽음.
    // CruxPetApp에서 history가 pet보다 먼저 선언되어야 이 타이밍이 보장됨.
    private func captureYesterdayIfNeeded() {
        let today = Self.dateString(from: Date())
        let storedDate = UserDefaults.standard.string(forKey: Self.todayDateKey) ?? ""
        guard !storedDate.isEmpty, storedDate < today else { return }
        guard !entries.contains(where: { $0.dateString == storedDate }) else { return }
        let commits = UserDefaults.standard.integer(forKey: Self.commitCountKey)
        let pomodoros = UserDefaults.standard.integer(forKey: Self.pomodoroCountKey)
        record(commits: commits, pomodoros: pomodoros, for: storedDate)
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([DailyActivity].self, from: data)
        else { return }
        entries = decoded
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    // MARK: - Test helpers

    #if DEBUG
    func clearAllForTesting() {
        entries = []
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
    #endif
}
