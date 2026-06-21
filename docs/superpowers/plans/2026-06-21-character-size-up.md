# Character Size Up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the pet and pixel background larger in the home tab by giving the characterSection ZStack a fixed 180px height, scaling the pet to 1.5×, and resizing the glow circle proportionally.

**Architecture:** Three targeted edits to `characterSection` in `CruxPet/ContentView.swift`. No other files touched.

**Tech Stack:** SwiftUI

---

### Task 1: Enlarge character section in ContentView.swift

**Files:**
- Modify: `CruxPet/ContentView.swift` (`characterSection` computed var, lines ~381–428)

No tests needed — pure visual change, verified by build success and visual inspection.

- [ ] **Step 1: Add `.frame(height: 180)` to the characterSection ZStack**

In `CruxPet/ContentView.swift`, find:

```swift
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            .animation(.spring(duration: 0.4), value: pet.showLevelUp)
            treatButton
```

Replace with:

```swift
            .frame(height: 180)
            .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
            .animation(.spring(duration: 0.4), value: pet.showLevelUp)
            treatButton
```

- [ ] **Step 2: Scale PetView from 1.0→1.5 at rest, 1.25→1.875 when tapped**

Find:

```swift
                .scaleEffect(interaction.isTapped ? 1.25 : 1.0)
```

Replace with:

```swift
                .scaleEffect(interaction.isTapped ? 1.875 : 1.5)
```

- [ ] **Step 3: Resize the glow circle from 90×90 to 135×135**

Find:

```swift
                Circle()
                    .fill(Color.blue.opacity(0.06))
                    .frame(width: 90, height: 90)
                    .blur(radius: 14)
```

Replace with:

```swift
                Circle()
                    .fill(Color.blue.opacity(0.06))
                    .frame(width: 135, height: 135)
                    .blur(radius: 14)
```

- [ ] **Step 4: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: enlarge character section (180px height, 1.5x pet scale)"
```
