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
}
