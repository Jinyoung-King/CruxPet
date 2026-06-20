# UI Tab Redesign Design

## Goal

Replace the single long-scroll main view with a 3-tab layout — making the interface simpler, more focused, and less overwhelming.

## Window Size

| | Before | After |
|--|--------|-------|
| Width | 220px | 280px |
| Height | auto-scroll (very tall) | 400px fixed |

## Layout Structure

```
┌─────────────────────────────┐  ← 280px wide
│  [🐾 홈]  [🍅 포모도로]  [📊 스탯]  │  ← TabView (native macOS tabs)
├─────────────────────────────┤
│                             │
│     Tab content             │  ← ~340px
│                             │
├─────────────────────────────┤
│  [↑ 공유]  [⚙ 설정]  [⏻ 종료]  │  ← persistent footer (share/settings/quit)
│           v1.x.x            │
└─────────────────────────────┘
```

## Tab Contents

### 🐾 홈 탭
- `characterSection` — enlarged pixel background + pet (taller than current)
- `goalSection` — today's commit / pomodoro goal progress

No scrolling. Content fits fixed height.

### 🍅 포모도로 탭
- `pomodoroSection` — full tab dedicated to timer and session count

No scrolling. Timer UI centered in the tab.

### 📊 스탯 탭
- `expSection` — level + XP bar
- `statsSection` — last 7 days commit/pomodoro bar chart
- `questSection` — quest list (collapsible)
- `achievementSection` — achievement summary
- `activitySection` — commit activity calendar

Scrollable (content exceeds tab height).

## Architecture

Single file modified: `CruxPet/ContentView.swift`

The existing section computed vars (`characterSection`, `goalSection`, `expSection`, `questSection`, `achievementSection`, `pomodoroSection`, `activitySection`) are kept unchanged. Only their placement changes.

### Before (main `body` else-branch)
```swift
VStack(spacing: 10) {
    characterSection
    goalSection
    expSection
    statsSection
    questSection
    achievementSection
    pomodoroSection
    activitySection
    Divider()
    // bottom toolbar
}
.frame(width: 220)
```

### After
```swift
VStack(spacing: 0) {
    TabView {
        // 홈
        ScrollView {
            VStack(spacing: 10) {
                characterSection
                goalSection
            }
            .padding(12)
        }
        .tabItem { Label("홈", systemImage: "pawprint.fill") }

        // 포모도로
        pomodoroSection
            .padding(12)
            .tabItem { Label("포모도로", systemImage: "timer") }

        // 스탯
        ScrollView {
            VStack(spacing: 10) {
                expSection
                statsSection
                questSection
                achievementSection
                activitySection
            }
            .padding(12)
        }
        .tabItem { Label("스탯", systemImage: "chart.bar.fill") }
    }

    Divider()
    // footer: share / settings / quit / version
}
.frame(width: 280, height: 400)
```

## characterSection Height

The home tab gives the character more vertical space. The `characterSection` ZStack no longer competes with 7 other sections for space, so the pet area can grow naturally. No explicit height constraint change needed — the ZStack fills available space in the tab.

## What Does NOT Change

- All section computed vars (`characterSection`, `pomodoroSection`, etc.) — logic unchanged
- `showCustomize`, `showAchievements`, `showSharePreview` modal screens — kept as-is, shown over the entire view
- Toast overlay — unchanged
- `CustomizeView` frame (220×650) — unchanged
- Background, animation modifiers — unchanged

## Non-Goals

- No redesign of individual section content
- No new sections or features
- No change to modal screens (customize, share, achievements)
