# Pet Types Design

## Goal

Add three new pet types (cat, dog, ghost) that can be unlocked by level and selected as the main pet, replacing the slime renderer while sharing all existing game systems.

## Architecture

### PetType enum (`PetType.swift`)

```swift
enum PetType: String, Codable, CaseIterable {
    case slime, cat, dog, ghost

    var unlockLevel: Int {
        switch self {
        case .slime: return 0
        case .cat:   return 15
        case .dog:   return 25
        case .ghost: return 35
        }
    }

    var displayName: String { /* 슬라임, 고양이, 강아지, 유령 */ }
}
```

### PetView dispatcher (`PetType.swift`)

A single `PetView` struct replaces all direct `SlimeView` call sites. It takes all parameters both the slime and new types need, and dispatches to the right renderer.

```swift
struct PetView: View {
    let petType: PetType
    let appearance: SlimeAppearance   // used only when petType == .slime
    let level: Int                    // used by cat/dog/ghost
    let emotion: PetEmotion
    let environmentAccessories: [EnvironmentAccessory]
    let accessories: [AccessorySlot: String]
    let isPomodoroActive: Bool
    let isWandering: Bool

    var body: some View {
        switch petType {
        case .slime: SlimeView(appearance: appearance, ...)
        case .cat:   CatView(level: level, emotion: emotion, ...)
        case .dog:   DogView(level: level, emotion: emotion, ...)
        case .ghost: GhostView(level: level, emotion: emotion, ...)
        }
    }
}
```

New pet types receive `level: Int` directly and determine their own appearance internally — they do not use `SlimeAppearance`.

### New files

| File | Responsibility |
|---|---|
| `CruxPet/PetType.swift` | `PetType` enum + `PetView` dispatcher |
| `CruxPet/CatView.swift` | Canvas-based cat renderer |
| `CruxPet/DogView.swift` | Canvas-based dog renderer |
| `CruxPet/GhostView.swift` | Canvas-based ghost renderer |

### Modified files

| File | Change |
|---|---|
| `PetCustomization.swift` | Add `petType: PetType = .slime` field (Codable, backward-compatible) |
| `ContentView.swift` | Replace `SlimeView(...)` with `PetView(...)` |
| `CustomizeView.swift` | Add pet type picker section above color section |
| `ShareCardView.swift` | Replace `SlimeView(...)` with `PetView(...)` |

---

## Pet Visuals & Animations

All three new types share the same signature as SlimeView: Canvas-based, `TimelineView(.animation)`, same frame size.

### 🐱 CatView

**Shape:** Rounded body + head, pointy ears, long swinging tail.

**Unique animation:** Tail swings on a sin curve (`sin(t * 1.8)`), offset left/right relative to body. When `isWandering`, ears twitch slightly.

**Pomodoro active:** Fast bob (higher frequency), tail whips faster.

**Emotion expressions:**
- `.normal` — neutral eyes
- `.happy` — crescent eyes (^_^)
- `.sleepy` — droopy half-closed eyes
- `.excited` — wide open eyes, tail straight up

**Level-based appearance:**
- Lv.1–14: plain orange tabby
- Lv.15–24: cleaner markings, small bow
- Lv.25–34: shinier coat, sparkle on tail tip
- Lv.35+: golden crown, rainbow shimmer on fur

---

### 🐶 DogView

**Shape:** Round body + head, large floppy ears, short wagging tail.

**Unique animation:** Tail wags (`sin(t * 3.0)`) left/right. Ears droop and lift in sync with bob.

**Pomodoro active:** Ears flap fast, body bounces (jump motion).

**Emotion expressions:**
- `.normal` — big nose, closed mouth
- `.happy` — tongue out, eyes squinted
- `.sleepy` — eyes half-closed, ears drooped low
- `.excited` — all four paws off ground (float offset), ears up

**Level-based appearance:**
- Lv.1–24: no collar, beige coat
- Lv.25–29: simple collar appears
- Lv.30–34: collar with small gem, fluffier body
- Lv.35+: jeweled collar, golden sparkles

---

### 👻 GhostView

**Shape:** Oval head with wavy/scalloped bottom edge, large round eyes, translucent fill.

**Unique animation:** Gentle float (`sin(t * 0.7) * 3.0`), slightly slower than slime. Body opacity pulses gently (0.75–0.95).

**Pomodoro active:** Spins slowly (`rotation(t * 30°)`), leaves ghost trail fading.

**Emotion expressions:**
- `.normal` — round eyes, small O mouth
- `.happy` — crescent eyes, wide smile
- `.sleepy` — X eyes, drooped
- `.excited` — spinning faster, sparkles

**Environment interaction:** When `timeOfDay` is `.night`, `.dawn`, or `.evening`, ghost opacity increases to 1.0 and a subtle glow appears.

**Level-based appearance:**
- Lv.1–34: light blue-grey, semi-transparent
- Lv.35–39: brighter white, slight glow
- Lv.40–44: golden sparkles around edge
- Lv.45+: crown, rainbow pulse on edge

---

## Unlock & Selection UI

### Unlock conditions

| Pet | Unlock level |
|---|---|
| 슬라임 | 0 (default) |
| 고양이 | 15 |
| 강아지 | 25 |
| 유령 | 35 |

When the player reaches the unlock level, no special notification is shown — the type simply becomes selectable in CustomizeView.

### CustomizeView pet type picker

Inserted as the first section in CustomizeView, above the name field. A horizontal row of 4 buttons (슬라임 / 고양이 / 강아지 / 유령):

- **Unlocked + selected:** filled blue background, white text
- **Unlocked + unselected:** bordered, normal text
- **Locked:** greyed out, lock icon, "Lv.XX~" label

Tapping an unlocked type immediately updates `draft.petType` and the live preview above reflects it.

### Accessories and color

Accessories and custom color are shared across all pet types — they are not stored per-type. The color overlay applies to the new pet types the same way it applies to the slime (as a tint on the body fill color).

---

## Data model change

`PetCustomization` gains one new field:

```swift
var petType: PetType = .slime
```

Added to both `CodingKeys` and `init(from:)` with `decodeIfPresent` defaulting to `.slime` for backward compatibility. Existing saved customizations continue to load correctly as slime.

---

## What this does NOT change

- Level/EXP system — unchanged
- `SlimeAppearance` — unchanged, still used by `.slime`
- Companion slimes (`CompanionSlimeView`) — separate system, unchanged
- Achievement/quest systems — unchanged
- `PetModel.appearance(for:)` — still returns `SlimeAppearance`, used only by `PetView` when `petType == .slime`
