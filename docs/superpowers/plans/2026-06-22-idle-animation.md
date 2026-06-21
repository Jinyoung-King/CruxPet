# Idle Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a floating ZZZ overlay above the pet when it has been idle (no commits/pomodoros) for 45+ minutes.

**Architecture:** `PetModel` already tracks `lastActivityDate` and already sets `emotion = .sleepy` after 45 minutes of inactivity via `updateEmotion()`. We expose that as a computed `isIdleSleeping` property, then add a looping `ZzzOverlayView` wired into `characterSection`. Two tasks, two files.

**Tech Stack:** SwiftUI, Swift, macOS 14.6

---

### Task 1: Add `isIdleSleeping` computed property to PetModel

**Files:**
- Modify: `CruxPet/PetModel.swift`

**Context:** `PetModel` is `@Observable`. `emotion: EmotionState` (private(set)) is already set to `.sleepy` by the existing `updateEmotion()` which fires on the 60-second emotion timer. `.sleepy` is only ever set by `updateEmotion()` — never manually — so `emotion == .sleepy` is a reliable idle signal.

- [ ] **Step 1: Add the computed property**

In `CruxPet/PetModel.swift`, find the line:
```swift
private(set) var emotion: EmotionState = .normal
```
(around line 50)

Add immediately after it:
```swift
var isIdleSleeping: Bool { emotion == .sleepy }
```

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/PetModel.swift
git commit -m "feat: expose isIdleSleeping computed property on PetModel"
```

---

### Task 2: Add `ZzzOverlayView` and wire into `characterSection`

**Files:**
- Modify: `CruxPet/ContentView.swift`

**Context:** `ContentView.swift` is ~1042 lines. `characterSection` is a computed property (around lines 391–477) containing a ZStack with `PixelBackgroundView`, blur circle, `PetView`, and conditional overlays (`ParticleOverlayView`, CRITICAL label, LEVEL UP badge, `LevelUpParticleView`). Private struct views are declared at the bottom of the file. The last private struct is `ParticleOverlayView` (around line 1016).

- [ ] **Step 1: Add `ZzzOverlayView` struct**

In `CruxPet/ContentView.swift`, find `ParticleOverlayView` (the last private struct, around line 1016). Add the new struct **before** it:

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

- [ ] **Step 2: Wire `ZzzOverlayView` into `characterSection`**

In `CruxPet/ContentView.swift`, find the block that ends the ZStack in `characterSection`. Look for the pattern (around line 455–465):

```swift
                if pet.showLevelUp {
                    LevelUpParticleView()
                        .id(pet.level)
                        .transition(.opacity)
                }
            }
            .frame(height: 220)
            .clipped()
```

Replace with:

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
            .clipped()
```

- [ ] **Step 3: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: add ZZZ overlay when pet is idle for 45+ minutes"
```
