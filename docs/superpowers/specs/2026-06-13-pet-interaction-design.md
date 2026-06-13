# Pet Interaction Design

## Goal

Add tap and feed interactions to the pet: tapping triggers a bounce animation + floating heart particles + temporary `.happy` emotion; feeding with a treat button grants EXP and triggers an `.excited` emotion, with a 30-minute cooldown persisted across app restarts.

## Architecture

### PetInteractionModel (`PetInteractionModel.swift`)

New `@MainActor @Observable` class injected via SwiftUI environment.

```swift
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

    func tap(pet: PetModel) {
        // 1. Bounce
        isTapped = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isTapped = false
        }
        // 2. Particles
        showParticles = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            showParticles = false
        }
        // 3. Emotion → .happy for 2s
        pet.setTemporaryEmotion(.happy, duration: 2.0)
    }

    func feed(pet: PetModel) {
        guard canFeed else { return }
        lastFedAt = Date()
        saveLastFed()
        // EXP
        pet.addExp(10)
        // Eating animation
        isEating = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            isEating = false
        }
        // Emotion → .excited for 1.5s
        pet.setTemporaryEmotion(.excited, duration: 1.5)
    }

    // MARK: - Persistence
    private static let lastFedKey = "cruxpet.lastFedAt"

    init() {
        if let ts = UserDefaults.standard.object(forKey: Self.lastFedKey) as? Double {
            lastFedAt = Date(timeIntervalSince1970: ts)
        }
    }

    private func saveLastFed() {
        UserDefaults.standard.set(lastFedAt?.timeIntervalSince1970, forKey: Self.lastFedKey)
    }
}
```

### PetModel additions

Add `setTemporaryEmotion(_:duration:)` to `PetModel`. Since `updateEmotion()` is already a private method that computes the correct idle emotion (happy/normal/sleepy based on minutes since last commit), the restore simply calls it:

```swift
func setTemporaryEmotion(_ emotion: EmotionState, duration: Double) {
    self.emotion = emotion
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(duration))
        self.updateEmotion()  // restore idle emotion
    }
}
```

`updateEmotion()` remains private — `setTemporaryEmotion` is defined inside `PetModel` so it has direct access.

### ContentView changes

1. Add `@Environment(PetInteractionModel.self) private var interaction`
2. Wrap PetView in a `ZStack` with a particle overlay:

```swift
ZStack {
    PetView(...)
        .scaleEffect(interaction.isTapped ? 1.25 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.4), value: interaction.isTapped)
        .onTapGesture { interaction.tap(pet: pet) }

    if interaction.showParticles {
        ParticleOverlayView()
    }
}
```

3. Add treat button below the pet area:

```swift
Button {
    interaction.feed(pet: pet)
} label: {
    HStack(spacing: 3) {
        Text(interaction.isEating ? "😋" : "🍬")
            .font(.system(size: 13))
        if !interaction.canFeed {
            Text(cooldownLabel)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}
.buttonStyle(.plain)
.disabled(!interaction.canFeed)
.opacity(interaction.canFeed ? 1.0 : 0.45)
```

`cooldownLabel` formats `interaction.cooldownRemaining` as `"29분"` using `Int(cooldownRemaining / 60) + 1`.

### ParticleOverlayView

New small view in `ContentView.swift` (private, below the main view). Three `Text("❤️")` instances with staggered offsets — each floats upward (`offset(y: -30)`) and fades out over ~0.8s using `.animation(.easeOut(duration: 0.8))` triggered by `showParticles`.

### CruxPetApp.swift

Add `.environment(PetInteractionModel())` alongside existing environment objects.

---

## Behavior Summary

| Action | Animation | Emotion | EXP |
|---|---|---|---|
| Tap pet | Bounce (scale 1.25, spring) + 3 hearts float up | `.happy` for 2s | none |
| Feed (🍬) | 🍬 → 😋, treat floats to pet | `.excited` for 1.5s | +10 |
| Feed (cooldown) | Button greyed, shows "X분" | — | — |

## Cooldown

- Duration: 30 minutes
- Persisted: `UserDefaults` key `cruxpet.lastFedAt` (Unix timestamp)
- Survives app restart

## Files

| File | Action |
|---|---|
| `CruxPet/PetInteractionModel.swift` | Create |
| `CruxPet/PetModel.swift` | Add `setTemporaryEmotion(_:duration:)` + `computedEmotion` |
| `CruxPet/ContentView.swift` | Tap gesture, scaleEffect, ParticleOverlayView, treat button |
| `CruxPet/CruxPetApp.swift` | Add `.environment(PetInteractionModel())` |
| `CruxPetTests/PetInteractionModelTests.swift` | Create — canFeed, cooldown, feed EXP tests |

## What This Does NOT Change

- PetView renderers (CatView, DogView, etc.) — unchanged
- Quest/achievement systems — unchanged
- EXP formula — `addExp(10)` uses existing logic
