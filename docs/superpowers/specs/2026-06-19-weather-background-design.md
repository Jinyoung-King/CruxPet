# Weather Background Design

## Goal

Add day/night cycle to `PixelBackgroundView` based on the current system hour. No external API, no new state — the view reads time internally from its existing `TimelineView`.

## Architecture

Single file modified: `CruxPet/PixelBackgroundView.swift`

`PixelBackgroundView` already drives animation via `TimelineView(.animation)`. The `tl.date` value inside the Canvas closure provides the current timestamp, from which `hour` is derived. No parameters added, no external dependencies.

## Day/Night States

| State | Hours | Sky Color |
|-------|-------|-----------|
| Day | 6:00–19:59 | `#92C8E8` (current blue) |
| Night | 20:00–5:59 | `#0D0D2B` (dark navy) |

## Visual Changes by State

### Day (unchanged)
- Sky: `#92C8E8`
- Grass highlight: `#7EC850`, grass fill: `#5BA832`, dirt: `#8B5E3C`
- Two animated clouds

### Night
- Sky: `#0D0D2B`
- Grass highlight: `#4A7A28`, grass fill: `#2E5A18`, dirt: `#5C3D22` (darkened versions)
- Clouds: hidden
- Stars: 8 fixed points defined as relative `(xRatio, yRatio)` coordinates in the sky area
  - Size: 1 pixel block (`px × px`)
  - Color: white, opacity = `0.7 + sin(t * freq + phase) * 0.2` per star (range 0.5–0.9)
  - Frequencies and phases (one per star, index-matched to position list):
    - freq: `[0.9, 1.3, 0.7, 1.1, 1.5, 0.8, 1.2, 1.0]`
    - phase: `[0.0, 1.2, 2.4, 0.8, 1.9, 3.1, 0.4, 2.7]`

## Star Positions

8 stars at fixed relative coordinates (x as fraction of width, y as fraction of sky height):

```
(0.08, 0.12), (0.22, 0.28), (0.38, 0.10), (0.51, 0.35),
(0.63, 0.18), (0.74, 0.42), (0.85, 0.08), (0.92, 0.30)
```

These are hardcoded — no randomness — so star positions are stable across frames.

## Implementation Notes

- `hour` is extracted via `Calendar.current.component(.hour, from: tl.date)`
- `isNight` = `hour >= 20 || hour < 6`
- Ground colors darken at night to match the darker sky
- No transition animation between states — hard cut is appropriate for pixel art

## Non-Goals

- No sunrise/sunset transition colors
- No moon graphic
- No precipitation (rain/snow)
- No user setting to override time
