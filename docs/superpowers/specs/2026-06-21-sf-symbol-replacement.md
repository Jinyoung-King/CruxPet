# SF Symbol Replacement Design

## Goal

Replace all emoji used as UI icons/labels with SF Symbols throughout the app. Pet accessory rendering (Canvas-drawn emoji in SlimeView/CatView/DogView/GhostView and `type.emoji` in CustomizeView) is explicitly out of scope.

## Deployment Target

macOS 14.6 — all SF Symbols used below are available.

## Symbol Mapping

| Emoji | SF Symbol name | Notes |
|---|---|---|
| ⚡ | `bolt.fill` | commits |
| 🍅 | `timer` | pomodoro |
| 🔥 | `flame.fill` | streak |
| 🏆 | `trophy.fill` | achievement toast |
| ⭐ | `star.fill` | level achievement |
| 🌙 | `moon.stars.fill` | nightOwl |
| 🎯 | `target` | focusKing |
| 📋 | `checklist` | quest clears |
| 🐾 | `pawprint.fill` | companion toast |
| 🎉 | `party.popper` | level-up / quest clear |
| 💥 | `bolt.circle.fill` | critical attack |
| ✓ | `checkmark` | goal done |
| ✅ | `checkmark.circle.fill` | quest count |
| ✨ | `sparkles` | achievement count label |
| 💪 | `figure.strengthtraining.traditional` | 14-day streak |
| 👑 | `crown.fill` | 30-day streak |
| 💎 | `diamond.fill` | 60-day streak |
| 🌟 | `star.fill` | default streak milestone |
| 🐣 | `bird` | baby companion |
| 🍬 | `gift.fill` | treat button (not eating) |
| 😋 | `face.smiling.fill` | treat button (eating) |
| ❤️ particle | `heart.fill` | tap particle |
| ✨ particle | `sparkle` | level-up particle |

## Files Changed

| File | What changes |
|---|---|
| `ContentView.swift` | ToastData.emoji→icon, toastView, showToast calls, streakMilestoneMessage, goalRow, overlays, streak section, treat button, quest count, pomodoro session count, achievement count label, "🎉 달성!" badge, particle views |
| `AchievementModel.swift` | `Achievement.emoji: String` → `sfSymbol: String`, all literal values |
| `CompanionModel.swift` | `Companion.emoji: String` → `sfSymbol: String`, all literal values |
| `StatsView.swift` | `summaryCell` takes SF Symbol name instead of emoji |
| `CustomizeView.swift` | `Text("⚡ 커밋")` and `Text("🍅 포모도로")` labels |
| `ShareCardView.swift` | `earnedBadges[i].emoji` → `.sfSymbol`, render as `Image(systemName:)` |
| `CompanionSlimeView.swift` | `companion.emoji` → `.sfSymbol`, render as `Image(systemName:)` |

## Detailed Changes

### ContentView.swift — ToastData

**Before:**
```swift
private struct ToastData: Equatable {
    let emoji: String
    let title: String
    let subtitle: String
}
```

**After:**
```swift
private struct ToastData: Equatable {
    let icon: String
    let title: String
    let subtitle: String
}
```

`toastView()` before:
```swift
Text(data.emoji)
    .font(.title3)
```

After:
```swift
Image(systemName: data.icon)
    .font(.title3)
    .symbolRenderingMode(.multicolor)
```

All `showToast(ToastData(emoji:` → `showToast(ToastData(icon:` with SF Symbol names:
- `"⚡️"` → `"bolt.fill"`
- `"🎉"` → `"party.popper"` (level-up, quest clear)
- `"🍅"` → `"timer"` (pomodoro complete)
- `"🏆"` → `"trophy.fill"`
- `"🐾"` → `"pawprint.fill"`
- In `streakMilestoneMessage`: inline subtitle string `"EXP를 획득했어요 ✨"` → `"EXP를 획득했어요"`

### ContentView.swift — streakMilestoneMessage

**Before:**
```swift
case 3:   return ("🔥", "3일 연속! 습관이 만들어지고 있어요")
case 7:   return ("🔥", "일주일 개근! 대단한데요?")
case 14:  return ("💪", "2주 연속! 이제 루틴이 됐네요")
case 30:  return ("👑", "한 달 연속!! 진짜 레전드")
case 60:  return ("💎", "두 달 연속... 미쳤다")
default:  return ("🌟", "무려 \(days)일 연속! 전설의 개발자")
```

**After:**
```swift
case 3:   return ("flame.fill", "3일 연속! 습관이 만들어지고 있어요")
case 7:   return ("flame.fill", "일주일 개근! 대단한데요?")
case 14:  return ("figure.strengthtraining.traditional", "2주 연속! 이제 루틴이 됐네요")
case 30:  return ("crown.fill", "한 달 연속!! 진짜 레전드")
case 60:  return ("diamond.fill", "두 달 연속... 미쳤다")
default:  return ("star.fill", "무려 \(days)일 연속! 전설의 개발자")
```

### ContentView.swift — goalRow

Signature: `goalRow(_ emoji: String, ...)` → `goalRow(_ icon: String, ...)`

**Before:**
```swift
Text("\(emoji) \(label)")
    .font(.system(size: 10))
    .foregroundStyle(.secondary)
    .frame(width: 40, alignment: .leading)
```

**After:**
```swift
HStack(spacing: 3) {
    Image(systemName: icon).font(.system(size: 9))
    Text(label)
}
.font(.system(size: 10))
.foregroundStyle(.secondary)
.frame(width: 40, alignment: .leading)
```

Call sites:
- `goalRow("⚡", "커밋", ...)` → `goalRow("bolt.fill", "커밋", ...)`
- `goalRow("🍅", "포모", ...)` → `goalRow("timer", "포모", ...)`

### ContentView.swift — characterSection overlays

**CRITICAL overlay before:**
```swift
Text("💥 CRITICAL!")
    .font(.system(size: 11, weight: .bold))
    .foregroundStyle(.orange)
```
**After:**
```swift
Label("CRITICAL!", systemImage: "bolt.circle.fill")
    .font(.system(size: 11, weight: .bold))
    .foregroundStyle(.orange)
```

**LEVEL UP overlay before:**
```swift
Text("🎉 LEVEL UP!")
    .font(.system(size: 13, weight: .black, design: .rounded))
    .foregroundStyle(.white)
```
**After:**
```swift
Label("LEVEL UP!", systemImage: "party.popper")
    .font(.system(size: 13, weight: .black, design: .rounded))
    .foregroundStyle(.white)
```

### ContentView.swift — streak section

**Before:**
```swift
Text("🔥")
```
**After:**
```swift
Image(systemName: "flame.fill")
    .foregroundStyle(.orange)
```

### ContentView.swift — treat button

**Before:**
```swift
Text(interaction.isEating ? "😋" : "🍬")
```
**After:**
```swift
Image(systemName: interaction.isEating ? "face.smiling.fill" : "gift.fill")
```

### ContentView.swift — quest count

**Before:**
```swift
Text("✅ \(questsModel.claimedCount)/\(questsModel.todayQuests.count)")
```
**After:**
```swift
Label("\(questsModel.claimedCount)/\(questsModel.todayQuests.count)", systemImage: "checkmark.circle.fill")
    .foregroundStyle(.green)
```

### ContentView.swift — pomodoro session count

**Before:**
```swift
Text("🍅 × \(pomodoro.sessionCount)")
```
**After:**
```swift
Label("× \(pomodoro.sessionCount)", systemImage: "timer")
```

### ContentView.swift — achievement count label (two places)

**Before:**
```swift
Text("✨ \(achievementModel.claimedCount)개 달성")
```
**After:**
```swift
Label("\(achievementModel.claimedCount)개 달성", systemImage: "sparkles")
```

### ContentView.swift — achievement row "달성!" badge

**Before:**
```swift
Text("🎉 달성!")
    .font(.system(size: 9))
    .foregroundStyle(.green.opacity(0.7))
```
**After:**
```swift
Label("달성!", systemImage: "checkmark.seal.fill")
    .font(.system(size: 9))
    .foregroundStyle(.green.opacity(0.7))
```

### ContentView.swift — goal row ✓ checkmark

**Before:**
```swift
Text("✓").font(.system(size: 9)).foregroundStyle(.green)
```
**After:**
```swift
Image(systemName: "checkmark").font(.system(size: 9)).foregroundStyle(.green)
```

### ContentView.swift — pomodoro help text header

**Before:**
```swift
Text("🍅 포모도로 기법")
```
**After:**
```swift
Label("포모도로 기법", systemImage: "timer")
```

### ContentView.swift — ParticleOverlayView

**Before:**
```swift
Text("❤️")
    .font(.system(size: 12))
```
**After:**
```swift
Image(systemName: "heart.fill")
    .font(.system(size: 12))
    .foregroundStyle(.red)
```

### ContentView.swift — LevelUpParticleView

**Before:**
```swift
Text("✨")
    .font(.system(size: 14))
```
**After:**
```swift
Image(systemName: "sparkle")
    .font(.system(size: 14))
    .foregroundStyle(.yellow)
```

### AchievementModel.swift

`Achievement.emoji: String` → `sfSymbol: String`

Literal mappings:
- `"⚡"` → `"bolt.fill"` (commit, sprinter)
- `"🍅"` → `"timer"` (pomodoro)
- `"🔥"` → `"flame.fill"` (streak)
- `"⭐"` → `"star.fill"` (level)
- `"📋"` → `"checklist"` (questclear)
- `"🌙"` → `"moon.stars.fill"` (nightOwl)
- `"🎯"` → `"target"` (focusKing)

### CompanionModel.swift

`Companion.emoji: String` → `sfSymbol: String`

Literal mappings:
- `"🐣"` → `"bird"` (baby)
- `"🔥"` → `"flame.fill"` (flame)
- `"✨"` → `"sparkles"` (star)
- `"🌙"` → `"moon.stars.fill"` (night)
- `"🍅"` → `"timer"` (pomo)

### CompanionSlimeView.swift

```swift
Text(companion.emoji).font(.system(size: 8))
```
→
```swift
Image(systemName: companion.sfSymbol).font(.system(size: 8))
```

### ShareCardView.swift

```swift
Text(earnedBadges[i].emoji)
```
→
```swift
Image(systemName: earnedBadges[i].sfSymbol)
```

### StatsView.swift — summaryCell

Signature: `summaryCell(_ emoji: String, ...)` → `summaryCell(_ icon: String, ...)`

```swift
Text(emoji).font(.system(size: 12))
```
→
```swift
Image(systemName: icon).font(.system(size: 12))
```

Call sites:
- `"🔥"` → `"flame.fill"`
- `"⚡"` → `"bolt.fill"`
- `"🍅"` → `"timer"`

### CustomizeView.swift

```swift
Text("⚡ 커밋").font(.caption2).foregroundStyle(.secondary)
```
→
```swift
Label("커밋", systemImage: "bolt.fill").font(.caption2).foregroundStyle(.secondary)
```

```swift
Text("🍅 포모도로").font(.caption2).foregroundStyle(.secondary)
```
→
```swift
Label("포모도로", systemImage: "timer").font(.caption2).foregroundStyle(.secondary)
```

## What Does NOT Change

- `CustomizeView.swift` line ~55: `Text(isUnlocked ? type.emoji : "🔒")` — pet type selector, Category 5
- All pet view Canvas rendering (SlimeView, CatView, DogView, GhostView)
- `PetModel.swift` accessory/constellation emoji
- Any Korean text strings (they are content, not icons)
