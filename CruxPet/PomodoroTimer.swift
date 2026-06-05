import Foundation
import Observation

enum PomodoroState: Equatable {
    case idle, running, paused, completed
}

@MainActor @Observable
class PomodoroTimer {
    private(set) var state: PomodoroState = .idle
    private(set) var timeRemaining: TimeInterval = 25 * 60

    var displayTime: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var onComplete: (() -> Void)?

    private var timer: Timer?

    func start() {
        guard state == .idle else { return }
        state = .running
        scheduleTimer()
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
        scheduleTimer()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = 25 * 60
    }

    @MainActor
    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.state = .completed
                self.onComplete?()
            }
        }
    }
}
