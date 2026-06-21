# Idle Animation Design

## Goal

After 20 minutes of no commits or pomodoros, the pet automatically enters a sleep state: `emotion` drops to `.sleepy` (existing slow-animation effect) and a ZZZ overlay floats above the pet. Any new activity immediately wakes the pet.

## Deployment Target

macOS 14.6 — no new APIs required.

## Architecture

Two files change:

| File | What changes |
|---|---|
| `CruxPet/PetModel.swift` | Add `lastActivityDate`, `isIdleSleeping`; update `updateEmotion()`, `gainCommitExp()`, `gainPomodoroExp()` |
| `CruxPet/ContentView.swift` | Add `ZzzOverlayView` struct; wire into `characterSection` ZStack |

No new files. No PetType/Canvas changes.

## PetModel Changes

### New properties

```swift
var lastActivityDate: Date = .now
private(set) var isIdleSleeping: Bool = false
```

`lastActivityDate` persists across app restarts via `UserDefaults` (key `"lastActivityDate"`). Default on first launch: `.now`.

### Idle check in `updateEmotion()`

`updateEmotion()` already runs every 60 seconds via `emotionTimer`. Append idle logic at the end:

```swift
let idleThreshold: TimeInterval = 1200  // 20 minutes
if Date().timeIntervalSince(lastActivityDate) >= idleThreshold {
    if !isIdleSleeping {
        isIdleSleeping = true
        emotion = .sleepy
    }
} else {
    if isIdleSleeping {
        isIdleSleeping = false
        // emotion restored to normal by the rest of updateEmotion() logic
    }
}
```

The `isIdleSleeping = true` branch only fires once (guarded by `!isIdleSleeping`), so it doesn't stomp happy/excited emotions set by concurrent events.

### Activity reset

In `gainCommitExp()` and `gainPomodoroExp()`, add at the top of each function:

```swift
lastActivityDate = .now
UserDefaults.standard.set(lastActivityDate, forKey: "lastActivityDate")
if isIdleSleeping {
    isIdleSleeping = false
}
```

### UserDefaults load in `init()`

Add after the existing UserDefaults loads:

```swift
if let saved = UserDefaults.standard.object(forKey: "lastActivityDate") as? Date {
    lastActivityDate = saved
}
```

## ContentView Changes

### ZzzOverlayView struct

Add after `LevelUpParticleView` (currently the last private struct in the file):

```swift
private struct ZzzOverlayView: View {
    @State private var floated = false

    private let sizes: [CGFloat] = [8, 11, 14]
    private let xTargets: [CGFloat] = [10, 20, 32]
    private let yTargets: [CGFloat] = [-18, -32, -48]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Text("z")
                    .font(.system(size: sizes[i], weight: .bold, design: .rounded))
                    .foregroundStyle(.indigo.opacity(0.7))
                    .offset(
                        x: floated ? xTargets[i] : 0,
                        y: floated ? yTargets[i] : 0
                    )
                    .opacity(floated ? 0 : 0.85)
                    .animation(
                        .easeOut(duration: 1.4)
                            .delay(Double(i) * 0.5)
                            .repeatForever(autoreverses: false),
                        value: floated
                    )
            }
        }
        .onAppear { floated = true }
    }
}
```

**Parameters:**

| Property | Value |
|---|---|
| Bubble count | 3 ("z", "z", "z" — ascending size) |
| Sizes | 8pt, 11pt, 14pt |
| Color | `.indigo.opacity(0.7)` |
| X drift | +10, +20, +32pt (diagonally right) |
| Y rise | -18, -32, -48pt |
| Duration | 1.4s easeOut per bubble |
| Stagger | 0.5s between bubbles |
| Loop | `repeatForever(autoreverses: false)` |

### Wire into characterSection

In `characterSection`, in the ZStack immediately after the existing `if pet.showLevelUp { LevelUpParticleView() }` block:

**Before:**
```swift
                if pet.showLevelUp {
                    LevelUpParticleView()
                        .id(pet.level)
                        .transition(.opacity)
                }
            }
            .frame(height: 220)
```

**After:**
```swift
                if pet.showLevelUp {
                    LevelUpParticleView()
                        .id(pet.level)
                        .transition(.opacity)
                }
                if pet.isIdleSleeping {
                    ZzzOverlayView()
                        .transition(.opacity)
                }
            }
            .frame(height: 220)
```

## What Does NOT Change

- `EmotionState` enum — no new cases
- `SlimeView`, `CatView`, `DogView`, `GhostView` — no canvas changes
- All other files
- The existing `triggerExcitement()` / `setTemporaryEmotion()` paths — if excitement fires while sleeping, it overrides `.sleepy` naturally (emotion gets set to `.excited`), and `isIdleSleeping` gets cleared on next activity
