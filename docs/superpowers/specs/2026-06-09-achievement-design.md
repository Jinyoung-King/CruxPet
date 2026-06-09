# Achievement System — Design Spec

## Goal

달성할수록 새 마일스톤이 생성되는 무한 업적 시스템. 업적 달성 시 상점 아이템 잠금 해제 조건으로 사용 (상점은 별도 구현).

## Architecture

- **`AchievementModel.swift`** (신규): 마일스톤 생성 로직, 달성 여부 판정, 보상 기록
- **`PetModel.swift`** (수정): 누적 카운터 3개 추가, 특수 업적용 플래그 1개 추가
- **`QuestModel.swift`** (수정): 올클리어 달성 시 `PetModel.questClearCount` 증가
- **`ContentView.swift`** (수정): 퀘스트 섹션 아래 업적 섹션 추가

## Achievement Types

```swift
enum AchievementType {
    case commit(Int)        // 누적 커밋 n회
    case pomodoro(Int)      // 누적 포모도로 n회
    case streak(Int)        // 연속 n일 달성
    case level(Int)         // 레벨 n 도달
    case questClear(Int)    // 퀘스트 올클리어 n회
    case special(SpecialKind)
}

enum SpecialKind: String {
    case nightOwl   // 자정(00:00~03:59) 커밋
    case sprinter   // 하루 커밋 5회
    case focusKing  // 하루 포모도로 3회
}
```

```swift
struct Achievement: Identifiable {
    let id: String              // "commit_100", "streak_30", "special_nightOwl"
    let type: AchievementType
    let emoji: String
    let title: String           // 한국어
    let unlocksItemId: String?  // 상점 아이템 ID 플레이스홀더 (nil이면 보상 없음)
}
```

## Milestone Sequences

달성한 마일스톤 전부 + 다음 미달성 1개를 표시. ID는 `"\(category)_\(threshold)"`.

| 카테고리 | 시퀀스 |
|---|---|
| 커밋 | 1, 10, 50, 100, 250, 500, 1000, 2500, 5000, 10000 → 이후 ×2.5 반올림 |
| 포모도로 | 1, 10, 25, 50, 100, 250, 500, 1000 → 이후 ×2.5 반올림 |
| 스트릭 | 3, 7, 14, 30, 60, 100, 200, 365, 730 → 이후 +365 |
| 레벨 | 10, 20, 30, 50, 75, 100 → 이후 +50 |
| 퀘스트 올클리어 | 1, 7, 30, 100, 365 → 이후 +365 |
| 특수 | nightOwl / sprinter / focusKing (1회성) |

## PetModel 추가 필드

```swift
private(set) var totalCommitCount: Int = 0      // 누적 커밋 (리셋 없음)
private(set) var totalPomodoroCount: Int = 0    // 누적 포모도로 (리셋 없음)
private(set) var questClearCount: Int = 0       // 퀘스트 올클리어 횟수
private(set) var hasNightOwlCommit: Bool = false // 자정 커밋 여부 (영구 플래그)
```

- `gainCommitExp()`: `totalCommitCount += 1`, 시간이 0~3시면 `hasNightOwlCommit = true`
- `gainPomodoroExp()`: `totalPomodoroCount += 1`
- `incrementQuestClear()`: `questClearCount += 1` (QuestModel에서 올클리어 시 호출)
- UserDefaults 키: `cruxpet.totalCommitCount`, `cruxpet.totalPomodoroCount`, `cruxpet.questClearCount`, `cruxpet.hasNightOwlCommit`

## AchievementModel Public Interface

```swift
@Observable class AchievementModel {
    private(set) var claimedIds: Set<String> = []

    var claimedCount: Int { claimedIds.count }

    // 표시할 업적: 달성한 것 전부 + 카테고리별 다음 미달성 1개
    func visibleAchievements(for pet: PetModel) -> [Achievement]

    // 완료된 미지급 업적 일괄 클레임 (새 달성 시 토스트용으로 [Achievement] 반환)
    @discardableResult
    func claimCompleted(pet: PetModel) -> [Achievement]

    func isClaimed(_ achievement: Achievement) -> Bool
    func progress(for achievement: Achievement, pet: PetModel) -> (current: Int, total: Int)

    // 마일스톤 생성 (static, 테스트 가능)
    static func commitMilestones(upTo count: Int) -> [Int]
    static func pomodoroMilestones(upTo count: Int) -> [Int]
    static func streakMilestones(upTo days: Int) -> [Int]
    static func levelMilestones(upTo level: Int) -> [Int]
    static func questClearMilestones(upTo count: Int) -> [Int]
}
```

UserDefaults 키: `cruxpet.achievements.claimedIds`

## 달성 판정

```
commit(n)       → pet.totalCommitCount >= n
pomodoro(n)     → pet.totalPomodoroCount >= n
streak(n)       → pet.streakDays >= n
level(n)        → pet.level >= n
questClear(n)   → pet.questClearCount >= n
nightOwl        → pet.hasNightOwlCommit
sprinter        → pet.todayCommitCount >= 5
focusKing       → pet.todayPomodoroCount >= 3
```

## UI — ContentView 업적 섹션

**위치:** questSection 아래

**접힌 상태:**
```
🏆 업적    ✨ 12개 달성    ›
```

**펼친 상태:**
```
🏆 업적    ✨ 12개 달성    ∨
┌──────────────────────────────┐
│ ✅ 커밋 100회    🎉 달성!      │
│ ✅ 스트릭 30일   🎉 달성!      │
│ 🔒 커밋 250회   ████░░ 187/250│
│ 🔒 스트릭 60일  ████░░ 44/60  │
│ 🌙 밤샘 코더    달성!          │
│ ...                          │
└──────────────────────────────┘
```

- 달성한 업적: 초록 체크마크 + 흐린 텍스트 (퀘스트 섹션과 동일 스타일)
- 미달성: 자물쇠 이모지 + 캡슐 프로그레스 바 + `현재/목표`
- 특수 업적: 달성 조건 설명 텍스트 표시 (예: "자정 이후 커밋")

**신규 달성 시:** 토스트 알림 — `🏆 업적 달성! {title}`

업적 클레임은 `gainCommitExp()`, `gainPomodoroExp()`, `gainQuestExp()` 호출 이후 `claimCompleted()` 트리거.

## 이벤트 트리거

`ContentView.onChange(of: pet.totalCommitCount)`, `onChange(of: pet.totalPomodoroCount)`, `onChange(of: pet.questClearCount)` — 각각 `achievementModel.claimCompleted(pet:)` 호출 후 반환된 새 업적마다 토스트.
