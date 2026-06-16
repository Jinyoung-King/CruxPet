# Goal Row Tap → Expand Stats Design

## Goal

Tapping either daily goal progress bar (commit or pomodoro row in DailyGoalView) automatically expands the weekly stats chart.

## Architecture

Three files modified, no new files:

### `CruxPet/StatsView.swift`
Change `@State private var isExpanded = false` to `@Binding var isExpanded: Bool`. The `StatsView` no longer owns its expanded state — it is controlled externally. Update `#Preview` to pass a constant binding.

### `CruxPet/ContentView.swift` (DailyGoalView)
Add `onTap: () -> Void` parameter to `DailyGoalView`. Add `.onTapGesture { onTap() }` to each `goalRow` HStack. The callback is invoked when either row is tapped.

### `CruxPet/ContentView.swift` (ContentView)
Add `@State private var isStatsExpanded = false`. Pass `isExpanded: $isStatsExpanded` to `StatsView`. Pass `onTap: { withAnimation(.easeInOut(duration: 0.2)) { isStatsExpanded = true } }` to `DailyGoalView`.

## Behaviour

- Tapping ⚡ 커밋 row → stats chart expands (animated)
- Tapping 🍅 포모 row → stats chart expands (animated)
- Tapping the "📊 주간 스탯" header still toggles the chart open/closed as before
- No change to any other UI

## Non-Goals

- No per-series highlighting (all bars stay the same after tap)
- No scroll-to-stats (menu bar window is small enough that chart is visible)
- No separate tap target for "close" — existing header toggle handles that
