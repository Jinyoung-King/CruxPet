import XCTest
@testable import CruxPet

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
        XCTAssertEqual(timer.timeRemaining, 25 * 60)
    }

    func testResetFromPausedGoesBackToIdle() {
        let timer = PomodoroTimer()
        timer.start()
        timer.pause()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
    }

    func testStartFromIdleIsNoOpIfAlreadyRunning() {
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
}
