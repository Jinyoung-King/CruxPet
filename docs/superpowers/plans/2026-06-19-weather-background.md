# Weather Background Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add day/night cycle to `PixelBackgroundView` — dark navy sky + twinkling stars at night, current blue sky + clouds during the day.

**Architecture:** Single file modified: `CruxPet/PixelBackgroundView.swift`. Reads `hour` from `tl.date` (already available in the existing `TimelineView`), derives `isNight`, and branches drawing accordingly. No new state, no new dependencies.

**Tech Stack:** SwiftUI Canvas, TimelineView, Calendar

---

### Task 1: Implement day/night cycle in PixelBackgroundView

**Files:**
- Modify: `CruxPet/PixelBackgroundView.swift`

No tests needed — pure visual, verified by build success and visual inspection.

- [ ] **Step 1: Replace PixelBackgroundView.swift with the complete implementation**

Overwrite `CruxPet/PixelBackgroundView.swift` with:

```swift
import SwiftUI

struct PixelBackgroundView: View {
    private let px: CGFloat = 4

    private let starPositions: [(CGFloat, CGFloat)] = [
        (0.08, 0.12), (0.22, 0.28), (0.38, 0.10), (0.51, 0.35),
        (0.63, 0.18), (0.74, 0.42), (0.85, 0.08), (0.92, 0.30)
    ]
    private let starFreqs:  [Double] = [0.9, 1.3, 0.7, 1.1, 1.5, 0.8, 1.2, 1.0]
    private let starPhases: [Double] = [0.0, 1.2, 2.4, 0.8, 1.9, 3.1, 0.4, 2.7]

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { context, size in
                var ctx = context
                let t    = tl.date.timeIntervalSinceReferenceDate
                let hour = Calendar.current.component(.hour, from: tl.date)
                let isNight = hour >= 20 || hour < 6
                draw(&ctx, size: size, t: t, isNight: isNight)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double, isNight: Bool) {
        let skyEndY    = floor(size.height * 0.65 / px) * px
        let dirtStartY = floor(size.height * 0.85 / px) * px

        ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: skyEndY)),
                 with: .color(isNight ? Color(hex: "#0D0D2B") : Color(hex: "#92C8E8")))
        ctx.fill(Path(CGRect(x: 0, y: skyEndY, width: size.width, height: px * 2)),
                 with: .color(isNight ? Color(hex: "#4A7A28") : Color(hex: "#7EC850")))
        ctx.fill(Path(CGRect(x: 0, y: skyEndY + px * 2,
                             width: size.width,
                             height: dirtStartY - skyEndY - px * 2)),
                 with: .color(isNight ? Color(hex: "#2E5A18") : Color(hex: "#5BA832")))
        ctx.fill(Path(CGRect(x: 0, y: dirtStartY,
                             width: size.width,
                             height: size.height - dirtStartY)),
                 with: .color(isNight ? Color(hex: "#5C3D22") : Color(hex: "#8B5E3C")))

        if isNight {
            drawStars(&ctx, size: size, t: t, skyEndY: skyEndY)
        } else {
            drawCloud(&ctx, size: size, t: t, bodyW: 12, speed: 12, yBlock: 4, phase: 0)
            drawCloud(&ctx, size: size, t: t, bodyW: 10, speed: 7,  yBlock: 8, phase: 120)
        }
    }

    private func drawStars(_ ctx: inout GraphicsContext, size: CGSize, t: Double, skyEndY: CGFloat) {
        for i in starPositions.indices {
            let (xRatio, yRatio) = starPositions[i]
            let opacity = 0.7 + sin(t * starFreqs[i] + starPhases[i]) * 0.2
            let x = xRatio * size.width
            let y = yRatio * skyEndY
            ctx.fill(Path(CGRect(x: x, y: y, width: px, height: px)),
                     with: .color(Color.white.opacity(opacity)))
        }
    }

    private func drawCloud(_ ctx: inout GraphicsContext, size: CGSize, t: Double,
                           bodyW: Int, speed: Double, yBlock: CGFloat, phase: CGFloat) {
        let cloudW = CGFloat(bodyW) * px
        let bumpW  = bodyW / 2
        let total  = size.width + cloudW
        let x = (CGFloat(t * speed) + phase).truncatingRemainder(dividingBy: total) - cloudW
        let y = yBlock * px

        ctx.fill(Path(CGRect(x: x, y: y, width: cloudW, height: px * 2)),
                 with: .color(Color.white.opacity(0.88)))

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

Note: `Color(hex:)` is defined in `CruxPet/SlimeView.swift` and is available module-wide.

- [ ] **Step 2: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/PixelBackgroundView.swift
git commit -m "feat: add day/night cycle to pixel background"
```
