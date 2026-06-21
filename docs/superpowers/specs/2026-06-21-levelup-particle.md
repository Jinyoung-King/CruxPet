# Level-Up Particle Effect Design

## Goal

Show 8 sparkle (✨) particles fanning upward from the pet when `pet.showLevelUp` fires — a distinct celebration moment separate from the tap-heart particles.

## Architecture

One new private struct `LevelUpParticleView` added to `CruxPet/ContentView.swift` (near the existing `ParticleOverlayView`). One new conditional `if pet.showLevelUp { LevelUpParticleView() }` block added inside `characterSection`'s ZStack, immediately after the existing LEVEL UP badge block.

No PetModel changes. `showLevelUp` already stays true for 2 seconds — sufficient for the 1.39s total particle sequence (0.9s duration + 7 × 0.07s stagger).

## Changes

### 1. New `LevelUpParticleView` struct

Add after `ParticleOverlayView` (currently at line 980 of `ContentView.swift`):

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
```

### 2. Add to `characterSection` ZStack

In `characterSection`, immediately after the existing `if pet.showLevelUp { Text("🎉 LEVEL UP!") ... }` block:

**Before:**
```swift
                if pet.showLevelUp {
                    Text("🎉 LEVEL UP!")
                        ...
                }
            }
            .frame(height: 220)
```

**After:**
```swift
                if pet.showLevelUp {
                    Text("🎉 LEVEL UP!")
                        ...
                }
                if pet.showLevelUp {
                    LevelUpParticleView()
                }
            }
            .frame(height: 220)
```

## Animation Parameters

| Property | Value |
|---|---|
| Particle count | 8 |
| Emoji | ✨ |
| Font size | 14pt |
| Duration | 0.9s easeOut per particle |
| Stagger | 70ms between particles |
| Total sequence | ~1.39s |
| `showLevelUp` window | 2s (existing) |
| X spread | -55pt to +55pt (fanned) |
| Y height | -70pt to -88pt (center particles fly highest) |

## What Does NOT Change

- `PetModel.swift` — no changes
- The existing `ParticleOverlayView` (tap hearts) — unchanged
- The "🎉 LEVEL UP!" badge — unchanged
- Any other file
