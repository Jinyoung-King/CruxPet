# SF Symbol Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all emoji used as UI icons/labels with SF Symbols across 7 files, leaving pet accessory Canvas rendering untouched.

**Architecture:** Sequential tasks — model files first (to avoid broken references during build), then UI files. Each task is self-contained and builds cleanly. No new files created.

**Tech Stack:** SwiftUI, SF Symbols (macOS 14.6 deployment target)

---

### Task 1: AchievementModel — rename `emoji` → `sfSymbol` + fix consumers

**Files:**
- Modify: `CruxPet/AchievementModel.swift` (lines 23, 129–143)
- Modify: `CruxPet/ContentView.swift` (line 138)
- Modify: `CruxPet/ShareCardView.swift` (line 228)

- [ ] **Step 1: Rename field and update all literals in `AchievementModel.swift`**

Find:
```swift
struct Achievement: Identifiable {
    let id: String
    let type: AchievementType
    let emoji: String
    let title: String
    let unlocksItemId: String? = nil
}
```
Replace with:
```swift
struct Achievement: Identifiable {
    let id: String
    let type: AchievementType
    let sfSymbol: String
    let title: String
    let unlocksItemId: String? = nil
}
```

Find:
```swift
        case .commit(let n):
            return Achievement(id: "commit_\(n)", type: type, emoji: "⚡", title: "커밋 \(n)회")
        case .pomodoro(let n):
            return Achievement(id: "pomodoro_\(n)", type: type, emoji: "🍅", title: "포모도로 \(n)회")
        case .streak(let n):
            return Achievement(id: "streak_\(n)", type: type, emoji: "🔥", title: "\(n)일 연속")
        case .level(let n):
            return Achievement(id: "level_\(n)", type: type, emoji: "⭐", title: "레벨 \(n) 달성")
        case .questClear(let n):
            return Achievement(id: "questclear_\(n)", type: type, emoji: "📋", title: "퀘스트 올클리어 \(n)회")
        case .special(let kind):
            switch kind {
            case .nightOwl:  return Achievement(id: "special_nightOwl",  type: type, emoji: "🌙", title: "밤샘 코더")
            case .sprinter:  return Achievement(id: "special_sprinter",   type: type, emoji: "⚡", title: "스프린터")
            case .focusKing: return Achievement(id: "special_focusKing",  type: type, emoji: "🎯", title: "집중왕")
            }
```
Replace with:
```swift
        case .commit(let n):
            return Achievement(id: "commit_\(n)", type: type, sfSymbol: "bolt.fill", title: "커밋 \(n)회")
        case .pomodoro(let n):
            return Achievement(id: "pomodoro_\(n)", type: type, sfSymbol: "timer", title: "포모도로 \(n)회")
        case .streak(let n):
            return Achievement(id: "streak_\(n)", type: type, sfSymbol: "flame.fill", title: "\(n)일 연속")
        case .level(let n):
            return Achievement(id: "level_\(n)", type: type, sfSymbol: "star.fill", title: "레벨 \(n) 달성")
        case .questClear(let n):
            return Achievement(id: "questclear_\(n)", type: type, sfSymbol: "checklist", title: "퀘스트 올클리어 \(n)회")
        case .special(let kind):
            switch kind {
            case .nightOwl:  return Achievement(id: "special_nightOwl",  type: type, sfSymbol: "moon.stars.fill", title: "밤샘 코더")
            case .sprinter:  return Achievement(id: "special_sprinter",   type: type, sfSymbol: "bolt.fill", title: "스프린터")
            case .focusKing: return Achievement(id: "special_focusKing",  type: type, sfSymbol: "target", title: "집중왕")
            }
```

- [ ] **Step 2: Fix `ContentView.swift` line ~138 — `achievement.emoji` → `.sfSymbol`**

Find:
```swift
            Text(achievement.emoji)
                .font(.caption)
```
Replace with:
```swift
            Image(systemName: achievement.sfSymbol)
                .font(.caption)
                .symbolRenderingMode(.multicolor)
```

- [ ] **Step 3: Fix `ShareCardView.swift` line ~228 — `earnedBadges[i].emoji` → `.sfSymbol`**

Find:
```swift
                                Text(earnedBadges[i].emoji)
                                    .font(.system(size: 11))
```
Replace with:
```swift
                                Image(systemName: earnedBadges[i].sfSymbol)
                                    .font(.system(size: 11))
                                    .symbolRenderingMode(.multicolor)
```

- [ ] **Step 4: Build**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/AchievementModel.swift CruxPet/ContentView.swift CruxPet/ShareCardView.swift
git commit -m "refactor: replace Achievement.emoji with sfSymbol"
```

---

### Task 2: CompanionModel — rename `emoji` → `sfSymbol` + fix consumers

**Files:**
- Modify: `CruxPet/CompanionModel.swift` (lines 8, 16–20)
- Modify: `CruxPet/CompanionSlimeView.swift` (line ~66)

- [ ] **Step 1: Rename field and update literals in `CompanionModel.swift`**

Find:
```swift
struct Companion: Identifiable, Equatable {
    let id: String
    let name: String
    let bodyHex: String
    let emoji: String
}

@Observable
class CompanionModel {
    private(set) var unlockedIDs: Set<String> = []

    static let all: [Companion] = [
        Companion(id: "baby",  name: "아기 슬라임",  bodyHex: "#7EC8E3", emoji: "🐣"),
        Companion(id: "flame", name: "불꽃 슬라임", bodyHex: "#FF5722", emoji: "🔥"),
        Companion(id: "star",  name: "별빛 슬라임",  bodyHex: "#FFD700", emoji: "✨"),
        Companion(id: "night", name: "야왕 슬라임",  bodyHex: "#212121", emoji: "🌙"),
        Companion(id: "pomo",  name: "포모 슬라임",  bodyHex: "#E53935", emoji: "🍅"),
    ]
```
Replace with:
```swift
struct Companion: Identifiable, Equatable {
    let id: String
    let name: String
    let bodyHex: String
    let sfSymbol: String
}

@Observable
class CompanionModel {
    private(set) var unlockedIDs: Set<String> = []

    static let all: [Companion] = [
        Companion(id: "baby",  name: "아기 슬라임",  bodyHex: "#7EC8E3", sfSymbol: "bird"),
        Companion(id: "flame", name: "불꽃 슬라임", bodyHex: "#FF5722", sfSymbol: "flame.fill"),
        Companion(id: "star",  name: "별빛 슬라임",  bodyHex: "#FFD700", sfSymbol: "sparkles"),
        Companion(id: "night", name: "야왕 슬라임",  bodyHex: "#212121", sfSymbol: "moon.stars.fill"),
        Companion(id: "pomo",  name: "포모 슬라임",  bodyHex: "#E53935", sfSymbol: "timer"),
    ]
```

- [ ] **Step 2: Fix `CompanionSlimeView.swift` — render SF Symbol in Canvas**

Find:
```swift
                // 이모지 (슬라임 위)
                let resolved = context.resolve(
                    Text(companion.emoji).font(.system(size: 8))
                )
```
Replace with:
```swift
                // 아이콘 (슬라임 위)
                let resolved = context.resolve(
                    Image(systemName: companion.sfSymbol).font(.system(size: 8))
                )
```

- [ ] **Step 3: Build**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/CompanionModel.swift CruxPet/CompanionSlimeView.swift
git commit -m "refactor: replace Companion.emoji with sfSymbol"
```

---

### Task 3: ContentView — ToastData + toastView + showToast + streakMilestoneMessage

**Files:**
- Modify: `CruxPet/ContentView.swift` (lines 4–7, 332, 374–383, 318–345, 862–864, 911)

- [ ] **Step 1: Rename `ToastData.emoji` → `icon`**

Find:
```swift
private struct ToastData: Equatable {
    let emoji: String
    let title: String
    let subtitle: String
}
```
Replace with:
```swift
private struct ToastData: Equatable {
    let icon: String
    let title: String
    let subtitle: String
}
```

- [ ] **Step 2: Update `toastView()` to render SF Symbol**

Find:
```swift
            Text(data.emoji)
                .font(.title3)
```
Replace with:
```swift
            Image(systemName: data.icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
```

- [ ] **Step 3: Update all `showToast(ToastData(emoji:` call sites**

Find:
```swift
                showToast(ToastData(emoji: "⚡️", title: "커밋 감지!", subtitle: "EXP를 획득했어요"))
```
Replace with:
```swift
                showToast(ToastData(icon: "bolt.fill", title: "커밋 감지!", subtitle: "EXP를 획득했어요"))
```

Find:
```swift
            showToast(ToastData(emoji: "🎉", title: "레벨 업! Lv.\(newLevel)",
                                subtitle: "슬라임이 성장했어요 ✨"))
```
Replace with:
```swift
            showToast(ToastData(icon: "party.popper", title: "레벨 업! Lv.\(newLevel)",
                                subtitle: "슬라임이 성장했어요"))
```

Find:
```swift
            let (emoji, subtitle) = streakMilestoneMessage(milestone)
            showToast(ToastData(emoji: emoji, title: "\(milestone)일 연속 달성!", subtitle: subtitle))
```
Replace with:
```swift
            let (icon, subtitle) = streakMilestoneMessage(milestone)
            showToast(ToastData(icon: icon, title: "\(milestone)일 연속 달성!", subtitle: subtitle))
```

Find:
```swift
                showToast(ToastData(emoji: "🍅", title: "포모도로 완료!", subtitle: "EXP를 획득했어요 ✨"))
```
Replace with:
```swift
                showToast(ToastData(icon: "timer", title: "포모도로 완료!", subtitle: "EXP를 획득했어요"))
```

Find (first occurrence — pomodoro quest):
```swift
                showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
            }
            refreshActivityDays()
        }
        .onChange(of: pet.todayCommitCount) { _, _ in
            if questsModel.claimCompleted(pet: pet) {
                showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
```
Replace with:
```swift
                showToast(ToastData(icon: "party.popper", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
            }
            refreshActivityDays()
        }
        .onChange(of: pet.todayCommitCount) { _, _ in
            if questsModel.claimCompleted(pet: pet) {
                showToast(ToastData(icon: "party.popper", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
```

Find:
```swift
            showToast(ToastData(emoji: "🏆", title: "업적 달성! \(newOnes[0].title)", subtitle: "새 업적을 달성했어요"))
        } else {
            showToast(ToastData(emoji: "🏆", title: "업적 \(newOnes.count)개 달성!", subtitle: "새 업적을 달성했어요"))
```
Replace with:
```swift
            showToast(ToastData(icon: "trophy.fill", title: "업적 달성! \(newOnes[0].title)", subtitle: "새 업적을 달성했어요"))
        } else {
            showToast(ToastData(icon: "trophy.fill", title: "업적 \(newOnes.count)개 달성!", subtitle: "새 업적을 달성했어요"))
```

Find:
```swift
            showToast(ToastData(emoji: "🐾", title: "\(companion.name) 등장!",
                                subtitle: "새 친구를 얻었어요"))
```
Replace with:
```swift
            showToast(ToastData(icon: "pawprint.fill", title: "\(companion.name) 등장!",
                                subtitle: "새 친구를 얻었어요"))
```

- [ ] **Step 4: Update `streakMilestoneMessage` return type from emoji to SF Symbol name**

Find:
```swift
    private func streakMilestoneMessage(_ days: Int) -> (String, String) {
        switch days {
        case 3:   return ("🔥", "3일 연속! 습관이 만들어지고 있어요")
        case 7:   return ("🔥", "일주일 개근! 대단한데요?")
        case 14:  return ("💪", "2주 연속! 이제 루틴이 됐네요")
        case 30:  return ("👑", "한 달 연속!! 진짜 레전드")
        case 60:  return ("💎", "두 달 연속... 미쳤다")
        default:  return ("🌟", "무려 \(days)일 연속! 전설의 개발자")
        }
    }
```
Replace with:
```swift
    private func streakMilestoneMessage(_ days: Int) -> (String, String) {
        switch days {
        case 3:   return ("flame.fill", "3일 연속! 습관이 만들어지고 있어요")
        case 7:   return ("flame.fill", "일주일 개근! 대단한데요?")
        case 14:  return ("figure.strengthtraining.traditional", "2주 연속! 이제 루틴이 됐네요")
        case 30:  return ("crown.fill", "한 달 연속!! 진짜 레전드")
        case 60:  return ("diamond.fill", "두 달 연속... 미쳤다")
        default:  return ("star.fill", "무려 \(days)일 연속! 전설의 개발자")
        }
    }
```

- [ ] **Step 5: Build**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "refactor: replace ToastData emoji with SF Symbol icons"
```

---

### Task 4: ContentView — inline emoji replacements (UI elements)

**Files:**
- Modify: `CruxPet/ContentView.swift` (lines 24, 46–47, 51–79, 112, 145, 417, 424, 480, 496, 610, 645, 757)

- [ ] **Step 1: Pomodoro help popover header**

Find:
```swift
                Text("🍅 포모도로 기법")
                    .font(.caption.bold())
```
Replace with:
```swift
                Label("포모도로 기법", systemImage: "timer")
                    .font(.caption.bold())
```

- [ ] **Step 2: Goal row ✓ checkmark**

Find:
```swift
                    Text("✓").font(.system(size: 9)).foregroundStyle(.green)
```
Replace with:
```swift
                    Image(systemName: "checkmark").font(.system(size: 9)).foregroundStyle(.green)
```

- [ ] **Step 3: `goalRow` — rename parameter, update body and call sites**

Find (function signature and label rendering):
```swift
    private func goalRow(_ emoji: String, _ label: String, current: Int, goal: Int) -> some View {
        let done = current >= goal
        let ratio: CGFloat = goal > 0 ? min(CGFloat(current) / CGFloat(goal), 1.0) : 0
        return HStack(spacing: 6) {
            Text("\(emoji) \(label)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
```
Replace with:
```swift
    private func goalRow(_ icon: String, _ label: String, current: Int, goal: Int) -> some View {
        let done = current >= goal
        let ratio: CGFloat = goal > 0 ? min(CGFloat(current) / CGFloat(goal), 1.0) : 0
        return HStack(spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 9))
                Text(label)
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .frame(width: 40, alignment: .leading)
```

Find call sites:
```swift
            goalRow("⚡", "커밋",  current: todayCommits,   goal: commitGoal)
            goalRow("🍅", "포모", current: todayPomodoros, goal: pomodoroGoal)
```
Replace with:
```swift
            goalRow("bolt.fill", "커밋",  current: todayCommits,   goal: commitGoal)
            goalRow("timer", "포모", current: todayPomodoros, goal: pomodoroGoal)
```

- [ ] **Step 4: Achievement count label (two places)**

Find first occurrence (in `AchievementsView` header):
```swift
                Text("✨ \(achievementModel.claimedCount)개 달성")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
```
Replace with:
```swift
                Label("\(achievementModel.claimedCount)개 달성", systemImage: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
```

Find second occurrence (in goal section button row):
```swift
                Text("✨ \(achievementModel.claimedCount)개 달성")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
```
Replace with:
```swift
                Label("\(achievementModel.claimedCount)개 달성", systemImage: "sparkles")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
```

- [ ] **Step 5: Achievement row "🎉 달성!" badge**

Find:
```swift
                    Text("🎉 달성!")
                        .font(.system(size: 9))
                        .foregroundStyle(.green.opacity(0.7))
```
Replace with:
```swift
                    Label("달성!", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green.opacity(0.7))
```

- [ ] **Step 6: CRITICAL overlay**

Find:
```swift
                    Text("💥 CRITICAL!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
```
Replace with:
```swift
                    Label("CRITICAL!", systemImage: "bolt.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
```

- [ ] **Step 7: LEVEL UP overlay**

Find:
```swift
                    Text("🎉 LEVEL UP!")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
```
Replace with:
```swift
                    Label("LEVEL UP!", systemImage: "party.popper")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
```

- [ ] **Step 8: Treat button**

Find:
```swift
                Text(interaction.isEating ? "😋" : "🍬")
                    .font(.system(size: 13))
```
Replace with:
```swift
                Image(systemName: interaction.isEating ? "face.smiling.fill" : "gift.fill")
                    .font(.system(size: 13))
```

- [ ] **Step 9: Streak badge flame**

Find:
```swift
            Text("🔥")
                .font(.system(size: 11))
```
Replace with:
```swift
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
```

- [ ] **Step 10: Quest count checkmark**

Find:
```swift
                    Text("✅ \(questsModel.claimedCount)/\(questsModel.todayQuests.count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
```
Replace with:
```swift
                    Label("\(questsModel.claimedCount)/\(questsModel.todayQuests.count)", systemImage: "checkmark.circle.fill")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.green)
```

- [ ] **Step 11: Pomodoro session count**

Find:
```swift
                Text("🍅 × \(pomodoro.sessionCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
```
Replace with:
```swift
                Label("× \(pomodoro.sessionCount)", systemImage: "timer")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
```

- [ ] **Step 12: Build**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 13: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "refactor: replace inline emoji with SF Symbols in ContentView"
```

---

### Task 5: StatsView + CustomizeView

**Files:**
- Modify: `CruxPet/StatsView.swift` (lines 81–83, 102–104)
- Modify: `CruxPet/CustomizeView.swift` (lines 185, 192)

- [ ] **Step 1: Update `summaryCell` in `StatsView.swift`**

Find:
```swift
    private func summaryCell(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(emoji).font(.system(size: 12))
```
Replace with:
```swift
    private func summaryCell(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 12))
```

Find call sites:
```swift
                    summaryCell("🔥", "\(pet.streakDays)", "연속")
                    summaryCell("⚡", "\(weekCommits)",   "커밋/주")
                    summaryCell("🍅", "\(weekPomodoros)", "뽀모/주")
```
Replace with:
```swift
                    summaryCell("flame.fill", "\(pet.streakDays)", "연속")
                    summaryCell("bolt.fill", "\(weekCommits)",   "커밋/주")
                    summaryCell("timer", "\(weekPomodoros)", "뽀모/주")
```

- [ ] **Step 2: Update labels in `CustomizeView.swift`**

Find:
```swift
                        Text("⚡ 커밋").font(.caption2).foregroundStyle(.secondary)
```
Replace with:
```swift
                        Label("커밋", systemImage: "bolt.fill").font(.caption2).foregroundStyle(.secondary)
```

Find:
```swift
                        Text("🍅 포모도로").font(.caption2).foregroundStyle(.secondary)
```
Replace with:
```swift
                        Label("포모도로", systemImage: "timer").font(.caption2).foregroundStyle(.secondary)
```

- [ ] **Step 3: Build**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/StatsView.swift CruxPet/CustomizeView.swift
git commit -m "refactor: replace emoji with SF Symbols in StatsView and CustomizeView"
```

---

### Task 6: Particle views — replace emoji with SF Symbols

**Files:**
- Modify: `CruxPet/ContentView.swift` (lines ~985–1015, `ParticleOverlayView` and `LevelUpParticleView`)

- [ ] **Step 1: `ParticleOverlayView` — `Text("❤️")` → `Image(systemName: "heart.fill")`**

Find:
```swift
                Text("❤️")
                    .font(.system(size: 12))
                    .offset(x: CGFloat(i - 1) * 10, y: floated ? -40 : 0)
                    .opacity(floated ? 0 : 1)
                    .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: floated)
```
Replace with:
```swift
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .offset(x: CGFloat(i - 1) * 10, y: floated ? -40 : 0)
                    .opacity(floated ? 0 : 1)
                    .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: floated)
```

- [ ] **Step 2: `LevelUpParticleView` — `Text("✨")` → `Image(systemName: "sparkle")`**

Find:
```swift
                Text("✨")
                    .font(.system(size: 14))
                    .offset(x: floated ? xOffsets[i] : 0,
```
Replace with:
```swift
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                    .offset(x: floated ? xOffsets[i] : 0,
```

- [ ] **Step 3: Build**

```bash
cd /Users/jiny/dev/CruxPet
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add CruxPet/ContentView.swift
git commit -m "refactor: replace emoji particles with SF Symbol images"
```
