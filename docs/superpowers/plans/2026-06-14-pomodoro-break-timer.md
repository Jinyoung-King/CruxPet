# Pomodoro Break Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add manual break timer support to the pomodoro feature — after focus ends the user taps "휴식 시작", gets a 5-min or 15-min countdown (every 4th session triggers the long break), and receives a "집중 시작!" notification when the break ends.

**Architecture:** Extend `PomodoroState` with `.shortBreak`/`.longBreak`; add `sessionCount`, `startBreak()`, `skipBreak()`, and `breakComplete` callback to `PomodoroTimer`; add an internal `completeForTesting()` helper for unit tests; update `pomodoroSection` in `ContentView` for the new states; wire `breakComplete` notification in `CruxPetApp`.

**Tech Stack:** SwiftUI, `@Observable`, `Timer`, `UNUserNotificationCenter`, XCTest

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `CruxPet/PomodoroTimer.swift` | Modify | New enum cases, sessionCount, startBreak/skipBreak, breakComplete |
| `CruxPet/ContentView.swift` | Modify | pomodoroSection: session counter, state-aware header/buttons |
| `CruxPet/CruxPetApp.swift` | Modify | Wire breakComplete → sendBreakCompleteNotification |
| `CruxPetTests/PomodoroTimerTests.swift` | Modify | Add tests for sessionCount, startBreak, skipBreak, reset |

---

### Task 1: PomodoroTimer additions

**Files:**
- Modify: `CruxPet/PomodoroTimer.swift`
- Modify: `CruxPetTests/PomodoroTimerTests.swift`

- [ ] **Step 1: Write the failing tests**

Add at the bottom of `PomodoroTimerTests` class (before the closing `}`):

```swift
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
```

- [ ] **Step 2: Run tests to confirm build failure**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing CruxPetTests/PomodoroTimerTests 2>&1 | grep -E "error:|FAILED|PASSED"
```

Expected: compile error — `sessionCount`, `completeForTesting()`, `startBreak()`, `skipBreak()`, `breakComplete` do not exist.

- [ ] **Step 3: Replace `CruxPet/PomodoroTimer.swift` with the full updated implementation**

```swift
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
        if sessionCount % 4 == 0 {
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
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing CruxPetTests/PomodoroTimerTests 2>&1 | grep -E "Test Suite|PASSED|FAILED"
```

Expected: `Test Suite 'PomodoroTimerTests' passed`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/PomodoroTimer.swift CruxPetTests/PomodoroTimerTests.swift
git commit -m "feat: add break timer support to PomodoroTimer"
```

---

### Task 2: ContentView pomodoroSection

**Files:**
- Modify: `CruxPet/ContentView.swift`

No unit tests — verified by build.

- [ ] **Step 1: Replace `pomodoroSection` in `CruxPet/ContentView.swift`**

Find (lines 620–678):
```swift
    private var pomodoroSection: some View {
        let isRunning = pomodoro.state == .running
        let accent: Color = isRunning ? .orange : .blue
        return VStack(spacing: 7) {
            HStack(spacing: 4) {
                Image(systemName: isRunning ? "flame.fill" : "timer")
                    .font(.caption)
                    .foregroundStyle(isRunning ? .orange : .secondary)
                Text(isRunning ? "집중 중" : "포모도로")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isRunning ? .orange : .secondary)
                PomodoroInfoButton()
            }
            Text(pomodoro.displayTime)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(isRunning ? .primary : .secondary)
                .animation(.none, value: pomodoro.displayTime)
            HStack(spacing: 8) {
                Group {
                    switch pomodoro.state {
                    case .idle:
                        Button("▶  시작") { pomodoro.start() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    case .running:
                        Button("⏸  일시정지") { pomodoro.pause() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .paused:
                        Button("▶  계속") { pomodoro.resume() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .completed:
                        Button("↺  다시") { pomodoro.reset() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(accent.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: isRunning)
    }
```

Replace with:
```swift
    private var pomodoroSection: some View {
        let isRunning = pomodoro.state == .running
        let isBreak = pomodoro.state == .shortBreak || pomodoro.state == .longBreak
        let isCompleted = pomodoro.state == .completed
        let accent: Color = isRunning ? .orange : isCompleted ? .green : isBreak ? .teal : .blue
        let headerIcon: String = isRunning ? "flame.fill" : isCompleted ? "checkmark.circle.fill" : isBreak ? "cup.and.saucer.fill" : "timer"
        let headerText: String = {
            switch pomodoro.state {
            case .running:    return "집중 중"
            case .completed:  return "포모도로 완료"
            case .shortBreak: return "☕ 짧은 휴식"
            case .longBreak:  return "🛋 긴 휴식"
            default:          return "포모도로"
            }
        }()
        return VStack(spacing: 7) {
            HStack(spacing: 4) {
                Image(systemName: headerIcon)
                    .font(.caption)
                    .foregroundStyle(accent)
                Text(headerText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(accent)
                if pomodoro.state == .idle || pomodoro.state == .paused {
                    PomodoroInfoButton()
                }
            }
            Text(pomodoro.displayTime)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(isRunning || isCompleted || isBreak ? .primary : .secondary)
                .animation(.none, value: pomodoro.displayTime)
            if pomodoro.sessionCount > 0 {
                Text("🍅 × \(pomodoro.sessionCount)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Group {
                    switch pomodoro.state {
                    case .idle:
                        Button("▶  시작") { pomodoro.start() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    case .running:
                        Button("⏸  일시정지") { pomodoro.pause() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .paused:
                        Button("▶  계속") { pomodoro.resume() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .completed:
                        Button("☕  휴식 시작") { pomodoro.startBreak() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.small)
                        Button("↺") { pomodoro.reset() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    case .shortBreak, .longBreak:
                        Button("건너뛰기") { pomodoro.skipBreak() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(accent.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: pomodoro.state)
    }
```

- [ ] **Step 2: Build to verify compilation**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: update pomodoroSection for break timer states"
```

---

### Task 3: CruxPetApp break notification

**Files:**
- Modify: `CruxPet/CruxPetApp.swift`

No unit tests — verified by build.

- [ ] **Step 1: Wire `breakComplete` callback in `startServices()` in `CruxPet/CruxPetApp.swift`**

Find:
```swift
        pomodoro.onComplete = {
            watcher.appendPomodoro()
            pet.gainPomodoroExp()
            sendPomodoroNotification()
        }
```

Replace with:
```swift
        pomodoro.onComplete = {
            watcher.appendPomodoro()
            pet.gainPomodoroExp()
            sendPomodoroNotification()
        }
        pomodoro.breakComplete = {
            sendBreakCompleteNotification()
        }
```

- [ ] **Step 2: Add `sendBreakCompleteNotification()` to `CruxPetApp`**

Find:
```swift
    private func sendPomodoroNotification() {
```

Insert the new method immediately before it:
```swift
    private func sendBreakCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "CruxPet 🍅"
        content.body = "집중 시작!"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sendPomodoroNotification() {
```

- [ ] **Step 3: Build to verify compilation**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Run full test suite**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "\*\* TEST"
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/CruxPetApp.swift
git commit -m "feat: add break completion notification in CruxPetApp"
```

---

## Self-Review

### Spec Coverage Check

| Spec requirement | Task |
|---|---|
| `.shortBreak` / `.longBreak` added to PomodoroState | Task 1 |
| `sessionCount` increments on completion | Task 1 |
| `startBreak()` picks longBreak at sessionCount % 4 == 0 | Task 1 |
| `startBreak()` picks shortBreak otherwise | Task 1 |
| `skipBreak()` resets to idle, preserves sessionCount | Task 1 |
| `reset()` resets sessionCount | Task 1 |
| `breakComplete` callback | Task 1 |
| Session counter "🍅 × N" in pomodoroSection | Task 2 |
| "☕ 휴식 시작" button in completed state | Task 2 |
| Break countdown UI + "건너뛰기" in break states | Task 2 |
| State-aware header icon/text/accent | Task 2 |
| "집중 시작!" notification on break end (no sound) | Task 3 |

All requirements covered.

### Type Consistency Check

- `pomodoro.sessionCount` — `Int`, defined Task 1, read Task 2 ✓
- `pomodoro.startBreak()` — defined Task 1, called Task 2 ✓
- `pomodoro.skipBreak()` — defined Task 1, called Task 2 ✓
- `pomodoro.breakComplete` — `(() -> Void)?`, defined Task 1, wired Task 3 ✓
- `PomodoroState.shortBreak`, `.longBreak` — defined Task 1, used Task 2 ✓
- `scheduleFocusTimer()` — renamed from `scheduleTimer()`, internal only ✓
