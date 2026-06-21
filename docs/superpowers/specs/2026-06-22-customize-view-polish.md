# CustomizeView Design Polish

## Goal

Make `CustomizeView` visually consistent with the home screen (`ContentView`): enhanced pet preview with pixel background, styled section panels, and unified corner radii/typography. One file changes: `CruxPet/CustomizeView.swift`.

## Deployment Target

macOS 14.6

## Changes

### 1. Pet Preview — Enhanced (lines 31–40)

**Before:**
```swift
PetView(
    petType: draft.petType,
    appearance: previewAppearance,
    level: petLevel,
    emotion: .normal,
    accessories: draft.accessories,
    isPomodoroActive: false,
    isWandering: false
)
.frame(height: 80)
```

**After:**
```swift
ZStack {
    PixelBackgroundView()
    Circle()
        .fill(Color.blue.opacity(0.06))
        .frame(width: 100, height: 100)
        .blur(radius: 14)
    PetView(
        petType: draft.petType,
        appearance: previewAppearance,
        level: petLevel,
        emotion: .normal,
        accessories: draft.accessories,
        isPomodoroActive: false,
        isWandering: false
    )
}
.frame(height: 130)
.clipShape(RoundedRectangle(cornerRadius: 8))
```

Height increases 80pt → 130pt. `PixelBackgroundView` and blue blur circle match the exact pattern from `characterSection` in `ContentView.swift` (blur circle scaled to 100pt to fit the smaller preview).

### 2. Section Panels — Styled backgrounds replacing plain Dividers

Remove the three plain `Divider()` views (lines 42, 79, after accessories section). Instead, wrap each functional section in a styled panel.

Each section wrapper:
```swift
VStack(alignment: .leading, spacing: 6) {
    // section header label
    // section content
}
.padding(10)
.background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.04)))
```

Sections to wrap (5 total):
1. **Pet Type** — currently lines 44–77
2. **Name** — currently lines 82–90
3. **Color** — currently lines 92–119
4. **Accessories** — currently lines 121–166
5. **Pomodoro + Daily Goals** — group these two into one panel (currently lines 168–198)

### 3. Corner Radius — 6pt → 8pt throughout

All `RoundedRectangle(cornerRadius: 6)` and `cornerRadius: 6` in the file → `cornerRadius: 8`.

Affected locations:
- Pet type button border (in `petTypeButton`)
- Name TextField border  
- Color circle selection stroke
- Any other inline usages

### 4. Section Header Typography — Unified style

All section header labels (e.g., "이름", "색상", "악세사리", "포모도로 시간", "일일 목표"):

**Before:** `.font(.caption)` or `.font(.system(size: 9))`

**After:** `.font(.caption.bold()).foregroundStyle(.secondary)`

This matches the `.caption.bold()` style used in StatsView's section headers.

## What Does NOT Change

- All functionality (save/cancel/stepper/color/accessory logic) — unchanged
- `draft` state management — unchanged
- Panel width (220pt) — unchanged
- `previewAppearance` computed property — unchanged
- Button styles (Cancel/Save/Update) — unchanged
- Any Korean text content — unchanged
