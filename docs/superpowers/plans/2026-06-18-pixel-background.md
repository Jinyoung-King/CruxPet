# Pixel Background Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an animated pixel art background (sky + grass + moving clouds) behind the pet in the character section.

**Architecture:** New `PixelBackgroundView.swift` using SwiftUI `Canvas + TimelineView` — same pattern as `SlimeView.swift`. Added as the bottom layer of the `characterSection` ZStack in `ContentView.swift`. No new state, no new dependencies.

**Tech Stack:** SwiftUI Canvas, TimelineView

---

### Task 1: Create PixelBackgroundView.swift

**Files:**
- Create: `CruxPet/PixelBackgroundView.swift`

No tests needed — pure visual, verified by build success and visual inspection.

- [ ] **Step 1: Create the file**

Create `CruxPet/PixelBackgroundView.swift` with the complete implementation below:

```swift
import SwiftUI

struct PixelBackgroundView: View {
    private let px: CGFloat = 4

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { context, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                draw(&context, size: size, t: t)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let skyEndY    = floor(size.height * 0.65 / px) * px
        let dirtStartY = floor(size.height * 0.85 / px) * px

        // Sky
        ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: skyEndY)),
                 with: .color(Color(hex: "#92C8E8")))

        // Grass top highlight row
        ctx.fill(Path(CGRect(x: 0, y: skyEndY, width: size.width, height: px * 2)),
                 with: .color(Color(hex: "#7EC850")))

        // Grass fill
        ctx.fill(Path(CGRect(x: 0, y: skyEndY + px * 2,
                             width: size.width,
                             height: dirtStartY - skyEndY - px * 2)),
                 with: .color(Color(hex: "#5BA832")))

        // Dirt
        ctx.fill(Path(CGRect(x: 0, y: dirtStartY,
                             width: size.width,
                             height: size.height - dirtStartY)),
                 with: .color(Color(hex: "#8B5E3C")))

        // Cloud A: 12 blocks wide, speed 12, y at row 4
        drawCloud(&ctx, size: size, t: t,
                  bodyW: 12, bumpW: 6, speed: 12, yBlock: 4, phase: 0)

        // Cloud B: 10 blocks wide, speed 7, y at row 8, starts further right
        drawCloud(&ctx, size: size, t: t,
                  bodyW: 10, bumpW: 5, speed: 7, yBlock: 8, phase: size.width * 0.55)
    }

    private func drawCloud(_ ctx: inout GraphicsContext, size: CGSize, t: Double,
                           bodyW: Int, bumpW: Int,
                           speed: Double, yBlock: CGFloat, phase: CGFloat) {
        let cloudW = CGFloat(bodyW) * px
        let total  = size.width + cloudW
        let x = (CGFloat(t * speed) + phase).truncatingRemainder(dividingBy: total) - cloudW
        let y = yBlock * px

        // Main body (2 blocks tall)
        ctx.fill(Path(CGRect(x: x, y: y, width: cloudW, height: px * 2)),
                 with: .color(Color.white.opacity(0.88)))

        // Bump on top (1 block tall, centered)
        let bumpX = x + (cloudW - CGFloat(bumpW) * px) / 2
        ctx.fill(Path(CGRect(x: bumpX, y: y - px, width: CGFloat(bumpW) * px, height: px)),
                 with: .color(Color.white.opacity(0.88)))
    }
}

#Preview {
    PixelBackgroundView()
        .frame(width: 220, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8))
}
```

Note: `Color(hex:)` is defined in `CruxPet/SlimeView.swift` and is available module-wide — no import needed.

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/PixelBackgroundView.swift
git commit -m "feat: add PixelBackgroundView with animated pixel sky and grass"
```

---

### Task 2: Integrate into ContentView characterSection

**Files:**
- Modify: `CruxPet/ContentView.swift:360-402`

- [ ] **Step 1: Add PixelBackgroundView as first ZStack child**

In `CruxPet/ContentView.swift`, find `characterSection` (around line 358). The ZStack currently opens with a `Circle()` glow. Add `PixelBackgroundView()` before it:

```swift
// BEFORE (line 360):
ZStack {
    Circle()
        .fill(Color.blue.opacity(0.06))
        .frame(width: 90, height: 90)
        .blur(radius: 14)
    PetView(

// AFTER:
ZStack {
    PixelBackgroundView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    Circle()
        .fill(Color.blue.opacity(0.06))
        .frame(width: 90, height: 90)
        .blur(radius: 14)
    PetView(
```

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: show pixel background in character section"
```
