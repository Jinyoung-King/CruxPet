# Goal Tap → Expand Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tapping either daily goal row (commit or pomodoro) in DailyGoalView expands the weekly stats chart automatically.

**Architecture:** Lift `isExpanded` state from `StatsView` to `ContentView`. Pass it as a `@Binding`. `DailyGoalView` gets an `onTap` callback that sets `isStatsExpanded = true` with animation.

**Tech Stack:** SwiftUI, `@Binding`, `.onTapGesture`

---

### Task 1: StatsView — lift isExpanded to a Binding

**Files:**
- Modify: `CruxPet/StatsView.swift:9` — change `@State private var isExpanded = false` → `@Binding var isExpanded: Bool`
- Modify: `CruxPet/StatsView.swift:114-120` — update `#Preview` to pass `.constant(true)`

No tests needed — pure structural change, verified by build success.

- [ ] **Step 1: Change the property declaration**

In `CruxPet/StatsView.swift`, replace line 9:

```swift
// BEFORE
@State private var isExpanded = false

// AFTER
@Binding var isExpanded: Bool
```

The `isExpanded.toggle()` call inside `body` (line 35) still works — `@Binding` supports mutation.

- [ ] **Step 2: Update #Preview**

Replace lines 114-120:

```swift
// BEFORE
#Preview {
    let history = ActivityHistoryModel()
    let pet = PetModel()
    return StatsView(pet: pet, history: history)
        .padding()
        .frame(width: 220)
}

// AFTER
#Preview {
    let history = ActivityHistoryModel()
    let pet = PetModel()
    return StatsView(pet: pet, history: history, isExpanded: .constant(true))
        .padding()
        .frame(width: 220)
}
```

- [ ] **Step 3: Build to confirm no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/StatsView.swift
git commit -m "refactor: lift StatsView isExpanded to @Binding"
```

---

### Task 2: ContentView — wire DailyGoalView tap to stats expansion

**Files:**
- Modify: `CruxPet/ContentView.swift:37-78` — add `onTap: () -> Void` to `DailyGoalView`, add `.onTapGesture` to goalRow HStack
- Modify: `CruxPet/ContentView.swift:186-190` — add `@State private var isStatsExpanded = false`
- Modify: `CruxPet/ContentView.swift:539-550` — update `goalSection` and `statsSection`

- [ ] **Step 1: Add onTap parameter and gesture to DailyGoalView**

In `CruxPet/ContentView.swift`, `DailyGoalView` struct (lines 37-78):

```swift
// BEFORE
private struct DailyGoalView: View {
    let todayCommits: Int
    let todayPomodoros: Int
    let commitGoal: Int
    let pomodoroGoal: Int

    var body: some View {
        VStack(spacing: 4) {
            goalRow("⚡", "커밋",  current: todayCommits,   goal: commitGoal)
            goalRow("🍅", "포모", current: todayPomodoros, goal: pomodoroGoal)
        }
    }

    private func goalRow(_ emoji: String, _ label: String, current: Int, goal: Int) -> some View {
        let done = current >= goal
        let ratio: CGFloat = goal > 0 ? min(CGFloat(current) / CGFloat(goal), 1.0) : 0
        return HStack(spacing: 6) {
            Text("\(emoji) \(label)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 6)
            HStack(spacing: 2) {
                Text("\(current)/\(goal)")
                    .font(.system(size: 9))
                    .foregroundStyle(done ? .green : .secondary)
                if done {
                    Text("✓").font(.system(size: 9)).foregroundStyle(.green)
                }
            }
            .frame(width: 36, alignment: .trailing)
        }
    }
}

// AFTER
private struct DailyGoalView: View {
    let todayCommits: Int
    let todayPomodoros: Int
    let commitGoal: Int
    let pomodoroGoal: Int
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            goalRow("⚡", "커밋",  current: todayCommits,   goal: commitGoal)
            goalRow("🍅", "포모", current: todayPomodoros, goal: pomodoroGoal)
        }
    }

    private func goalRow(_ emoji: String, _ label: String, current: Int, goal: Int) -> some View {
        let done = current >= goal
        let ratio: CGFloat = goal > 0 ? min(CGFloat(current) / CGFloat(goal), 1.0) : 0
        return HStack(spacing: 6) {
            Text("\(emoji) \(label)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 6)
            HStack(spacing: 2) {
                Text("\(current)/\(goal)")
                    .font(.system(size: 9))
                    .foregroundStyle(done ? .green : .secondary)
                if done {
                    Text("✓").font(.system(size: 9)).foregroundStyle(.green)
                }
            }
            .frame(width: 36, alignment: .trailing)
        }
        .onTapGesture { onTap() }
    }
}
```

- [ ] **Step 2: Add isStatsExpanded state variable**

In `CruxPet/ContentView.swift`, after line 186 (`@State private var isQuestExpanded = false`):

```swift
// ADD this line after isQuestExpanded:
@State private var isStatsExpanded = false
```

- [ ] **Step 3: Update goalSection and statsSection**

In `CruxPet/ContentView.swift`, replace lines 539-550:

```swift
// BEFORE
private var goalSection: some View {
    DailyGoalView(
        todayCommits: pet.todayCommitCount,
        todayPomodoros: pet.todayPomodoroCount,
        commitGoal: customization.dailyCommitGoal,
        pomodoroGoal: customization.dailyPomodoroGoal
    )
}

private var statsSection: some View {
    StatsView(pet: pet, history: history)
}

// AFTER
private var goalSection: some View {
    DailyGoalView(
        todayCommits: pet.todayCommitCount,
        todayPomodoros: pet.todayPomodoroCount,
        commitGoal: customization.dailyCommitGoal,
        pomodoroGoal: customization.dailyPomodoroGoal,
        onTap: { withAnimation(.easeInOut(duration: 0.2)) { isStatsExpanded = true } }
    )
}

private var statsSection: some View {
    StatsView(pet: pet, history: history, isExpanded: $isStatsExpanded)
}
```

- [ ] **Step 4: Build to confirm no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `Build succeeded`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: tap goal row to expand stats chart"
```
