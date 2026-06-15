# Daily Goals Design

## Goal

Show daily commit/pomodoro progress bars always visible in the main menu, with a bonus XP + pet reaction on goal completion.

## Architecture

No new files. Three existing files modified:

### `PetCustomization.swift`
Add two new fields:
- `dailyCommitGoal: Int` — default 5
- `dailyPomodoroGoal: Int` — default 4

Persist via existing JSON encode/decode. Add to `CodingKeys`. Decode with `decodeIfPresent` for backward compatibility.

### `PetModel.swift`
Add:
- `private(set) var goalBonusAwardedToday: Bool` — persisted in UserDefaults (`cruxpet.goalBonusAwardedToday`), reset to `false` in `resetDailyCountsIfNeeded()`
- `func awardGoalBonus()` — gives +50 XP (via existing `gainExp`), sets `goalBonusAwardedToday = true`, triggers `excited` emotion for 5 seconds

### `CruxPetApp.swift`
After each commit or pomodoro event, check if both goals are newly met:
```swift
let commitsOk = pet.todayCommitCount >= customization.dailyCommitGoal
let pomodorosOk = pet.todayPomodoroCount >= customization.dailyPomodoroGoal
if commitsOk && pomodorosOk && !pet.goalBonusAwardedToday {
    pet.awardGoalBonus()
}
```

### `ContentView.swift`
Add `DailyGoalView` as a `private struct` inside ContentView.swift. Insert between `characterSection` and `expSection`.

### `CustomizeView.swift`
Add "일일 목표" section (below 포모도로 시간, above buttons) with two steppers: commit goal (1–20) and pomodoro goal (1–10).

## UI: DailyGoalView

Always-visible compact component showing two progress bars:

```
⚡ 커밋  [████████░░] 4/5
🍅 포모  [██████████] 4/4 ✓
```

- Each row: emoji + label + capsule progress bar + "current/goal" count
- Progress bar fills proportionally: `min(current / goal, 1.0)`
- At 100%: bar color changes from blue/orange to green, ✓ appended to count
- `customization` passed in as a parameter (already available in ContentView via `@State`)

## Goal Completion Logic

- Triggered on every commit and every pomodoro completion in `CruxPetApp.startServices()`
- Condition: `todayCommitCount >= dailyCommitGoal && todayPomodoroCount >= dailyPomodoroGoal && !goalBonusAwardedToday`
- Both goals must be met simultaneously (not independently)
- Bonus: +50 XP, `excited` emotion for 5 seconds
- `goalBonusAwardedToday` is reset to `false` at midnight with other daily counts

## Testing

- `goalBonusAwardedToday` resets to `false` after `resetDailyCountsIfNeeded()`
- `awardGoalBonus()` sets `goalBonusAwardedToday = true` and increases `totalExp` by 50
- Bonus not awarded twice if called again after first award
- `DailyGoalView` shows ✓ and green bar when `current >= goal`
- `DailyGoalView` shows partial fill when `current < goal`
- CustomizeView steppers clamp commit goal to 1–20, pomodoro goal to 1–10

## Non-Goals

- No per-goal independent reward (both must be met for the bonus)
- No weekly goal support
- No goal streak tracking
