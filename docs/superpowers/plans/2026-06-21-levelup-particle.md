# Level-Up Particle Effect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show 8 sparkle particles fanning upward from the pet when a level-up occurs.

**Architecture:** One new `LevelUpParticleView` struct added to `ContentView.swift` (after `ParticleOverlayView`), and one `if pet.showLevelUp { LevelUpParticleView() }` block inserted in `characterSection`'s ZStack after the existing LEVEL UP badge. No PetModel changes — `showLevelUp` (2-second window) already exists.

**Tech Stack:** SwiftUI, Swift

---

### Task 1: Add `LevelUpParticleView` and wire it into `characterSection`

**Files:**
- Modify: `CruxPet/ContentView.swift` (lines ~437–438 for ZStack insertion; lines ~993–995 for new struct)

- [ ] **Step 1: Add `LevelUpParticleView()` to the `characterSection` ZStack**

In `CruxPet/ContentView.swift`, find:

```swift
                }
            }
            .frame(height: 220)
            .clipped()
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            .animation(.spring(duration: 0.4), value: pet.showLevelUp)
```

(This closing `}` on line 437 ends the `if pet.showLevelUp { Text("🎉 LEVEL UP!") ... }` block; the next `}` closes the ZStack.)

Replace with:

```swift
                }
                if pet.showLevelUp {
                    LevelUpParticleView()
                }
            }
            .frame(height: 220)
            .clipped()
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            .animation(.spring(duration: 0.4), value: pet.showLevelUp)
```

- [ ] **Step 2: Add the `LevelUpParticleView` struct**

In `CruxPet/ContentView.swift`, find:

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
```

Replace with:

```swift
private struct LevelUpParticleView: View {
    @State private var floated = false

    private let xOffsets: [CGFloat] = [-55, -35, -15, 5, -5, 15, 35, 55]
    private let yOffsets: [CGFloat] = [-70, -80, -85, -88, -88, -85, -80, -70]

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Text("✨")
                    .font(.system(size: 14))
                    .offset(x: floated ? xOffsets[i] : 0,
                            y: floated ? yOffsets[i] : 0)
                    .opacity(floated ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.9).delay(Double(i) * 0.07),
                        value: floated
                    )
            }
        }
        .onAppear { floated = true }
    }
}

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
git commit -m "feat: add sparkle particle burst on level-up"
```
