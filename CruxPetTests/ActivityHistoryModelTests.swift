// CruxPetTests/ActivityHistoryModelTests.swift
import XCTest
@testable import CruxPet

final class ActivityHistoryModelTests: XCTestCase {

    // last7Days: 이력 없을 때 7개 항목 모두 0 반환
    func testLast7DaysEmptyHistory() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        let days = model.last7Days(todayCommits: 0, todayPomodoros: 0)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(days.allSatisfy { $0.commits == 0 && $0.pomodoros == 0 })
    }

    // last7Days: 오늘 값은 todayCommits/todayPomodoros 인자로 채워짐
    func testLast7DaysTodayFromArguments() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        let days = model.last7Days(todayCommits: 5, todayPomodoros: 3)
        XCTAssertEqual(days.last?.commits, 5)
        XCTAssertEqual(days.last?.pomodoros, 3)
    }

    // record: 같은 날짜 중복 저장 안 함
    func testRecordNoDuplicates() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        model.record(commits: 3, pomodoros: 1, for: "2026-06-10")
        model.record(commits: 9, pomodoros: 9, for: "2026-06-10")
        let entry = model.entries.first(where: { $0.dateString == "2026-06-10" })
        XCTAssertEqual(entry?.commits, 3)
    }

    // record: 30개 초과 시 가장 오래된 항목 제거
    func testRecordMaxEntries() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        for i in 1...31 {
            let date = String(format: "2026-01-%02d", i)
            model.record(commits: i, pomodoros: 0, for: date)
        }
        XCTAssertEqual(model.entries.count, 30)
        XCTAssertNil(model.entries.first(where: { $0.dateString == "2026-01-01" }))
    }

    // last7Days: 기록된 날짜가 7일 범위 내에 있으면 포함됨
    func testLast7DaysIncludesRecentEntry() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        let yesterday = ActivityHistoryModel.dateString(
            from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        model.record(commits: 7, pomodoros: 2, for: yesterday)
        let days = model.last7Days(todayCommits: 0, todayPomodoros: 0)
        let found = days.first(where: { $0.dateString == yesterday })
        XCTAssertEqual(found?.commits, 7)
    }
}
