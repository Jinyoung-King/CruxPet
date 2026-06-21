# Pomodoro Complete Bounce Design

## Goal

Make the pet bounce celebratorily when a pomodoro session completes. Differentiates from the commit jump: bigger offset (-28pt vs -22pt) and bouncier spring (dampingFraction: 0.3 vs 0.4).

## Architecture

Two files modified: `CruxPet/PetModel.swift` and `CruxPet/ContentView.swift`. Follows the exact same pattern as `showJump` / commit jump animation.

## Changes

### 1. PetModel.swift — `showPomoComplete` state + `triggerPomoComplete()`

Add property after `showJump`:

```swift
private(set) var showPomoComplete: Bool = false
```

Add method before `triggerJump()`:

```swift
private func triggerPomoComplete() {
    showPomoComplete = true
    Task { @MainActor [weak self] in
        try? await Task.sleep(for: .seconds(0.7))
        self?.showPomoComplete = false
    }
}
```

Call from `gainPomodoroExp()` immediately after `triggerExcitement()`:

```swift
triggerExcitement()
triggerPomoComplete()   // ← new
```

(Note: `gainCommitExp()` calls `triggerJump()`, not `triggerPomoComplete()`. `gainPomodoroExp()` calls `triggerPomoComplete()`, not `triggerJump()`. They are separate.)

### 2. ContentView.swift — add offset + animation for pomo complete

In `characterSection`, immediately after the commit jump modifiers:

**Before:**
```swift
                .offset(y: pet.showJump ? -22 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

**After:**
```swift
                .offset(y: pet.showJump ? -22 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: pet.showJump)
                .offset(y: pet.showPomoComplete ? -28 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.3), value: pet.showPomoComplete)
                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
```

The two `.offset()` modifiers are independent. If both fire simultaneously (extremely unlikely — commit and pomodoro complete at the same instant), they add: -22 + -28 = -50pt, which is fine.

## Animation Feel vs Commit Jump

| | Commit Jump | Pomo Complete |
|---|---|---|
| Offset | -22pt | -28pt |
| Spring response | 0.3 | 0.35 |
| Damping fraction | 0.4 (less bouncy) | 0.3 (more bouncy) |
| Duration | 0.5s | 0.7s |

Pomo complete is bigger, bouncier, and longer — fitting for a 25-minute achievement vs a single commit.

## What Does NOT Change

- `gainCommitExp()` — still calls only `triggerJump()`
- `PomodoroTimer` internal state machine — unchanged
- `PetView`, `SlimeView`, other views — unchanged
- Any other file
