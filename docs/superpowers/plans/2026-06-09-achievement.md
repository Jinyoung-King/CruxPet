# Achievement System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 달성할수록 새 마일스톤이 생성되는 무한 업적 시스템을 구현한다.

**Architecture:** `AchievementModel`에 카테고리별 마일스톤 생성 함수(static, 테스트 가능)를 두고, `PetModel`에 누적 카운터 4개를 추가한다. `claimCompleted(pet:)`이 달성된 미지급 업적을 일괄 처리하고 `[Achievement]`를 반환하면 ContentView가 토스트를 띄운다.

**Tech Stack:** Swift, SwiftUI `@Observable`, UserDefaults, XCTest

**파일 구조:**
- 신규: `CruxPet/AchievementModel.swift` — 타입 정의, 마일스톤 생성, 클레임 로직
- 신규: `CruxPetTests/AchievementModelTests.swift` — 마일스톤·isCompleted·progress 테스트
- 수정: `CruxPet/PetModel.swift` — totalCommitCount, totalPomodoroCount, questClearCount, hasNightOwlCommit 추가
- 수정: `CruxPetTests/PetModelTests.swift` — isNightOwlHour static 함수 테스트 추가
- 수정: `CruxPet/QuestModel.swift` — 올클리어 시 pet.incrementQuestClear() 호출
- 수정: `CruxPet/ContentView.swift` — achievementSection UI, onChange 훅 추가

> **참고:** 프로젝트가 `PBXFileSystemSynchronizedRootGroup`을 사용하므로 디렉토리에 파일을 생성하면 자동으로 컴파일 대상에 포함된다. pbxproj 수동 편집 불필요.

---

### Task 1: AchievementModel — 데이터 타입 및 마일스톤 생성기

**Files:**
- Create: `CruxPetTests/AchievementModelTests.swift`
- Create: `CruxPet/AchievementModel.swift`

- [ ] **Step 1: 테스트 파일 작성 (실패 예정)**

```swift
// CruxPetTests/AchievementModelTests.swift
import XCTest
@testable import CruxPet

final class AchievementModelTests: XCTestCase {

    // MARK: - commitMilestones

    func testCommitMilestones_atZero() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 0), [1])
    }

    func testCommitMilestones_at1() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 1), [1, 10])
    }

    func testCommitMilestones_at10() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 10), [1, 10, 50])
    }

    func testCommitMilestones_at99() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 99), [1, 10, 50, 100])
    }

    func testCommitMilestones_at100() {
        XCTAssertEqual(AchievementModel.commitMilestones(upTo: 100), [1, 10, 50, 100, 250])
    }

    func testCommitMilestones_nextIsFirstBeyondCount() {
        let m = AchievementModel.commitMilestones(upTo: 50)
        XCTAssertEqual(m.last, 100)
    }

    // MARK: - pomodoroMilestones

    func testPomodoroMilestones_atZero() {
        XCTAssertEqual(AchievementModel.pomodoroMilestones(upTo: 0), [1])
    }

    func testPomodoroMilestones_at25() {
        XCTAssertEqual(AchievementModel.pomodoroMilestones(upTo: 25), [1, 10, 25, 50])
    }

    // MARK: - streakMilestones

    func testStreakMilestones_atZero() {
        XCTAssertEqual(AchievementModel.streakMilestones(upTo: 0), [3])
    }

    func testStreakMilestones_at3() {
        XCTAssertEqual(AchievementModel.streakMilestones(upTo: 3), [3, 7])
    }

    func testStreakMilestones_at730() {
        let m = AchievementModel.streakMilestones(upTo: 730)
        XCTAssertTrue(m.contains(730))
        XCTAssertEqual(m.last, 1095) // 730 + 365
    }

    // MARK: - levelMilestones

    func testLevelMilestones_atZero() {
        XCTAssertEqual(AchievementModel.levelMilestones(upTo: 0), [10])
    }

    func testLevelMilestones_at100() {
        let m = AchievementModel.levelMilestones(upTo: 100)
        XCTAssertTrue(m.contains(100))
        XCTAssertEqual(m.last, 150)
    }

    // MARK: - questClearMilestones

    func testQuestClearMilestones_atZero() {
        XCTAssertEqual(AchievementModel.questClearMilestones(upTo: 0), [1])
    }

    func testQuestClearMilestones_at365() {
        let m = AchievementModel.questClearMilestones(upTo: 365)
        XCTAssertTrue(m.contains(365))
        XCTAssertEqual(m.last, 730)
    }

    // MARK: - make() factory

    func testMake_commit10_id() {
        XCTAssertEqual(AchievementModel.make(.commit(10)).id, "commit_10")
    }

    func testMake_pomodoro50_id() {
        XCTAssertEqual(AchievementModel.make(.pomodoro(50)).id, "pomodoro_50")
    }

    func testMake_streak30_id() {
        XCTAssertEqual(AchievementModel.make(.streak(30)).id, "streak_30")
    }

    func testMake_level20_id() {
        XCTAssertEqual(AchievementModel.make(.level(20)).id, "level_20")
    }

    func testMake_questClear7_id() {
        XCTAssertEqual(AchievementModel.make(.questClear(7)).id, "questclear_7")
    }

    func testMake_nightOwl_id() {
        XCTAssertEqual(AchievementModel.make(.special(.nightOwl)).id, "special_nightOwl")
    }

    func testMake_sprinter_id() {
        XCTAssertEqual(AchievementModel.make(.special(.sprinter)).id, "special_sprinter")
    }

    func testMake_focusKing_id() {
        XCTAssertEqual(AchievementModel.make(.special(.focusKing)).id, "special_focusKing")
    }
}
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|FAIL|passed|failed" | head -20
```

Expected: 컴파일 에러 (`AchievementModel` not found)

- [ ] **Step 3: AchievementModel.swift 작성**

```swift
// CruxPet/AchievementModel.swift
import Foundation
import Observation

enum AchievementType {
    case commit(Int)
    case pomodoro(Int)
    case streak(Int)
    case level(Int)
    case questClear(Int)
    case special(SpecialKind)
}

enum SpecialKind: String {
    case nightOwl   // 자정(00:00~03:59) 커밋
    case sprinter   // 하루 커밋 5회
    case focusKing  // 하루 포모도로 3회
}

struct Achievement: Identifiable {
    let id: String
    let type: AchievementType
    let emoji: String
    let title: String
    let unlocksItemId: String?

    init(id: String, type: AchievementType, emoji: String, title: String, unlocksItemId: String? = nil) {
        self.id = id; self.type = type; self.emoji = emoji
        self.title = title; self.unlocksItemId = unlocksItemId
    }
}

@Observable
class AchievementModel {
    private(set) var claimedIds: Set<String> = []

    var claimedCount: Int { claimedIds.count }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "cruxpet.achievements.claimedIds") ?? []
        claimedIds = Set(saved)
    }

    // MARK: - Milestone generators (static, 테스트 가능)

    static func commitMilestones(upTo count: Int) -> [Int] {
        generateMilestones(seed: [1, 10, 50, 100, 250, 500, 1000, 2500, 5000, 10000], upTo: count) { last in
            max(last + 1, Int((Double(last) * 2.5 / 100).rounded()) * 100)
        }
    }

    static func pomodoroMilestones(upTo count: Int) -> [Int] {
        generateMilestones(seed: [1, 10, 25, 50, 100, 250, 500, 1000], upTo: count) { last in
            max(last + 1, Int((Double(last) * 2.5 / 100).rounded()) * 100)
        }
    }

    static func streakMilestones(upTo days: Int) -> [Int] {
        generateMilestones(seed: [3, 7, 14, 30, 60, 100, 200, 365, 730], upTo: days) { $0 + 365 }
    }

    static func levelMilestones(upTo level: Int) -> [Int] {
        generateMilestones(seed: [10, 20, 30, 50, 75, 100], upTo: level) { $0 + 50 }
    }

    static func questClearMilestones(upTo count: Int) -> [Int] {
        generateMilestones(seed: [1, 7, 30, 100, 365], upTo: count) { $0 + 365 }
    }

    // 시드 이후 공식으로 연장. 결과: 달성한 마일스톤 전부 + 다음 미달성 1개
    private static func generateMilestones(seed: [Int], upTo count: Int, next: (Int) -> Int) -> [Int] {
        var result: [Int] = []
        for m in seed {
            result.append(m)
            if m > count { return result }
        }
        var last = seed.last!
        while true {
            last = next(last)
            result.append(last)
            if last > count { return result }
        }
    }

    // MARK: - Achievement factory

    static func make(_ type: AchievementType) -> Achievement {
        switch type {
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
            case .sprinter:  return Achievement(id: "special_sprinter",   type: type, emoji: "⚡️", title: "스프린터")
            case .focusKing: return Achievement(id: "special_focusKing",  type: type, emoji: "🎯", title: "집중왕")
            }
        }
    }
}
```

- [ ] **Step 4: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "AchievementModelTests|error:" | head -20
```

Expected: 17개 테스트 모두 passed

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/AchievementModel.swift CruxPetTests/AchievementModelTests.swift
git commit -m "feat: AchievementModel 데이터 타입 및 마일스톤 생성기"
```

---

### Task 2: PetModel — 누적 카운터 추가

**Files:**
- Modify: `CruxPet/PetModel.swift`
- Modify: `CruxPetTests/PetModelTests.swift`

- [ ] **Step 1: PetModelTests에 테스트 추가**

`CruxPetTests/PetModelTests.swift`의 기존 테스트 아래에 추가:

```swift
    // MARK: - isNightOwlHour

    func testIsNightOwlHour_midnight() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 0; c.minute = 0
        XCTAssertTrue(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }

    func testIsNightOwlHour_3am() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 3; c.minute = 59
        XCTAssertTrue(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }

    func testIsNightOwlHour_4am() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 4; c.minute = 0
        XCTAssertFalse(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }

    func testIsNightOwlHour_noon() {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 9; c.hour = 12; c.minute = 0
        XCTAssertFalse(PetModel.isNightOwlHour(Calendar.current.date(from: c)!))
    }
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "isNightOwl|error:" | head -10
```

Expected: `isNightOwlHour` not found 에러

- [ ] **Step 3: PetModel에 4개 필드 추가**

`CruxPet/PetModel.swift`의 `private(set) var streakDays: Int = 0` 줄 아래에 추가:

```swift
    private(set) var totalCommitCount: Int = 0
    private(set) var totalPomodoroCount: Int = 0
    private(set) var questClearCount: Int = 0
    private(set) var hasNightOwlCommit: Bool = false
```

- [ ] **Step 4: init()에서 UserDefaults 로드**

`init()` 안의 `streakDays = UserDefaults.standard.integer(forKey: "cruxpet.streakDays")` 줄 아래에 추가:

```swift
        totalCommitCount  = UserDefaults.standard.integer(forKey: "cruxpet.totalCommitCount")
        totalPomodoroCount = UserDefaults.standard.integer(forKey: "cruxpet.totalPomodoroCount")
        questClearCount   = UserDefaults.standard.integer(forKey: "cruxpet.questClearCount")
        hasNightOwlCommit = UserDefaults.standard.bool(forKey: "cruxpet.hasNightOwlCommit")
```

- [ ] **Step 5: gainCommitExp()에 누적 카운터 + 야행성 감지 추가**

`gainCommitExp()` 안의 `todayCommitCount += 1` 줄 아래에 추가:

```swift
        totalCommitCount += 1
        if PetModel.isNightOwlHour(Date()) { hasNightOwlCommit = true }
```

- [ ] **Step 6: gainPomodoroExp()에 누적 카운터 추가**

`gainPomodoroExp()` 안의 `todayPomodoroCount += 1` 줄 아래에 추가:

```swift
        totalPomodoroCount += 1
```

- [ ] **Step 7: incrementQuestClear() 메서드 추가**

`gainQuestExp()` 메서드 바로 아래에 추가:

```swift
    @MainActor func incrementQuestClear() {
        questClearCount += 1
        persist()
    }
```

- [ ] **Step 8: static isNightOwlHour 추가**

`// MARK: - Pure static logic` 섹션 안, `expNeededForLevel` 앞에 추가:

```swift
    static func isNightOwlHour(_ date: Date) -> Bool {
        Calendar.current.component(.hour, from: date) < 4
    }
```

- [ ] **Step 9: persist()에 새 키 저장 추가**

`persist()` 안의 `UserDefaults.standard.set(lastActivityDate...` 줄 아래에 추가:

```swift
        UserDefaults.standard.set(totalCommitCount,   forKey: "cruxpet.totalCommitCount")
        UserDefaults.standard.set(totalPomodoroCount, forKey: "cruxpet.totalPomodoroCount")
        UserDefaults.standard.set(questClearCount,    forKey: "cruxpet.questClearCount")
        UserDefaults.standard.set(hasNightOwlCommit,  forKey: "cruxpet.hasNightOwlCommit")
```

- [ ] **Step 10: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "isNightOwl|error:" | head -10
```

Expected: 4개 isNightOwlHour 테스트 passed

- [ ] **Step 11: 커밋**

```bash
git add CruxPet/PetModel.swift CruxPetTests/PetModelTests.swift
git commit -m "feat: PetModel 누적 카운터 및 야행성 감지 추가"
```

---

### Task 3: AchievementModel — 클레임 로직 및 visibleAchievements

**Files:**
- Modify: `CruxPet/AchievementModel.swift`
- Modify: `CruxPetTests/AchievementModelTests.swift`

- [ ] **Step 1: AchievementModelTests에 테스트 추가**

기존 `AchievementModelTests` 클래스 안에 추가:

```swift
    // MARK: - isCompleted

    private func notCompleted(_ a: Achievement) -> Bool {
        !AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
    }

    func testIsCompleted_commit_notYet() {
        let a = AchievementModel.make(.commit(10))
        XCTAssertFalse(AchievementModel.isCompleted(a,
            totalCommitCount: 9, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0))
    }

    func testIsCompleted_commit_exact() {
        let a = AchievementModel.make(.commit(10))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 10, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0))
    }

    func testIsCompleted_nightOwl_false() {
        let a = AchievementModel.make(.special(.nightOwl))
        XCTAssertTrue(notCompleted(a))
    }

    func testIsCompleted_nightOwl_true() {
        let a = AchievementModel.make(.special(.nightOwl))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: true, todayCommitCount: 0, todayPomodoroCount: 0))
    }

    func testIsCompleted_sprinter_notYet() {
        let a = AchievementModel.make(.special(.sprinter))
        XCTAssertFalse(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 4, todayPomodoroCount: 0))
    }

    func testIsCompleted_sprinter_exact() {
        let a = AchievementModel.make(.special(.sprinter))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 5, todayPomodoroCount: 0))
    }

    func testIsCompleted_focusKing_exact() {
        let a = AchievementModel.make(.special(.focusKing))
        XCTAssertTrue(AchievementModel.isCompleted(a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 3))
    }

    // MARK: - progress

    func testProgress_commit_partial() {
        let a = AchievementModel.make(.commit(10))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 7, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 7)
        XCTAssertEqual(total, 10)
    }

    func testProgress_commit_capped() {
        let a = AchievementModel.make(.commit(10))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 15, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 10)
        XCTAssertEqual(total, 10)
    }

    func testProgress_nightOwl_unclaimed() {
        let a = AchievementModel.make(.special(.nightOwl))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 0)
        XCTAssertEqual(total, 1)
    }

    func testProgress_nightOwl_claimed() {
        let a = AchievementModel.make(.special(.nightOwl))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: true, todayCommitCount: 0, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 1)
        XCTAssertEqual(total, 1)
    }

    func testProgress_sprinter_partial() {
        let a = AchievementModel.make(.special(.sprinter))
        let (cur, total) = AchievementModel.progress(for: a,
            totalCommitCount: 0, totalPomodoroCount: 0, streakDays: 0,
            level: 1, questClearCount: 0,
            hasNightOwlCommit: false, todayCommitCount: 3, todayPomodoroCount: 0)
        XCTAssertEqual(cur, 3)
        XCTAssertEqual(total, 5)
    }
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "isCompleted|progress|error:" | head -10
```

Expected: `isCompleted` / `progress` not found 에러

- [ ] **Step 3: AchievementModel에 static isCompleted, static progress 추가**

`AchievementModel` 클래스 안, `make()` 메서드 아래에 추가:

```swift
    // MARK: - Completion logic (static, 테스트 가능)

    static func isCompleted(
        _ achievement: Achievement,
        totalCommitCount: Int, totalPomodoroCount: Int, streakDays: Int,
        level: Int, questClearCount: Int,
        hasNightOwlCommit: Bool, todayCommitCount: Int, todayPomodoroCount: Int
    ) -> Bool {
        switch achievement.type {
        case .commit(let n):     return totalCommitCount >= n
        case .pomodoro(let n):   return totalPomodoroCount >= n
        case .streak(let n):     return streakDays >= n
        case .level(let n):      return level >= n
        case .questClear(let n): return questClearCount >= n
        case .special(let kind):
            switch kind {
            case .nightOwl:  return hasNightOwlCommit
            case .sprinter:  return todayCommitCount >= 5
            case .focusKing: return todayPomodoroCount >= 3
            }
        }
    }

    static func progress(
        for achievement: Achievement,
        totalCommitCount: Int, totalPomodoroCount: Int, streakDays: Int,
        level: Int, questClearCount: Int,
        hasNightOwlCommit: Bool, todayCommitCount: Int, todayPomodoroCount: Int
    ) -> (current: Int, total: Int) {
        switch achievement.type {
        case .commit(let n):     return (min(totalCommitCount, n), n)
        case .pomodoro(let n):   return (min(totalPomodoroCount, n), n)
        case .streak(let n):     return (min(streakDays, n), n)
        case .level(let n):      return (min(level, n), n)
        case .questClear(let n): return (min(questClearCount, n), n)
        case .special(let kind):
            switch kind {
            case .nightOwl:  return (hasNightOwlCommit ? 1 : 0, 1)
            case .sprinter:  return (min(todayCommitCount, 5), 5)
            case .focusKing: return (min(todayPomodoroCount, 3), 3)
            }
        }
    }
```

- [ ] **Step 4: AchievementModel에 instance 메서드 추가**

static 메서드 아래에 추가:

```swift
    // MARK: - Instance methods

    func isClaimed(_ achievement: Achievement) -> Bool {
        claimedIds.contains(achievement.id)
    }

    func isCompleted(_ achievement: Achievement, pet: PetModel) -> Bool {
        Self.isCompleted(achievement,
            totalCommitCount: pet.totalCommitCount, totalPomodoroCount: pet.totalPomodoroCount,
            streakDays: pet.streakDays, level: pet.level, questClearCount: pet.questClearCount,
            hasNightOwlCommit: pet.hasNightOwlCommit,
            todayCommitCount: pet.todayCommitCount, todayPomodoroCount: pet.todayPomodoroCount)
    }

    func progress(for achievement: Achievement, pet: PetModel) -> (current: Int, total: Int) {
        Self.progress(for: achievement,
            totalCommitCount: pet.totalCommitCount, totalPomodoroCount: pet.totalPomodoroCount,
            streakDays: pet.streakDays, level: pet.level, questClearCount: pet.questClearCount,
            hasNightOwlCommit: pet.hasNightOwlCommit,
            todayCommitCount: pet.todayCommitCount, todayPomodoroCount: pet.todayPomodoroCount)
    }

    // 표시할 업적: 카테고리별 달성한 것 전부 + 다음 미달성 1개 + 특수 3개
    func visibleAchievements(for pet: PetModel) -> [Achievement] {
        var result: [Achievement] = []
        for n in Self.commitMilestones(upTo: pet.totalCommitCount)   { result.append(Self.make(.commit(n)))       }
        for n in Self.pomodoroMilestones(upTo: pet.totalPomodoroCount) { result.append(Self.make(.pomodoro(n)))   }
        for n in Self.streakMilestones(upTo: pet.streakDays)          { result.append(Self.make(.streak(n)))      }
        for n in Self.levelMilestones(upTo: pet.level)                { result.append(Self.make(.level(n)))       }
        for n in Self.questClearMilestones(upTo: pet.questClearCount) { result.append(Self.make(.questClear(n)))  }
        result.append(Self.make(.special(.nightOwl)))
        result.append(Self.make(.special(.sprinter)))
        result.append(Self.make(.special(.focusKing)))
        return result
    }

    @discardableResult
    func claimCompleted(pet: PetModel) -> [Achievement] {
        let visible = visibleAchievements(for: pet)
        var newlyClaimed: [Achievement] = []
        for achievement in visible {
            guard !claimedIds.contains(achievement.id) else { continue }
            guard isCompleted(achievement, pet: pet) else { continue }
            claimedIds.insert(achievement.id)
            newlyClaimed.append(achievement)
        }
        if !newlyClaimed.isEmpty {
            UserDefaults.standard.set(Array(claimedIds), forKey: "cruxpet.achievements.claimedIds")
        }
        return newlyClaimed
    }
```

- [ ] **Step 5: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "AchievementModelTests|error:" | head -20
```

Expected: AchievementModelTests 전체 passed

- [ ] **Step 6: 커밋**

```bash
git add CruxPet/AchievementModel.swift CruxPetTests/AchievementModelTests.swift
git commit -m "feat: AchievementModel 클레임 로직 및 visibleAchievements"
```

---

### Task 4: QuestModel — 올클리어 시 incrementQuestClear 호출

**Files:**
- Modify: `CruxPet/QuestModel.swift`

- [ ] **Step 1: claimCompleted(pet:) 수정**

`QuestModel.swift`에서 `claimCompleted(pet:)` 메서드 안의:

```swift
        if allDone && !alreadyClaimed {
            UserDefaults.standard.set(true, forKey: "cruxpet.quest.allClearClaimed")
            pet.gainQuestExp(100)
            return true
        }
```

를 다음으로 교체:

```swift
        if allDone && !alreadyClaimed {
            UserDefaults.standard.set(true, forKey: "cruxpet.quest.allClearClaimed")
            pet.gainQuestExp(100)
            pet.incrementQuestClear()
            return true
        }
```

- [ ] **Step 2: 전체 테스트 통과 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add CruxPet/QuestModel.swift
git commit -m "feat: 퀘스트 올클리어 시 questClearCount 증가"
```

---

### Task 5: ContentView — 업적 섹션 UI 및 이벤트 훅

**Files:**
- Modify: `CruxPet/ContentView.swift`

> **주의:** ContentView는 이미 `onChange(of: pet.todayPomodoroCount)`와 `onChange(of: pet.todayCommitCount)` 핸들러가 있다. SwiftUI에서 동일 property에 대한 `onChange`는 마지막 것만 실행된다. 이 태스크에서 추가하는 핸들러는 모두 새 property(`totalCommitCount`, `totalPomodoroCount`, `questClearCount`, `streakDays`)에 대한 것이므로 충돌 없음.

- [ ] **Step 1: State 및 helper 추가**

`ContentView` 구조체 안의 `@State private var isQuestExpanded = false` 줄 아래에 추가:

```swift
    @State private var achievementModel = AchievementModel()
    @State private var isAchievementExpanded = false
```

- [ ] **Step 2: VStack에 achievementSection 추가**

`ContentView.body` 안 VStack의 `questSection` 줄 아래에 추가:

```swift
                    achievementSection
```

결과적으로 순서: `characterSection` → `expSection` → `questSection` → `achievementSection` → `pomodoroSection` → `activitySection`

- [ ] **Step 3: checkAchievements() 헬퍼 추가**

`// MARK: - Setup` 섹션 위에 추가:

```swift
    private func checkAchievements() {
        let newOnes = achievementModel.claimCompleted(pet: pet)
        for a in newOnes {
            showToast(ToastData(emoji: "🏆", title: "업적 달성!", subtitle: a.title))
        }
    }
```

- [ ] **Step 4: onChange 핸들러 4개 추가**

기존 `.onChange(of: pet.todayCommitCount)` 핸들러 **아래**에 추가:

```swift
        .onChange(of: pet.totalCommitCount) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.totalPomodoroCount) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.questClearCount) { _, _ in
            checkAchievements()
        }
        .onChange(of: pet.streakDays) { _, _ in
            checkAchievements()
        }
```

- [ ] **Step 5: pendingLevelUp 핸들러에 checkAchievements() 추가**

기존 `.onChange(of: pet.pendingLevelUp)` 핸들러를 다음으로 교체:

```swift
        .onChange(of: pet.pendingLevelUp) { _, newLevel in
            guard newLevel > 0 else { return }
            pet.pendingLevelUp = 0
            showToast(ToastData(emoji: "🎉", title: "레벨 업! Lv.\(newLevel)",
                                subtitle: "슬라임이 성장했어요 ✨"))
            checkAchievements()
        }
```

- [ ] **Step 6: setupWatcher()에 achievement 초기 클레임 추가**

`setupWatcher()` 안의 `questsModel.claimCompleted(pet: pet)` 줄 아래에 추가:

```swift
        achievementModel.claimCompleted(pet: pet)
```

- [ ] **Step 7: achievementSection 뷰 추가**

`questSection` computed property 아래에 추가:

```swift
    private var achievementSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { isAchievementExpanded.toggle() }
            }) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("업적")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("✨ \(achievementModel.claimedCount)개 달성")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                    Image(systemName: isAchievementExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isAchievementExpanded {
                VStack(spacing: 4) {
                    ForEach(achievementModel.visibleAchievements(for: pet)) { achievement in
                        achievementRow(achievement)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
```

- [ ] **Step 8: achievementRow 뷰 함수 추가**

`questRow` 함수 아래에 추가:

```swift
    private func achievementRow(_ achievement: Achievement) -> some View {
        let claimed = achievementModel.isClaimed(achievement)
        let (cur, total) = achievementModel.progress(for: achievement, pet: pet)

        return HStack(spacing: 8) {
            Text(achievement.emoji)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.caption.weight(claimed ? .regular : .medium))
                    .foregroundStyle(claimed ? .secondary : .primary)

                if claimed {
                    Text("🎉 달성!")
                        .font(.system(size: 9))
                        .foregroundStyle(.green.opacity(0.7))
                } else if case .special(let kind) = achievement.type {
                    Text(specialConditionText(kind))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.15))
                            Capsule()
                                .fill(Color.orange.opacity(0.5))
                                .frame(width: total > 0
                                       ? geo.size.width * min(CGFloat(cur) / CGFloat(total), 1)
                                       : 0)
                        }
                    }
                    .frame(height: 4)

                    Text("\(cur)/\(total)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }

    private func specialConditionText(_ kind: SpecialKind) -> String {
        switch kind {
        case .nightOwl:  return "자정(00:00~03:59) 커밋"
        case .sprinter:  return "하루 커밋 5회"
        case .focusKing: return "하루 포모도로 3회"
        }
    }
```

- [ ] **Step 9: 빌드 확인**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|BUILD SUCCEEDED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 10: 전체 테스트 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 11: 커밋**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: 업적 섹션 UI 및 이벤트 훅 추가"
```
