# Pomodoro Tab Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `pomodoroSection` from a compact card widget to a full-tab layout with a larger timer, larger buttons, and vertical centering.

**Architecture:** Five targeted edits to `pomodoroSection` in `CruxPet/ContentView.swift`. No other files touched.

**Tech Stack:** SwiftUI

---

### Task 1: Polish pomodoroSection in ContentView.swift

**Files:**
- Modify: `CruxPet/ContentView.swift` (`pomodoroSection` computed var, lines ~722–792)

No tests needed — pure visual change, verified by build success and visual inspection.

- [ ] **Step 1: Increase VStack spacing from 7 to 16 and add top Spacer**

In `CruxPet/ContentView.swift`, find:

```swift
        return VStack(spacing: 7) {
            HStack(spacing: 4) {
```

Replace with:

```swift
        return VStack(spacing: 16) {
            Spacer()
            HStack(spacing: 4) {
```

- [ ] **Step 2: Increase timer font from 30pt to 48pt**

Find:

```swift
                .font(.system(size: 30, weight: .bold, design: .monospaced))
```

Replace with:

```swift
                .font(.system(size: 48, weight: .bold, design: .monospaced))
```

- [ ] **Step 3: Increase session count font from 10pt to 13pt**

Find:

```swift
                    .font(.system(size: 10))
```

Replace with:

```swift
                    .font(.system(size: 13))
```

- [ ] **Step 4: Change all button controlSize from .small to .regular**

Find and replace every `.controlSize(.small)` in the file with `.controlSize(.regular)`. All occurrences are inside `pomodoroSection` so replace-all is safe.

There are 8 occurrences (one per Button in the switch block).

- [ ] **Step 5: Add bottom Spacer and replace card background with full-tab frame**

Find (lines ~778–791):

```swift
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(accent.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: pomodoro.state)
```

Replace with:

```swift
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: pomodoro.state)
```

The two `Spacer()` calls (top and bottom) vertically center the fixed-height content in the 340px tab area. The card border and background are removed since the tab provides its own background.

- [ ] **Step 6: Build to verify no errors**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: polish pomodoro tab (larger timer, buttons, full-tab layout)"
```
