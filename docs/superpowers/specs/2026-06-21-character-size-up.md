# Character Size Up Design

## Goal

Make the pet and pixel background larger in the home tab so the character area feels impactful rather than cramped.

## Architecture

Single file modified: `CruxPet/ContentView.swift` — `characterSection` computed var only.

## Changes

### 1. ZStack height
Add `.frame(height: 180)` to the ZStack in `characterSection`. This forces the pixel background to fill 180px vertically, showing more sky and grass.

**Before:**
```swift
ZStack {
    PixelBackgroundView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    Circle()
        .fill(Color.blue.opacity(0.06))
        .frame(width: 90, height: 90)
        .blur(radius: 14)
    PetView(...)
        .scaleEffect(interaction.isTapped ? 1.25 : 1.0)
```

**After:**
```swift
ZStack {
    PixelBackgroundView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    Circle()
        .fill(Color.blue.opacity(0.06))
        .frame(width: 135, height: 135)
        .blur(radius: 14)
    PetView(...)
        .scaleEffect(interaction.isTapped ? 1.875 : 1.5)
```

### 2. PetView base scale: 1.0 → 1.5
- Rest state: `1.0` → `1.5`
- Tapped state: `1.25` → `1.875` (preserves the 1.25× tap ratio)

### 3. Circle glow size: 90×90 → 135×135
Scaled proportionally with the pet (90 × 1.5 = 135).

## What Does NOT Change

- All animation modifiers on PetView (spring, easeInOut) — unchanged
- CRITICAL / LEVEL UP overlays — unchanged
- treatButton, level badge, name, streakBadge, companionRow — unchanged
- goalSection — unchanged
- Any other section or file — unchanged

## Non-Goals

- No change to PetView internals or bodySize calculations
- No change to any other tab's layout
