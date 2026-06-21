# Pomodoro Complete Bounce Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the pet bounce celebratorily when a pomodoro session completes — bigger offset (-28pt) and bouncier spring (dampingFraction: 0.3) than the commit jump (-22pt, 0.4).

**Architecture:** Two files changed — `PetModel.swift` adds `showPomoComplete` bool + `triggerPomoComplete()` called from `gainPomodoroExp()`, and `ContentView.swift` adds offset + animation modifiers keyed on `pet.showPomoComplete`. Follows the exact same pattern as `showJump`.

**Tech Stack:** SwiftUI, Swift Concurrency (`Task.sleep`)

---

### Task 1: Add `showPomoComplete` state and `triggerPomoComplete()` to PetModel

**Files:**
- Modify: `CruxPet/PetModel.swift` (lines ~40, ~112, ~276)

- [ ] **Step 1: Add `showPomoComplete` property after `showJump`**

In `CruxPet/PetModel.swift`, find:

```swift
    private(set) var showJump: Bool = false
    var pendingLevelUp: Int = 0
```

Replace with:

```swift
    private(set) var showJump: Bool = false
    private(set) var showPomoComplete: Bool = false
    var pendingLevelUp: Int = 0
```

- [ ] **Step 2: Add `triggerPomoComplete()` method before `triggerJump()`**

Find:

```swift
    private func triggerJump() {
        showJump = true
```

Replace with:

```swift
    private func triggerPomoComplete() {
        showPomoComplete = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.7))
            self?.showPomoComplete = false
        }
    }

    private func triggerJump() {
        showJump = true
```

- [ ] **Step 3: Call `triggerPomoComplete()` from `gainPomodoroExp()`**

`gainCommitExp()` already has `triggerJump()` between `triggerExcitement()` and `persist()`, so the following find string is unique to `gainPomodoroExp()`.

Find:

```swift
        triggerExcitement()
        persist()
    }
```

Replace with:

```swift
        triggerExcitement()
        triggerPomoComplete()
        persist()
    }
```

- [ ] **Step 4: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/PetModel.swift
git commit -m "feat: add showPomoComplete state to PetModel"
```

---

### Task 2: Add pomo complete animation modifiers to PetView in characterSection

**Files:**
- Modify: `CruxPet/ContentView.swift` (`characterSection`, lines ~399–401)

- [ ] **Step 1: Add offset + animation for pomo complete**

In `CruxPet/ContentView.swift`, find:

```swift
                .offset(y: pet.showJump ? -22 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

Replace with:

```swift
                .offset(y: pet.showJump ? -22 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
                .offset(y: pet.showPomoComplete ? -28 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.3), value: pet.showPomoComplete)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: animate pet bounce on pomodoro complete"
```
