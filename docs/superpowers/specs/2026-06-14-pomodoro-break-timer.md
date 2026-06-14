# Pomodoro Break Timer Design

## Goal

Add break timer support to the pomodoro feature: after a focus session completes, the user manually starts a short (5min) or long (15min) break; every 4th session triggers a long break; a macOS notification fires when the break ends.

## Architecture

### PomodoroTimer changes

Extend `PomodoroState` with two new cases and add break management to `PomodoroTimer`.

```swift
enum PomodoroState: Equatable {
    case idle, running, paused, completed, shortBreak, longBreak
}
```

**New properties on PomodoroTimer:**
- `private(set) var sessionCount: Int = 0` — increments each time a pomodoro completes; resets on `reset()`
- `let shortBreakDuration: TimeInterval = 5 * 60`
- `let longBreakDuration: TimeInterval = 15 * 60`
- `var breakComplete: (() -> Void)?` — fired when break countdown reaches 0

**New methods:**
- `startBreak()` — called when user taps "휴식 시작"; picks shortBreak/longBreak based on `sessionCount % 4 == 0`; sets `timeRemaining` to appropriate duration; transitions state; schedules timer
- `skipBreak()` — discards break, resets to idle (timeRemaining = duration, state = .idle); does NOT reset sessionCount

**Modified behavior:**
- When focus countdown reaches 0: `sessionCount += 1`, state = `.completed`, call `onComplete?()`, **stop — do not auto-advance**
- `reset()`: resets sessionCount to 0, state to idle, timeRemaining to duration

**displayTime** already works correctly — it formats `timeRemaining` regardless of state.

### ContentView pomodoroSection changes

**Header row** — `isRunning` expanded to cover `.shortBreak`/`.longBreak`:
- Running/break: flame icon, orange accent
- Completed: checkmark icon, green accent
- idle/paused: timer icon, blue accent

**Session counter** — shown below the time display whenever `sessionCount > 0`:
```
🍅 × 3
```

**State-specific button rows:**

| State | Buttons |
|---|---|
| `.idle` | ▶ 시작 (borderedProminent) |
| `.running` | ⏸ 일시정지 (bordered) · ↺ (bordered) |
| `.paused` | ▶ 계속 (borderedProminent) · ↺ (bordered) |
| `.completed` | ☕ 휴식 시작 (borderedProminent, green) · ↺ (bordered) |
| `.shortBreak` / `.longBreak` | 건너뛰기 (bordered) |

**Break label** — shown in place of "포모도로"/"집중 중" during breaks:
- `.shortBreak`: "☕ 짧은 휴식"
- `.longBreak`: "🛋 긴 휴식"

### Notification

In `CruxPetApp`, wire `pomodoro.breakComplete`:
```swift
pomodoro.breakComplete = {
    sendNotification(title: "CruxPet 🍅", body: "집중 시작!")
}
```

Reuse the existing `sendNotification` helper already in `CruxPetApp`. No sound.

## Behavior Summary

| Trigger | Outcome |
|---|---|
| Focus countdown reaches 0 | sessionCount++, state = .completed, onComplete fires |
| Tap "☕ 휴식 시작" (session % 4 == 0) | state = .longBreak, 15min countdown |
| Tap "☕ 휴식 시작" (session % 4 != 0) | state = .shortBreak, 5min countdown |
| Break countdown reaches 0 | state = .idle, timeRemaining = duration, breakComplete fires |
| Tap "건너뛰기" | state = .idle, timeRemaining = duration (sessionCount unchanged) |
| Tap ↺ | state = .idle, timeRemaining = duration, sessionCount = 0 |

## Files

| File | Action |
|---|---|
| `CruxPet/PomodoroTimer.swift` | Add `.shortBreak`/`.longBreak`, `sessionCount`, `startBreak()`, `skipBreak()`, `breakComplete` |
| `CruxPet/ContentView.swift` | Update `pomodoroSection`: session counter, state-aware header/buttons |
| `CruxPet/CruxPetApp.swift` | Wire `pomodoro.breakComplete` notification |
| `CruxPetTests/PomodoroTimerTests.swift` | Create — sessionCount, startBreak, skipBreak, longBreak threshold tests |

## What This Does NOT Change

- Focus duration setting (still driven by `customization.pomodoroMinutes`)
- Quest/achievement counting (`pet.todayPomodoroCount` incremented via `onComplete` callback — unchanged)
- PetModel emotion or EXP — pomodoro does not interact with these
