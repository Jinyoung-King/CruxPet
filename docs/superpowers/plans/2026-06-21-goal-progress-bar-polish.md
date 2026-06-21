# Goal Progress Bar Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the existing goal progress bars in `DailyGoalView` with animated fill, taller bars, and a subtle green row highlight when a goal is completed.

**Architecture:** All three changes are inside `DailyGoalView.goalRow()` in a single file (`CruxPet/ContentView.swift`). No new types or files needed. SwiftUI animation modifiers keyed on existing state values (`current`, `done`).

**Tech Stack:** SwiftUI, Swift

---

### Task 1: Polish goalRow — animated fill, taller bar, done-row highlight

**Files:**
- Modify: `CruxPet/ContentView.swift` (lines 51–79, `DailyGoalView.goalRow()`)

- [ ] **Step 1: Add `.animation` to the fill Capsule**

In `CruxPet/ContentView.swift`, find:

```swift
                    Capsule()
                        .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                        .frame(width: geo.size.width * ratio)
```

Replace with:

```swift
                    Capsule()
                        .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                        .frame(width: geo.size.width * ratio)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
```

- [ ] **Step 2: Increase bar height from 6px to 8px**

Find:

```swift
            .frame(height: 6)
```

Replace with:

```swift
            .frame(height: 8)
```

- [ ] **Step 3: Add done-row highlight before `.onTapGesture`**

Find:

```swift
        .onTapGesture { onTap() }
    }
}
```

Replace with:

```swift
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(done ? Color.green.opacity(0.07) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: done)
        .onTapGesture { onTap() }
    }
}
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
git commit -m "feat: polish goal progress bars — animated fill, 8px height, done highlight"
```
