# Goal Progress Bar Polish Design

## Goal

Enhance the existing progress bars in `DailyGoalView` with animated fill, slightly taller bars, and a subtle row highlight when a goal is completed.

## Current State

`DailyGoalView` (ContentView.swift lines 37–79) already has:
- 6px capsule progress bars
- Blue fill → green when done
- `current/goal` text, ✓ when done

## Changes

All edits are inside `DailyGoalView.goalRow()` in `CruxPet/ContentView.swift`.

### 1. Animated bar fill

Add `.animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)` to the fill Capsule so it smoothly grows when a commit or pomodoro is recorded.

**Before:**
```swift
                Capsule()
                    .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                    .frame(width: geo.size.width * ratio)
```

**After:**
```swift
                Capsule()
                    .fill(done ? Color.green.opacity(0.6) : Color.blue.opacity(0.5))
                    .frame(width: geo.size.width * ratio)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
```

### 2. Bar height 6px → 8px

**Before:**
```swift
        .frame(height: 6)
```

**After:**
```swift
        .frame(height: 8)
```

### 3. Row background highlight when done

Wrap the HStack in a `Group` / add `.background()` so the row gets a subtle green tint when the goal is reached.

**Before:**
```swift
        .onTapGesture { onTap() }
    }
```

**After:**
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
```

## What Does NOT Change

- The emoji, label, current/goal text, ✓ checkmark — unchanged
- The `onTap` navigation to stats tab — unchanged
- The overall `DailyGoalView` structure (VStack with two goalRows) — unchanged
- Any other section or file
