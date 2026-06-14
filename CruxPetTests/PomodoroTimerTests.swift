import XCTest
@testable import CruxPet

@MainActor
final class PomodoroTimerTests: XCTestCase {

    func testInitialStateIsIdle() {
        let timer = PomodoroTimer()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.timeRemaining, 25 * 60)
    }

    func testStartTransitionsToRunning() {
        let timer = PomodoroTimer()
        timer.start()
        XCTAssertEqual(timer.state, .running)
    }

    func testPauseTransitionsToPaused() {
        let timer = PomodoroTimer()
        timer.start()
        timer.pause()
        XCTAssertEqual(timer.state, .paused)
    }

    func testResumeFromPausedTransitionsToRunning() {
        let timer = PomodoroTimer()
        timer.start()
        timer.pause()
        timer.resume()
        XCTAssertEqual(timer.state, .running)
    }

    func testResetFromRunningGoesBackToIdle() {
        let timer = PomodoroTimer()
        timer.start()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.timeRemaining, timer.duration)
    }

    func testResetFromPausedGoesBackToIdle() {
        let timer = PomodoroTimer()
        timer.start()
        timer.pause()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.timeRemaining, timer.duration)
    }

    func testDoubleStartIsNoOp() {
        let timer = PomodoroTimer()
        timer.start()
        timer.start()  // 두 번 start해도 running 유지
        XCTAssertEqual(timer.state, .running)
    }

    func testDisplayTime() {
        let timer = PomodoroTimer()
        // 25:00 표시
        XCTAssertEqual(timer.displayTime, "25:00")
    }

    func testOnCompleteCallbackCanBeSet() {
        let timer = PomodoroTimer()
        var called = false
        timer.onComplete = { called = true }
        XCTAssertNotNil(timer.onComplete)
    }

    func testSetDurationUpdatesTimeRemaining() {
        let timer = PomodoroTimer()
        timer.setDuration(15)
        XCTAssertEqual(timer.timeRemaining, 15 * 60)
        XCTAssertEqual(timer.state, .idle)
    }

    func testResetUsesCurrentDuration() {
        let timer = PomodoroTimer()
        timer.setDuration(50)
        timer.start()
        timer.reset()
        XCTAssertEqual(timer.timeRemaining, 50 * 60)
    }

    // MARK: - Break timer

    func testSessionCountInitiallyZero() {
        let timer = PomodoroTimer()
        XCTAssertEqual(timer.sessionCount, 0)
    }

    func testCompleteForTestingIncrementsSessionCount() {
        let timer = PomodoroTimer()
        timer.completeForTesting()
        XCTAssertEqual(timer.sessionCount, 1)
    }

    func testCompleteForTestingSetsCompletedState() {
        let timer = PomodoroTimer()
        timer.completeForTesting()
        XCTAssertEqual(timer.state, .completed)
    }

    func testStartBreakTransitionsToShortBreak() {
        let timer = PomodoroTimer()
        timer.completeForTesting()   // sessionCount = 1, state = .completed
        timer.startBreak()
        XCTAssertEqual(timer.state, .shortBreak)
    }

    func testStartBreakTransitionsToShortBreakAtSession1() {
        let timer = PomodoroTimer()
        timer.completeForTesting()   // sessionCount = 1
        timer.startBreak()
        XCTAssertEqual(timer.state, .shortBreak, "session 1 must be short break, not long")
    }

    func testStartBreakTransitionsToLongBreakAtSession4() {
        let timer = PomodoroTimer()
        timer.completeForTesting()   // 1
        timer.completeForTesting()   // 2
        timer.completeForTesting()   // 3
        timer.completeForTesting()   // 4 → longBreak threshold
        timer.startBreak()
        XCTAssertEqual(timer.state, .longBreak)
    }

    func testStartBreakSetsShortBreakTimeRemaining() {
        let timer = PomodoroTimer()
        timer.completeForTesting()
        timer.startBreak()
        XCTAssertEqual(timer.timeRemaining, 5 * 60)
    }

    func testStartBreakSetsLongBreakTimeRemaining() {
        let timer = PomodoroTimer()
        for _ in 0..<4 { timer.completeForTesting() }
        timer.startBreak()
        XCTAssertEqual(timer.timeRemaining, 15 * 60)
    }

    func testStartBreakIsNoOpFromIdle() {
        let timer = PomodoroTimer()
        timer.startBreak()
        XCTAssertEqual(timer.state, .idle)
    }

    func testSkipBreakResetsToIdle() {
        let timer = PomodoroTimer()
        timer.completeForTesting()
        timer.startBreak()
        timer.skipBreak()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.timeRemaining, timer.duration)
    }

    func testSkipBreakPreservesSessionCount() {
        let timer = PomodoroTimer()
        timer.completeForTesting()
        timer.startBreak()
        timer.skipBreak()
        XCTAssertEqual(timer.sessionCount, 1)
    }

    func testResetClearsSessionCount() {
        let timer = PomodoroTimer()
        timer.completeForTesting()
        timer.reset()
        XCTAssertEqual(timer.sessionCount, 0)
    }

    func testBreakCompleteCallbackCanBeSet() {
        let timer = PomodoroTimer()
        timer.breakComplete = {}
        XCTAssertNotNil(timer.breakComplete)
    }
}
