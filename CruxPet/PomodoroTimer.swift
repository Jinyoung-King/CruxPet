import Foundation
import Observation

enum PomodoroState: Equatable {
    case idle, running, paused, completed, shortBreak, longBreak
}

@MainActor @Observable
class PomodoroTimer {
    private(set) var state: PomodoroState = .idle
    private(set) var duration: TimeInterval = 25 * 60
    private(set) var timeRemaining: TimeInterval = 25 * 60
    private(set) var sessionCount: Int = 0

    let shortBreakDuration: TimeInterval = 5 * 60
    let longBreakDuration: TimeInterval = 15 * 60

    var displayTime: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var onComplete: (() -> Void)?
    var breakComplete: (() -> Void)?

    private var timer: Timer?

    func start() {
        guard state == .idle else { return }
        state = .running
        scheduleFocusTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        scheduleFocusTimer()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = duration
        sessionCount = 0
    }

    func setDuration(_ minutes: Int) {
        duration = TimeInterval(minutes * 60)
        reset()
    }

    func startBreak() {
        guard state == .completed else { return }
        if sessionCount > 0 && sessionCount % 4 == 0 {
            timeRemaining = longBreakDuration
            state = .longBreak
        } else {
            timeRemaining = shortBreakDuration
            state = .shortBreak
        }
        scheduleBreakTimer()
    }

    func skipBreak() {
        guard state == .shortBreak || state == .longBreak else { return }
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = duration
    }

    // For unit testing — simulates the focus countdown reaching zero.
    func completeForTesting() {
        timer?.invalidate()
        timer = nil
        sessionCount += 1
        state = .completed
        onComplete?()
    }

    @MainActor
    private func scheduleFocusTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.sessionCount += 1
                self.state = .completed
                self.onComplete?()
            }
        }
    }

    @MainActor
    private func scheduleBreakTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.state = .idle
                self.timeRemaining = self.duration
                self.breakComplete?()
            }
        }
    }
}
