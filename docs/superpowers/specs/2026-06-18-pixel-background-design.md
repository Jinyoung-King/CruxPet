# Pixel Background Design

## Goal

Add an animated pixel art background (sky + grass + moving clouds) to the character section in ContentView.

## Architecture

Two files touched, no new dependencies:

### `CruxPet/PixelBackgroundView.swift` (new)
Self-contained Canvas + TimelineView view. Draws sky, ground, and animated clouds using 4pt pixel blocks. Owns no external state — all animation is time-driven.

### `CruxPet/ContentView.swift`
`characterSection` wraps its existing ZStack content with `PixelBackgroundView()` as the bottom-most layer. No other changes.

## Visual Layers

Pixel block size: **4pt** (sharp on Retina at 8 physical pixels per block).

| Layer | Position | Color |
|-------|----------|-------|
| Sky | Top 65% | `#92C8E8` |
| Cloud A | Sky, upper-mid | White `#FFFFFF` + light gray `#E8E8E8` blocks |
| Cloud B | Sky, lower-mid | Same, offset by half width |
| Grass top | Row at 65% mark | `#7EC850` |
| Grass fill | 65%–85% | `#5BA832` |
| Dirt | Bottom 15% | `#8B5E3C` |

Clouds are rectangular pixel-block clusters (wide flat rectangles, 3–4 blocks tall, 10–14 blocks wide).

## Animation

Uses `TimelineView(.animation)` — same timing source as SlimeView, no extra timers.

- **Cloud A**: `xOffset = (t * 12).truncatingRemainder(dividingBy: width + cloudAWidth)` — scrolls left→right, wraps
- **Cloud B**: starts at `width * 0.55` offset, speed `t * 7` — slower, different height, creates parallax

Both clouds reappear from the left edge when they exit the right edge.

## ContentView Integration

`characterSection` currently:
```swift
VStack(spacing: 6) {
    ZStack { PetView(...) ... }
    ...
}
```

After:
```swift
VStack(spacing: 6) {
    ZStack {
        PixelBackgroundView()      // added, bottom layer
        PetView(...) ...
    }
    ...
}
```

`PixelBackgroundView` uses `.frame(maxWidth: .infinity, maxHeight: .infinity)` so it fills whatever space the ZStack gives it.

## Non-Goals

- No theme selection (single scene only)
- No day/night switching
- No additional elements beyond clouds (no birds, sun, stars)
- No user-configurable settings for the background
