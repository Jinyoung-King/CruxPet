# Pomodoro Tab Polish Design

## Goal

Upgrade `pomodoroSection` from a card-style widget to a proper full-tab layout. The section was designed for a scrollable sidebar; now it occupies an entire 280×340px tab and looks cramped.

## Architecture

Single file modified: `CruxPet/ContentView.swift` — `pomodoroSection` computed var only.

## Changes

### 1. Remove card background/border

The RoundedRectangle background and strokeBorder are appropriate for a card in a list, not for a full tab. Remove the entire `.background(...)` block.

**Before:**
```swift
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
```

**After:**
```swift
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

### 2. Vertical centering

Wrap the root `VStack` in a container that uses `.frame(maxHeight: .infinity)` so the content centers in the tab.

**Before:**
```swift
return VStack(spacing: 7) {
    // ... content
}
.padding(.vertical, 10)
.padding(.horizontal, 12)
.frame(maxWidth: .infinity)
.background(...)
```

**After:**
```swift
return VStack(spacing: 16) {
    // ... content (same)
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

The tab's own `.padding(12)` (already set at the call site in `ContentView`) provides the horizontal inset. No extra padding needed inside.

### 3. Timer font: 30pt → 48pt

```swift
// Before
.font(.system(size: 30, weight: .bold, design: .monospaced))

// After
.font(.system(size: 48, weight: .bold, design: .monospaced))
```

### 4. Button control size: .small → .regular

All six `Button` instances use `.controlSize(.small)` — change to `.controlSize(.regular)`.

### 5. Session count font: 10pt → 13pt

```swift
// Before
.font(.system(size: 10))

// After
.font(.system(size: 13))
```

### 6. Inner VStack spacing: 7 → 16

Increase the VStack spacing from 7 to 16 to spread content out in the larger space.

## What Does NOT Change

- All state logic (isRunning, isBreak, isCompleted, accent color, headerIcon)
- All button actions and conditions
- `PomodoroInfoButton` placement
- `.animation(.easeInOut(duration: 0.25), value: pomodoro.state)` — unchanged
- The call site in ContentView's TabView — no changes outside `pomodoroSection`
- Any other file

## Non-Goals

- No circular progress ring
- No new files
- No changes to PomodoroTimer logic
