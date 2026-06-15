# Daily Goals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show always-visible daily commit/pomodoro progress bars in the main menu, award +50 XP and an excited pet reaction when both goals are met.

**Architecture:** No new files. Five existing files modified: `PetCustomization` stores goal values, `PetModel` tracks the bonus flag and awards it, `CruxPetApp` checks completion after each activity event, `ContentView` shows a `DailyGoalView` progress component, `CustomizeView` lets the user adjust goal targets.

**Tech Stack:** Swift, SwiftUI, @Observable, UserDefaults, XCTest

---

## File Map

| File | Change |
|------|--------|
| `CruxPet/PetCustomization.swift` | Add `dailyCommitGoal: Int`, `dailyPomodoroGoal: Int` |
| `CruxPet/PetModel.swift` | Add `goalBonusAwardedToday: Bool`, `awardGoalBonus()`, reset logic |
| `CruxPet/CruxPetApp.swift` | Add `checkGoalCompletion()`, call from commit/pomodoro callbacks |
| `CruxPet/ContentView.swift` | Add `DailyGoalView` private struct + `goalSection` |
| `CruxPet/CustomizeView.swift` | Add "일일 목표" section with steppers; increase frame height 580→650 |
| `CruxPetTests/PetCustomizationTests.swift` | Add 3 tests for new goal fields |
| `CruxPetTests/PetModelTests.swift` | Add 3 tests for awardGoalBonus |

---

### Task 1: PetCustomization — add dailyCommitGoal and dailyPomodoroGoal

**Files:**
- Modify: `CruxPet/PetCustomization.swift`
- Test: `CruxPetTests/PetCustomizationTests.swift`

**Context:** `PetCustomization` is a `Codable` struct stored in UserDefaults under `cruxpet.customization`. It has a custom `init(from:)` and `encode(to:)` using `decodeIfPresent` for backward compatibility. You must follow this pattern for the new fields.

- [ ] **Step 1: Write failing tests in `CruxPetTests/PetCustomizationTests.swift`**

Add these three test methods to the existing `PetCustomizationTests` class:

```swift
func testDailyGoalDefaults() {
    let c = PetCustomization()
    XCTAssertEqual(c.dailyCommitGoal, 5)
    XCTAssertEqual(c.dailyPomodoroGoal, 4)
}

func testDailyGoalRoundTrip() throws {
    var c = PetCustomization()
    c.dailyCommitGoal = 8
    c.dailyPomodoroGoal = 3
    let data = try JSONEncoder().encode(c)
    let decoded = try JSONDecoder().decode(PetCustomization.self, from: data)
    XCTAssertEqual(decoded.dailyCommitGoal, 8)
    XCTAssertEqual(decoded.dailyPomodoroGoal, 3)
}

func testDailyGoalDefaultsOnOldData() {
    let oldJSON = """
    {"name":"Crux","useCustomColor":false,"customColorHex":"#7EC8E3","pomodoroMinutes":25}
    """.data(using: .utf8)!
    UserDefaults.standard.set(oldJSON, forKey: "cruxpet.customization")
    let c = PetCustomization.load()
    XCTAssertEqual(c.dailyCommitGoal, 5)
    XCTAssertEqual(c.dailyPomodoroGoal, 4)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing:CruxPetTests/PetCustomizationTests/testDailyGoalDefaults 2>&1 | grep -E "error:|FAILED|PASSED"
```

Expected: FAILED (property `dailyCommitGoal` does not exist)

- [ ] **Step 3: Add fields to `CruxPet/PetCustomization.swift`**

Add two properties after `var pomodoroMinutes: Int = 25`:

```swift
var dailyCommitGoal: Int = 5
var dailyPomodoroGoal: Int = 4
```

Add cases to `CodingKeys`:

```swift
enum CodingKeys: String, CodingKey {
    case petNames, name, useCustomColor, customColorHex, accessories, pomodoroMinutes, petType
    case dailyCommitGoal, dailyPomodoroGoal
}
```

In `init(from decoder:)`, add after the `pomodoroMinutes` line:

```swift
dailyCommitGoal   = try container.decodeIfPresent(Int.self, forKey: .dailyCommitGoal)  ?? 5
dailyPomodoroGoal = try container.decodeIfPresent(Int.self, forKey: .dailyPomodoroGoal) ?? 4
```

In `encode(to encoder:)`, add after the `pomodoroMinutes` line:

```swift
try container.encode(dailyCommitGoal,  forKey: .dailyCommitGoal)
try container.encode(dailyPomodoroGoal, forKey: .dailyPomodoroGoal)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing:CruxPetTests/PetCustomizationTests 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: All PetCustomizationTests PASSED

- [ ] **Step 5: Commit**

```bash
git add CruxPet/PetCustomization.swift CruxPetTests/PetCustomizationTests.swift
git commit -m "feat: add dailyCommitGoal and dailyPomodoroGoal to PetCustomization"
```

---

### Task 2: PetModel — goalBonusAwardedToday + awardGoalBonus()

**Files:**
- Modify: `CruxPet/PetModel.swift`
- Test: `CruxPetTests/PetModelTests.swift`

**Context:** `PetModel` is `@Observable`. Properties are persisted in `persist()` and reset in `resetDailyCountsIfNeeded()` (which runs on `init()` and every 60 seconds). Use the `@MainActor` annotation on the new function — see existing `gainTreatExp()` for the pattern. `setTemporaryEmotion(_:duration:)` already exists and handles the excited state.

- [ ] **Step 1: Write failing tests in `CruxPetTests/PetModelTests.swift`**

Add these three test methods to the existing `PetModelTests` class:

```swift
@MainActor func testAwardGoalBonusAdds50Exp() {
    UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    UserDefaults.standard.removeObject(forKey: "cruxpet.goalBonusAwardedToday")
    let pet = PetModel()
    let before = pet.totalExp
    pet.awardGoalBonus()
    XCTAssertEqual(pet.totalExp, before + 50)
    XCTAssertTrue(pet.goalBonusAwardedToday)
    UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    UserDefaults.standard.removeObject(forKey: "cruxpet.goalBonusAwardedToday")
}

@MainActor func testAwardGoalBonusIsIdempotent() {
    UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    UserDefaults.standard.removeObject(forKey: "cruxpet.goalBonusAwardedToday")
    let pet = PetModel()
    let before = pet.totalExp
    pet.awardGoalBonus()
    pet.awardGoalBonus()
    XCTAssertEqual(pet.totalExp, before + 50)
    UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    UserDefaults.standard.removeObject(forKey: "cruxpet.goalBonusAwardedToday")
}

@MainActor func testGoalBonusResetsWithDailyCounts() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    UserDefaults.standard.set(yesterday, forKey: "cruxpet.todayDate")
    UserDefaults.standard.set(true, forKey: "cruxpet.goalBonusAwardedToday")
    let pet = PetModel()
    XCTAssertFalse(pet.goalBonusAwardedToday)
    UserDefaults.standard.removeObject(forKey: "cruxpet.todayDate")
    UserDefaults.standard.removeObject(forKey: "cruxpet.goalBonusAwardedToday")
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing:CruxPetTests/PetModelTests/testAwardGoalBonusAdds50Exp 2>&1 | grep -E "error:|FAILED|PASSED"
```

Expected: FAILED (`value of type 'PetModel' has no member 'awardGoalBonus'`)

- [ ] **Step 3: Add `goalBonusAwardedToday` property to `CruxPet/PetModel.swift`**

Add after `private(set) var hasNightOwlCommit: Bool = false` (line ~46):

```swift
private(set) var goalBonusAwardedToday: Bool = false
```

In `init()`, add after the `hasNightOwlCommit` loading line:

```swift
goalBonusAwardedToday = UserDefaults.standard.bool(forKey: "cruxpet.goalBonusAwardedToday")
```

- [ ] **Step 4: Add `awardGoalBonus()` to `CruxPet/PetModel.swift`**

Add after `gainTreatExp()`:

```swift
@MainActor func awardGoalBonus() {
    guard !goalBonusAwardedToday else { return }
    totalExp += 50
    goalBonusAwardedToday = true
    persist()
    setTemporaryEmotion(.excited, duration: 5)
}
```

- [ ] **Step 5: Persist and reset `goalBonusAwardedToday`**

In `persist()`, add:

```swift
UserDefaults.standard.set(goalBonusAwardedToday, forKey: "cruxpet.goalBonusAwardedToday")
```

In `resetDailyCountsIfNeeded()`, inside the `if stored != today { ... }` block, add after `todayPomodoroCount = 0`:

```swift
goalBonusAwardedToday = false
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing:CruxPetTests/PetModelTests 2>&1 | grep -E "error:|FAILED|PASSED|Test Suite"
```

Expected: All PetModelTests PASSED

- [ ] **Step 7: Commit**

```bash
git add CruxPet/PetModel.swift CruxPetTests/PetModelTests.swift
git commit -m "feat: add goalBonusAwardedToday and awardGoalBonus to PetModel"
```

---

### Task 3: CruxPetApp — check goal completion after each activity

**Files:**
- Modify: `CruxPet/CruxPetApp.swift`

**Context:** `startServices()` sets up `watcher.onCommit` and `pomodoro.onComplete` closures. Both closures have access to `pet` (a `@State` property). `PetCustomization.load()` reads from UserDefaults JSON — fast and suitable for per-event use. The goals only change when the user saves from CustomizeView.

- [ ] **Step 1: Add `checkGoalCompletion()` to `CruxPetApp`**

Add this private method anywhere in `CruxPetApp` (e.g., after `cancelStreakReminder`):

```swift
private func checkGoalCompletion() {
    let goals = PetCustomization.load()
    guard pet.todayCommitCount >= goals.dailyCommitGoal,
          pet.todayPomodoroCount >= goals.dailyPomodoroGoal,
          !pet.goalBonusAwardedToday else { return }
    pet.awardGoalBonus()
}
```

- [ ] **Step 2: Call `checkGoalCompletion()` in both callbacks**

In `startServices()`, update the closures:

```swift
watcher.onCommit = {
    pet.gainCommitExp()
    Self.cancelStreakReminder()
    checkGoalCompletion()
}
pomodoro.onComplete = {
    watcher.appendPomodoro()
    pet.gainPomodoroExp()
    sendPomodoroNotification()
    Self.cancelStreakReminder()
    checkGoalCompletion()
}
```

- [ ] **Step 3: Build to verify no compilation errors**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/CruxPetApp.swift
git commit -m "feat: check daily goal completion after each commit and pomodoro"
```

---

### Task 4: ContentView — DailyGoalView + goalSection

**Files:**
- Modify: `CruxPet/ContentView.swift`

**Context:** `ContentView` has a `@State private var customization = PetCustomization.load()` and an `@Environment(PetModel.self) private var pet`. The main VStack currently has `characterSection` then `expSection`. You'll add `goalSection` between them. `DailyGoalView` should be a `private struct` defined inside `ContentView.swift` (like `PomodoroInfoButton` or `AchievementsView` already are).

- [ ] **Step 1: Add `DailyGoalView` private struct to `ContentView.swift`**

Add this struct anywhere in `ContentView.swift` before the `ContentView` struct definition:

```swift
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
```

- [ ] **Step 2: Add `goalSection` computed var inside `ContentView`**

Add this computed property alongside the other `private var xxxSection` properties in `ContentView`:

```swift
private var goalSection: some View {
    DailyGoalView(
        todayCommits: pet.todayCommitCount,
        todayPomodoros: pet.todayPomodoroCount,
        commitGoal: customization.dailyCommitGoal,
        pomodoroGoal: customization.dailyPomodoroGoal
    )
}
```

- [ ] **Step 3: Insert `goalSection` between `characterSection` and `expSection` in the main VStack**

In the main `VStack(spacing: 10)` inside `body`, find:

```swift
characterSection
expSection
```

Replace with:

```swift
characterSection
goalSection
expSection
```

- [ ] **Step 4: Build to verify no compilation errors**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: add DailyGoalView progress bars to main menu"
```

---

### Task 5: CustomizeView — goal settings UI

**Files:**
- Modify: `CruxPet/CustomizeView.swift`

**Context:** `CustomizeView` uses a `@State private var draft: PetCustomization` that starts as a copy of the current customization. The view is a `ScrollView` with a fixed frame `(width: 220, height: 580)`. Adding a new section increases content height, so you need to increase the frame height to `650` to avoid showing a scrollbar. Insert the new section between the "포모도로 시간" section and the "버튼" section.

- [ ] **Step 1: Add "일일 목표" section in `CruxPet/CustomizeView.swift`**

Find the "포모도로 시간" section (ends with closing `}`). After it, before the "// 버튼" comment, add:

```swift
// 일일 목표
VStack(alignment: .leading, spacing: 6) {
    Text("일일 목표").font(.caption.bold()).foregroundStyle(.secondary)
    HStack {
        Text("⚡ 커밋").font(.caption2).foregroundStyle(.secondary)
        Spacer()
        Stepper(value: $draft.dailyCommitGoal, in: 1...20) {
            Text("\(draft.dailyCommitGoal)회").font(.caption2)
        }
    }
    HStack {
        Text("🍅 포모도로").font(.caption2).foregroundStyle(.secondary)
        Spacer()
        Stepper(value: $draft.dailyPomodoroGoal, in: 1...10) {
            Text("\(draft.dailyPomodoroGoal)회").font(.caption2)
        }
    }
}
```

- [ ] **Step 2: Increase frame height from 580 to 650**

Find:

```swift
.frame(width: 220, height: 580)
```

Replace with:

```swift
.frame(width: 220, height: 650)
```

- [ ] **Step 3: Run all tests to verify nothing is broken**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|FAILED|Test Suite '.*' (passed|failed)"
```

Expected: All test suites passed, no errors

- [ ] **Step 4: Commit**

```bash
git add CruxPet/CustomizeView.swift
git commit -m "feat: add daily goal settings to CustomizeView"
```
