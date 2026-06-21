# Commit Jump Animation Design

## Goal

Make the pet visually react to a commit by jumping upward when `gainCommitExp()` fires. This gives immediate positive feedback that a commit was detected.

## Architecture

Two files modified: `CruxPet/PetModel.swift` and `CruxPet/ContentView.swift`. No other files touched.

## Changes

### 1. PetModel.swift — `showJump` state + `triggerJump()`

Add a new `showJump` boolean alongside the existing `showCritical` / `showLevelUp` pattern:

```swift
private(set) var showJump: Bool = false
```

Add `triggerJump()` private method:

```swift
private func triggerJump() {
    showJump = true
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
        self?.showJump = false
    }
}
```

Call `triggerJump()` from `gainCommitExp()`, after the existing `triggerExcitement()` call:

```swift
triggerExcitement()
triggerJump()   // ← new
```

### 2. ContentView.swift — `.offset()` + `.animation()` on PetView

In `characterSection`, the `PetView(...)` block currently has:
```swift
.scaleEffect(interaction.isTapped ? 1.875 : 1.5)
.animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

Add two modifiers immediately after `.scaleEffect(...)` and before the existing `.animation(...)`:

```swift
.scaleEffect(interaction.isTapped ? 1.875 : 1.5)
.offset(y: pet.showJump ? -22 : 0)
.animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
.animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

The spring (response: 0.3, dampingFraction: 0.4) produces a fast upward launch (negative y = up in SwiftUI) with a slight bounce on return. The pet rises 22pt, the spring overshoots slightly as it returns, landing at rest after ~0.5s.

## Animation Feel

- Trigger: `gainCommitExp()` fires (on every commit push detected)
- Motion: pet jumps up 22pt instantly (spring), returns with overshoot
- Duration: ~0.5s total
- Does NOT conflict with `isTapped` scale — they use separate `.animation()` modifiers with separate value keys

## What Does NOT Change

- `PetView`, `SlimeView`, `CatView`, `GhostView`, `DogView` — no changes
- Commit detection / polling logic in `CruxPetApp.swift` — unchanged
- `showCritical`, `showLevelUp` logic — unchanged
- Pomodoro `gainPomodoroExp()` — does NOT trigger jump (commits only)
- Any other file
