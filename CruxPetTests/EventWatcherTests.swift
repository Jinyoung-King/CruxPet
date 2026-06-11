import XCTest
@testable import CruxPet

final class EventWatcherTests: XCTestCase {

    func testParseEmptyLines() {
        let events = EventWatcher.parseLines("")
        XCTAssertTrue(events.isEmpty)
    }

    func testParseSingleCommitEvent() {
        let line = #"{"type":"commit","timestamp":1780634297}"#
        let events = EventWatcher.parseLines(line)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].type, "commit")
        XCTAssertEqual(events[0].timestamp, 1780634297)
    }

    func testParseSinglePomodoroEvent() {
        let line = #"{"type":"pomodoro","timestamp":1780637000}"#
        let events = EventWatcher.parseLines(line)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].type, "pomodoro")
    }

    func testParseMultipleLines() {
        let lines = """
        {"type":"commit","timestamp":100}
        {"type":"pomodoro","timestamp":200}
        {"type":"commit","timestamp":300}
        """
        let events = EventWatcher.parseLines(lines)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[2].timestamp, 300)
    }

    func testSkipMalformedLines() {
        let lines = """
        {"type":"commit","timestamp":100}
        this is not json
        {"type":"pomodoro","timestamp":200}
        """
        let events = EventWatcher.parseLines(lines)
        XCTAssertEqual(events.count, 2)
    }

    func testFilterByLastProcessed() {
        let lines = """
        {"type":"commit","timestamp":100}
        {"type":"commit","timestamp":200}
        {"type":"commit","timestamp":300}
        """
        let all = EventWatcher.parseLines(lines)
        let fresh = EventWatcher.filterNew(events: all, after: 150)
        XCTAssertEqual(fresh.count, 2)
        XCTAssertEqual(fresh[0].timestamp, 200)
    }

    // MARK: - activityDays

    func testActivityDays_emptyContent() {
        let days = EventWatcher.activityDays(from: "", last: 7, relativeTo: Date())
        XCTAssertTrue(days.isEmpty)
    }

    func testActivityDays_todayEventIncluded() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
        let ref = Calendar.current.date(from: comps)!
        let ts = Int(ref.timeIntervalSince1970)
        let content = "{\"type\":\"commit\",\"timestamp\":\(ts)}"
        let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        XCTAssertTrue(days.contains(fmt.string(from: ref)))
    }

    func testActivityDays_sixDaysAgoIncluded() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
        let ref = Calendar.current.date(from: comps)!
        let sixDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: ref)!
        let ts = Int(sixDaysAgo.timeIntervalSince1970)
        let content = "{\"type\":\"commit\",\"timestamp\":\(ts)}"
        let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        XCTAssertTrue(days.contains(fmt.string(from: sixDaysAgo)))
    }

    func testActivityDays_sevenDaysAgoExcluded() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
        let ref = Calendar.current.date(from: comps)!
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: ref)!
        let ts = Int(sevenDaysAgo.timeIntervalSince1970)
        let content = "{\"type\":\"commit\",\"timestamp\":\(ts)}"
        let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
        XCTAssertTrue(days.isEmpty)
    }

    func testActivityDays_multipleEventsOnSameDay() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
        let ref = Calendar.current.date(from: comps)!
        let ts = Int(ref.timeIntervalSince1970)
        let content = """
        {"type":"commit","timestamp":\(ts)}
        {"type":"pomodoro","timestamp":\(ts + 3600)}
        """
        let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
        XCTAssertEqual(days.count, 1)
    }
}
