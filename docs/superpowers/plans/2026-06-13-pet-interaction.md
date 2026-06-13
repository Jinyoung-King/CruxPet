# Pet Interaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add tap and feed interactions to the pet — tapping triggers a bounce + floating hearts + temporary `.happy` emotion; a 🍬 treat button grants EXP and triggers `.excited`, with a 30-minute cooldown persisted across restarts.

**Architecture:** `PetInteractionModel` (new `@MainActor @Observable` class) owns tap/feed state and cooldown persistence; two new methods added to `PetModel` (`gainTreatExp()`, `setTemporaryEmotion(_:duration:)`); `ContentView` wires tap gesture, scaleEffect, `ParticleOverlayView`, and treat button; `CruxPetApp` injects the model via `.environment()`.

**Tech Stack:** SwiftUI, `@Observable`, `UserDefaults`, `Task.sleep`, XCTest

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `CruxPet/PetInteractionModel.swift` | Create | Tap/feed state, cooldown, UserDefaults persistence |
| `CruxPet/PetModel.swift` | Modify | `gainTreatExp()` + `setTemporaryEmotion(_:duration:)` |
| `CruxPet/ContentView.swift` | Modify | Tap gesture, bounce, `ParticleOverlayView`, treat button, `@Environment` |
| `CruxPet/CruxPetApp.swift` | Modify | `@State private var interaction`, `.environment(interaction)` |
| `CruxPetTests/PetInteractionModelTests.swift` | Create | canFeed, cooldown, persistence tests |
| `CruxPetTests/PetModelTests.swift` | Modify | Add `gainTreatExp` EXP test |

---

### Task 1: PetModel additions

**Files:**
- Modify: `CruxPet/PetModel.swift`
- Modify: `CruxPetTests/PetModelTests.swift`

- [ ] **Step 1: Write the failing test**

Add at the bottom of `PetModelTests` class (before the closing `}`):

```swift
// MARK: - gainTreatExp

@MainActor func testGainTreatExpAdds10() {
    UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    let pet = PetModel()
    let before = pet.totalExp
    pet.gainTreatExp()
    XCTAssertEqual(pet.totalExp, before + 10)
}
```

- [ ] **Step 2: Run test to confirm failure**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing CruxPetTests/PetModelTests/testGainTreatExpAdds10 2>&1 | grep -E "error:|FAILED|PASSED"
```

Expected: compile error — `gainTreatExp()` does not exist.

- [ ] **Step 3: Add `gainTreatExp()` and `setTemporaryEmotion(_:duration:)` to `CruxPet/PetModel.swift`**

Find the line containing `@MainActor func gainQuestExp(_ exp: Int)` (around line 112). Add the two new methods after the `gainQuestExp` closing `}`:

```swift
@MainActor func gainTreatExp() {
    totalExp += 10
    persist()
}

func setTemporaryEmotion(_ newEmotion: EmotionState, duration: Double) {
    emotion = newEmotion
    Task { @MainActor [weak self] in
        try? await Task.sleep(for: .seconds(duration))
        self?.updateEmotion()
    }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing CruxPetTests/PetModelTests/testGainTreatExpAdds10 2>&1 | grep -E "PASSED|FAILED"
```

Expected: `Test case 'PetModelTests.testGainTreatExpAdds10()' passed`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/PetModel.swift CruxPetTests/PetModelTests.swift
git commit -m "feat: add gainTreatExp and setTemporaryEmotion to PetModel"
```

---

### Task 2: PetInteractionModel

**Files:**
- Create: `CruxPet/PetInteractionModel.swift`
- Create: `CruxPetTests/PetInteractionModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `CruxPetTests/PetInteractionModelTests.swift`:

```swift
import XCTest
@testable import CruxPet

@MainActor
final class PetInteractionModelTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "cruxpet.lastFedAt")
        UserDefaults.standard.removeObject(forKey: "cruxpet.totalExp")
    }

    func testCanFeedInitially() {
        let m = PetInteractionModel()
        XCTAssertTrue(m.canFeed)
    }

    func testCooldownRemainingInitiallyZero() {
        let m = PetInteractionModel()
        XCTAssertEqual(m.cooldownRemaining, 0)
    }

    func testCanFeedFalseAfterFeeding() {
        let m = PetInteractionModel()
        let pet = PetModel()
        m.feed(pet: pet)
        XCTAssertFalse(m.canFeed)
    }

    func testCooldownRemainingAfterFeeding() {
        let m = PetInteractionModel()
        let pet = PetModel()
        m.feed(pet: pet)
        XCTAssertGreaterThan(m.cooldownRemaining, 29 * 60)
        XCTAssertLessThanOrEqual(m.cooldownRemaining, 30 * 60)
    }

    func testCooldownPersistsAcrossReinit() {
        let m1 = PetInteractionModel()
        let pet = PetModel()
        m1.feed(pet: pet)
        let m2 = PetInteractionModel()
        XCTAssertFalse(m2.canFeed)
    }

    func testCanFeedTrueAfterCooldownElapsed() {
        let past = Date(timeIntervalSinceNow: -(31 * 60))
        UserDefaults.standard.set(past.timeIntervalSince1970, forKey: "cruxpet.lastFedAt")
        let m = PetInteractionModel()
        XCTAssertTrue(m.canFeed)
    }

    func testFeedDoesNothingWhenOnCooldown() {
        let m = PetInteractionModel()
        let pet = PetModel()
        m.feed(pet: pet)
        let expAfterFirst = pet.totalExp
        m.feed(pet: pet)
        XCTAssertEqual(pet.totalExp, expAfterFirst)
    }
}
```

- [ ] **Step 2: Run tests to confirm build failure**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing CruxPetTests/PetInteractionModelTests 2>&1 | grep -E "error:|FAILED|PASSED"
```

Expected: compile error — `PetInteractionModel` does not exist.

- [ ] **Step 3: Create `CruxPet/PetInteractionModel.swift`**

```swift
import Foundation
import Observation

@MainActor @Observable
class PetInteractionModel {
    private(set) var isTapped = false
    private(set) var showParticles = false
    private(set) var isEating = false
    private(set) var lastFedAt: Date?

    let feedCooldownMinutes = 30

    var canFeed: Bool {
        guard let last = lastFedAt else { return true }
        return Date().timeIntervalSince(last) >= Double(feedCooldownMinutes * 60)
    }

    var cooldownRemaining: TimeInterval {
        guard let last = lastFedAt, !canFeed else { return 0 }
        return Double(feedCooldownMinutes * 60) - Date().timeIntervalSince(last)
    }

    private static let lastFedKey = "cruxpet.lastFedAt"

    init() {
        if let ts = UserDefaults.standard.object(forKey: Self.lastFedKey) as? Double {
            lastFedAt = Date(timeIntervalSince1970: ts)
        }
    }

    func tap(pet: PetModel) {
        isTapped = true
        showParticles = true
        pet.setTemporaryEmotion(.happy, duration: 2.0)
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isTapped = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            showParticles = false
        }
    }

    func feed(pet: PetModel) {
        guard canFeed else { return }
        lastFedAt = Date()
        UserDefaults.standard.set(lastFedAt!.timeIntervalSince1970, forKey: Self.lastFedKey)
        pet.gainTreatExp()
        pet.setTemporaryEmotion(.excited, duration: 1.5)
        isEating = true
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            isEating = false
        }
    }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' -only-testing CruxPetTests/PetInteractionModelTests 2>&1 | grep -E "Test Suite|PASSED|FAILED"
```

Expected: `Test Suite 'PetInteractionModelTests' passed`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/PetInteractionModel.swift CruxPetTests/PetInteractionModelTests.swift
git commit -m "feat: add PetInteractionModel with tap and feed cooldown"
```

---

### Task 3: ContentView wiring + CruxPetApp injection

**Files:**
- Modify: `CruxPet/ContentView.swift`
- Modify: `CruxPet/CruxPetApp.swift`

No unit tests (UI component — verified by build).

- [ ] **Step 1: Add `@Environment` for PetInteractionModel in `ContentView.swift`**

Find (line ~136):
```swift
    @Environment(EnvironmentModel.self) private var environment
```

Replace with:
```swift
    @Environment(EnvironmentModel.self) private var environment
    @Environment(PetInteractionModel.self) private var interaction
```

- [ ] **Step 2: Add tap gesture and bounce to PetView in `ContentView.swift`**

In `characterSection`, find:
```swift
                PetView(
                    petType: customization.petType,
                    appearance: pet.slimeAppearance.applying(customization),
                    level: pet.level,
                    emotion: pomodoro.state == .running ? .normal : pet.emotion,
                    environmentAccessories: environment.currentAccessories,
                    accessories: customization.accessories,
                    isPomodoroActive: pomodoro.state == .running,
                    isWandering: pomodoro.state != .running
                )
```

Replace with:
```swift
                PetView(
                    petType: customization.petType,
                    appearance: pet.slimeAppearance.applying(customization),
                    level: pet.level,
                    emotion: pomodoro.state == .running ? .normal : pet.emotion,
                    environmentAccessories: environment.currentAccessories,
                    accessories: customization.accessories,
                    isPomodoroActive: pomodoro.state == .running,
                    isWandering: pomodoro.state != .running
                )
                .scaleEffect(interaction.isTapped ? 1.25 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
                .onTapGesture { interaction.tap(pet: pet) }
                if interaction.showParticles {
                    ParticleOverlayView()
                }
```

- [ ] **Step 3: Add `treatButton` computed property and `ParticleOverlayView` to `ContentView.swift`**

Find the line `private var streakBadge: some View {` (around line 380). Insert the new computed property **before** it:

```swift
    private var treatButton: some View {
        Button {
            interaction.feed(pet: pet)
        } label: {
            HStack(spacing: 3) {
                Text(interaction.isEating ? "😋" : "🍬")
                    .font(.system(size: 13))
                if !interaction.canFeed {
                    Text("\(max(1, Int(interaction.cooldownRemaining / 60)))분")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!interaction.canFeed)
        .opacity(interaction.canFeed ? 1.0 : 0.45)
    }
```

Then at the bottom of `ContentView.swift`, just before the file's final `}`, add the private struct:

```swift
private struct ParticleOverlayView: View {
    @State private var floated = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Text("❤️")
                    .font(.system(size: 12))
                    .offset(x: CGFloat(i - 1) * 10, y: floated ? -40 : 0)
                    .opacity(floated ? 0 : 1)
                    .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: floated)
            }
        }
        .onAppear { floated = true }
    }
}
```

- [ ] **Step 4: Place `treatButton` in `characterSection`**

In `characterSection`, find:
```swift
        .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
        .animation(.spring(duration: 0.4), value: pet.showLevelUp)
            HStack(spacing: 5) {
```

Replace with:
```swift
        .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
        .animation(.spring(duration: 0.4), value: pet.showLevelUp)
            treatButton
            HStack(spacing: 5) {
```

- [ ] **Step 5: Inject PetInteractionModel in `CruxPetApp.swift`**

Find (line ~100):
```swift
    @State private var environment = EnvironmentModel()
```

Replace with:
```swift
    @State private var environment = EnvironmentModel()
    @State private var interaction = PetInteractionModel()
```

Find (line ~109):
```swift
                .environment(environment)
```

Replace with:
```swift
                .environment(environment)
                .environment(interaction)
```

- [ ] **Step 6: Build to verify compilation**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Run full test suite**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "\*\* TEST"
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add CruxPet/ContentView.swift CruxPet/CruxPetApp.swift
git commit -m "feat: wire pet tap bounce, particles, and treat button in ContentView"
```

---

## Self-Review

### Spec Coverage Check

| Spec requirement | Task |
|---|---|
| Tap → bounce animation (scaleEffect 1.25, spring) | Task 3 |
| Tap → floating heart particles | Task 3 (`ParticleOverlayView`) |
| Tap → `.happy` emotion for 2s | Task 2 (`tap()` calls `setTemporaryEmotion`) |
| Feed → `.excited` emotion for 1.5s | Task 2 (`feed()` calls `setTemporaryEmotion`) |
| Feed → +10 EXP | Task 1 (`gainTreatExp`) + Task 2 |
| Feed → eating animation (🍬→😋) | Task 3 (`treatButton`, `isEating`) |
| 30-minute cooldown | Task 2 (`feedCooldownMinutes = 30`) |
| Cooldown persisted to UserDefaults | Task 2 (`cruxpet.lastFedAt`) |
| Button greyed + countdown label during cooldown | Task 3 (`treatButton`) |
| PetInteractionModel injected via environment | Task 3 (`CruxPetApp`) |

All requirements covered.

### Type Consistency Check

- `PetInteractionModel.tap(pet:)` — called with `pet: PetModel` ✓
- `PetInteractionModel.feed(pet:)` — called with `pet: PetModel` ✓
- `pet.gainTreatExp()` — `@MainActor`, defined in Task 1, called from Task 2 (also `@MainActor`) ✓
- `pet.setTemporaryEmotion(_ newEmotion: EmotionState, duration: Double)` — defined Task 1, called Task 2 ✓
- `ParticleOverlayView` — private struct, defined and used in ContentView.swift ✓
- `interaction.isTapped`, `interaction.showParticles`, `interaction.isEating`, `interaction.canFeed`, `interaction.cooldownRemaining` — all defined in Task 2 ✓
