# Commit Jump Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the pet jump upward briefly when a commit is detected, giving immediate visual feedback that the commit registered.

**Architecture:** Two files changed — `PetModel.swift` adds a `showJump` boolean (triggered from `gainCommitExp()`) and `ContentView.swift` adds `.offset(y:)` + `.animation()` modifiers to the PetView call in `characterSection`. Follows the exact same pattern as `showCritical` and `showLevelUp`.

**Tech Stack:** SwiftUI, Swift Concurrency (`Task.sleep`)

---

### Task 1: Add `showJump` state and `triggerJump()` to PetModel

**Files:**
- Modify: `CruxPet/PetModel.swift` (lines ~38–39 for state, ~97 for trigger call, ~274 for method)

No tests — pure state management verified by build success.

- [ ] **Step 1: Add `showJump` property after `showLevelUp`**

In `CruxPet/PetModel.swift`, find:

```swift
    private(set) var showCritical: Bool = false
    private(set) var showLevelUp: Bool = false
```

Replace with:

```swift
    private(set) var showCritical: Bool = false
    private(set) var showLevelUp: Bool = false
    private(set) var showJump: Bool = false
```

- [ ] **Step 2: Add `triggerJump()` method before `triggerExcitement()`**

In `CruxPet/PetModel.swift`, find:

```swift
    private func triggerExcitement() {
        lastActivityDate = Date()
```

Replace with:

```swift
    private func triggerJump() {
        showJump = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            self?.showJump = false
        }
    }

    private func triggerExcitement() {
        lastActivityDate = Date()
```

- [ ] **Step 3: Call `triggerJump()` from `gainCommitExp()`**

In `CruxPet/PetModel.swift`, find:

```swift
        triggerExcitement()
        persist()
```

Replace with:

```swift
        triggerExcitement()
        triggerJump()
        persist()
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
git commit -m "feat: add showJump state to PetModel (triggers on commit)"
```

---

### Task 2: Add jump animation modifiers to PetView in characterSection

**Files:**
- Modify: `CruxPet/ContentView.swift` (`characterSection` computed var, lines ~398–399)

- [ ] **Step 1: Add `.offset()` and `.animation()` modifiers to PetView**

In `CruxPet/ContentView.swift`, find:

```swift
                .scaleEffect(interaction.isTapped ? 1.875 : 1.5)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

Replace with:

```swift
                .scaleEffect(interaction.isTapped ? 1.875 : 1.5)
                .offset(y: pet.showJump ? -22 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

The `.offset(y: -22)` moves the pet 22pt upward when `showJump` is true. In SwiftUI, negative y = upward. The spring (response: 0.3, dampingFraction: 0.4) launches up quickly and bounces once on return. The two `.animation()` modifiers are separate — each targets its own `value` key, so tap and jump animations don't interfere.

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: animate pet jump on commit detection"
```
