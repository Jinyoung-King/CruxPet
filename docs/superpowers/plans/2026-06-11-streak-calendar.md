# 스트릭 캘린더 & EXP 배율 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 7칸 점 캘린더로 최근 7일 활동을 시각화하고, 스트릭 유지 시 EXP 배율을 높인다.

**Architecture:** `EventWatcher`에 정적 파싱 헬퍼 `activityDays(from:last:relativeTo:)` 추가, `PetModel`에 `multiplierForStreak(_:)` 정적 헬퍼 + `streakMultiplier` 프로퍼티 추가, ContentView에 7칸 캘린더 + 배지 배율 텍스트 추가.

**Tech Stack:** Swift, SwiftUI, XCTest, `~/.cruxpet/events.json`

---

## File Structure

| 파일 | 변경 |
|------|------|
| `CruxPet/EventWatcher.swift` | `activityDays(from:last:relativeTo:)` 정적 헬퍼 + `activityDays(last:)` 인스턴스 메서드 추가 |
| `CruxPet/PetModel.swift` | `multiplierForStreak(_:)` 정적 헬퍼 + `streakMultiplier` 계산 프로퍼티 + gain 메서드에 배율 적용 |
| `CruxPet/ContentView.swift` | `@State activityDays`, `streakBadge` 배율 텍스트, `streakCalendar` 뷰, 리프레시 로직 |
| `CruxPetTests/EventWatcherTests.swift` | `activityDays` 테스트 추가 |
| `CruxPetTests/PetModelTests.swift` | `multiplierForStreak` 테스트 추가 |

---

### Task 1: EventWatcher — activityDays 정적 헬퍼

**Files:**
- Modify: `CruxPet/EventWatcher.swift`
- Test: `CruxPetTests/EventWatcherTests.swift`

- [ ] **Step 1: 테스트 작성**

`CruxPetTests/EventWatcherTests.swift` 맨 아래에 추가:

```swift
// MARK: - activityDays

func testActivityDays_emptyContent() {
    let days = EventWatcher.activityDays(from: "", last: 7, relativeTo: Date())
    XCTAssertTrue(days.isEmpty)
}

func testActivityDays_todayEventIncluded() {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
    let ref = Calendar.current.date(from: comps)!
    let ts = Int(ref.timeIntervalSince1970)
    let content = "{\"type\":\"commit\",\"timestamp\":\(ts)}"
    let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
    let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
    XCTAssertTrue(days.contains(fmt.string(from: ref)))
}

func testActivityDays_sixDaysAgoIncluded() {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
    let ref = Calendar.current.date(from: comps)!
    let sixDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: ref)!
    let ts = Int(sixDaysAgo.timeIntervalSince1970)
    let content = "{\"type\":\"commit\",\"timestamp\":\(ts)}"
    let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
    let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
    XCTAssertTrue(days.contains(fmt.string(from: sixDaysAgo)))
}

func testActivityDays_sevenDaysAgoExcluded() {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
    let ref = Calendar.current.date(from: comps)!
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: ref)!
    let ts = Int(sevenDaysAgo.timeIntervalSince1970)
    let content = "{\"type\":\"commit\",\"timestamp\":\(ts)}"
    let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
    XCTAssertTrue(days.isEmpty)
}

func testActivityDays_multipleEventsOnSameDay() {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 6; comps.day = 11; comps.hour = 12
    let ref = Calendar.current.date(from: comps)!
    let ts = Int(ref.timeIntervalSince1970)
    let content = """
    {"type":"commit","timestamp":\(ts)}
    {"type":"pomodoro","timestamp":\(ts + 3600)}
    """
    let days = EventWatcher.activityDays(from: content, last: 7, relativeTo: ref)
    XCTAssertEqual(days.count, 1)
}
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -destination "platform=macOS" \
  -only-testing:CruxPetTests/EventWatcherTests/testActivityDays_emptyContent \
  -quiet 2>&1 | grep -E "PASS|FAIL|error:"
```

Expected: `error: 'activityDays' is not a member of 'EventWatcher'`

- [ ] **Step 3: 구현**

`CruxPet/EventWatcher.swift`의 `// MARK: - Pure static logic` 블록 안에 추가:

```swift
nonisolated static func activityDays(from content: String, last n: Int, relativeTo date: Date = Date()) -> Set<String> {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    let calendar = Calendar.current

    var validDays = Set<String>()
    for i in 0..<n {
        if let d = calendar.date(byAdding: .day, value: -i, to: date) {
            validDays.insert(fmt.string(from: d))
        }
    }

    let events = parseLines(content)
    return Set(events.compactMap { event -> String? in
        let dateStr = fmt.string(from: Date(timeIntervalSince1970: event.timestamp))
        return validDays.contains(dateStr) ? dateStr : nil
    })
}
```

`// MARK: - Private` 위에 인스턴스 메서드 추가:

```swift
nonisolated func activityDays(last n: Int) -> Set<String> {
    let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".cruxpet/events.json")
    guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    return EventWatcher.activityDays(from: content, last: n)
}
```

- [ ] **Step 4: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -destination "platform=macOS" \
  -only-testing:CruxPetTests/EventWatcherTests \
  -quiet 2>&1 | grep -E "PASS|FAIL|error:"
```

Expected: 기존 6개 + 신규 5개 모두 PASS

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/EventWatcher.swift CruxPetTests/EventWatcherTests.swift
git commit -m "feat: add EventWatcher.activityDays for streak calendar"
```

---

### Task 2: PetModel — streakMultiplier + gain 배율 적용

**Files:**
- Modify: `CruxPet/PetModel.swift`
- Test: `CruxPetTests/PetModelTests.swift`

- [ ] **Step 1: 테스트 작성**

`CruxPetTests/PetModelTests.swift` 맨 아래에 추가:

```swift
// MARK: - streakMultiplier

func testMultiplierBoundaries() {
    XCTAssertEqual(PetModel.multiplierForStreak(0),  1.0, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(1),  1.0, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(2),  1.0, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(3),  1.1, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(6),  1.1, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(7),  1.2, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(13), 1.2, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(14), 1.3, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(29), 1.3, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(30), 1.5, accuracy: 0.001)
    XCTAssertEqual(PetModel.multiplierForStreak(100),1.5, accuracy: 0.001)
}
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -destination "platform=macOS" \
  -only-testing:CruxPetTests/PetModelTests/testMultiplierBoundaries \
  -quiet 2>&1 | grep -E "PASS|FAIL|error:"
```

Expected: `error: 'multiplierForStreak' is not a member of 'PetModel'`

- [ ] **Step 3: PetModel에 정적 헬퍼 + 계산 프로퍼티 추가**

`PetModel.swift`의 `// MARK: - Pure static logic` 블록 안에 추가 (기존 static 함수들 아래):

```swift
static func multiplierForStreak(_ days: Int) -> Double {
    switch days {
    case 3...6:   return 1.1
    case 7...13:  return 1.2
    case 14...29: return 1.3
    case 30...:   return 1.5
    default:      return 1.0
    }
}
```

`PetModel` 클래스 안의 `var level: Int` 프로퍼티 아래에 추가:

```swift
var streakMultiplier: Double { PetModel.multiplierForStreak(streakDays) }
```

- [ ] **Step 4: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -destination "platform=macOS" \
  -only-testing:CruxPetTests/PetModelTests/testMultiplierBoundaries \
  -quiet 2>&1 | grep -E "PASS|FAIL|error:"
```

Expected: `PASS`

- [ ] **Step 5: gainCommitExp / gainPomodoroExp에 배율 적용**

`PetModel.swift`에서 `gainCommitExp` 수정:

```swift
@MainActor func gainCommitExp() {
    let prevLevel = level
    let (gained, isCrit) = PetModel.computeGain(base: 15, level: level)
    totalExp += (Double(gained) * streakMultiplier).rounded()
    todayCommitCount += 1
    totalCommitCount += 1
    if PetModel.isNightOwlHour(Date()) { hasNightOwlCommit = true }
    if isCrit { triggerCritical() }
    if level > prevLevel { triggerLevelUp(level) }
    updateStreak()
    triggerExcitement()
    persist()
}
```

`gainPomodoroExp` 수정:

```swift
@MainActor func gainPomodoroExp() {
    let prevLevel = level
    let (gained, isCrit) = PetModel.computeGain(base: 50, level: level)
    totalExp += (Double(gained) * streakMultiplier).rounded()
    todayPomodoroCount += 1
    totalPomodoroCount += 1
    if isCrit { triggerCritical() }
    if level > prevLevel { triggerLevelUp(level) }
    updateStreak()
    triggerExcitement()
    persist()
}
```

- [ ] **Step 6: 전체 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -destination "platform=macOS" \
  -only-testing:CruxPetTests/PetModelTests \
  -quiet 2>&1 | grep -E "PASS|FAIL|error:"
```

Expected: 기존 테스트 포함 전부 PASS

- [ ] **Step 7: 커밋**

```bash
git add CruxPet/PetModel.swift CruxPetTests/PetModelTests.swift
git commit -m "feat: add streak EXP multiplier (1.0x–1.5x based on streak days)"
```

---

### Task 3: ContentView — 7칸 캘린더 + 배지 배율 텍스트

**Files:**
- Modify: `CruxPet/ContentView.swift`

이 태스크는 UI 변경이므로 수동으로 앱을 실행해서 확인한다.

- [ ] **Step 1: @State 및 헬퍼 추가**

ContentView의 기존 `@State` 선언들 아래에 추가:

```swift
@State private var activityDays: Set<String> = []
```

ContentView의 `// MARK: - Setup` 섹션 안에 추가:

```swift
private func refreshActivityDays() {
    activityDays = watcher.activityDays(last: 7)
}

private func last7Days() -> [String] {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return (0..<7).reversed().map { i in
        fmt.string(from: Calendar.current.date(byAdding: .day, value: -i, to: Date())!)
    }
}

private func weekdayLabel(for dateStr: String) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    guard let date = fmt.date(from: dateStr) else { return "" }
    let labels = ["일", "월", "화", "수", "목", "금", "토"]
    return labels[Calendar.current.component(.weekday, from: date) - 1]
}
```

- [ ] **Step 2: onAppear에 refreshActivityDays 추가**

기존:

```swift
.onAppear {
    setupWatcher()
    watcher.pollNow()
}
```

변경 후:

```swift
.onAppear {
    setupWatcher()
    watcher.pollNow()
    refreshActivityDays()
}
```

- [ ] **Step 3: onChange에 refreshActivityDays 추가**

기존 `onChange(of: pet.todayCommitCount)`:

```swift
.onChange(of: pet.todayCommitCount) { _, _ in
    if questsModel.claimCompleted(pet: pet) {
        showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
    }
}
```

변경 후:

```swift
.onChange(of: pet.todayCommitCount) { _, _ in
    if questsModel.claimCompleted(pet: pet) {
        showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
    }
    refreshActivityDays()
}
```

기존 `onChange(of: pet.todayPomodoroCount)`:

```swift
.onChange(of: pet.todayPomodoroCount) { old, new in
    if new > old {
        showToast(ToastData(emoji: "🍅", title: "포모도로 완료!", subtitle: "EXP를 획득했어요 ✨"))
    }
    if questsModel.claimCompleted(pet: pet) {
        showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
    }
}
```

변경 후:

```swift
.onChange(of: pet.todayPomodoroCount) { old, new in
    if new > old {
        showToast(ToastData(emoji: "🍅", title: "포모도로 완료!", subtitle: "EXP를 획득했어요 ✨"))
    }
    if questsModel.claimCompleted(pet: pet) {
        showToast(ToastData(emoji: "🎉", title: "퀘스트 올클리어!", subtitle: "+100 EXP 보너스 지급!"))
    }
    refreshActivityDays()
}
```

- [ ] **Step 4: streakBadge에 배율 텍스트 추가**

기존 `streakBadge`:

```swift
private var streakBadge: some View {
    HStack(spacing: 3) {
        Text("🔥")
            .font(.system(size: 11))
        Text("\(pet.streakDays)일 연속")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(streakColor)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(streakColor.opacity(0.12), in: Capsule())
}
```

변경 후:

```swift
private var streakBadge: some View {
    HStack(spacing: 3) {
        Text("🔥")
            .font(.system(size: 11))
        Text("\(pet.streakDays)일 연속")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(streakColor)
        if pet.streakMultiplier > 1.0 {
            Text("×\(String(format: "%.1f", pet.streakMultiplier))")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(streakColor.opacity(0.8))
        }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(streakColor.opacity(0.12), in: Capsule())
}
```

- [ ] **Step 5: streakCalendar 뷰 추가**

`streakBadge` 프로퍼티 아래에 추가:

```swift
private var streakCalendar: some View {
    let days = last7Days()
    let todayStr = days.last ?? ""
    return HStack(spacing: 0) {
        ForEach(days, id: \.self) { dateStr in
            let isActive = activityDays.contains(dateStr)
            let isToday = dateStr == todayStr
            VStack(spacing: 3) {
                Text(weekdayLabel(for: dateStr))
                    .font(.system(size: 8, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? streakColor : Color.secondary.opacity(0.5))
                Image(systemName: isActive ? "circle.fill" : "circle")
                    .font(.system(size: 8))
                    .foregroundStyle(isActive ? streakColor : Color.secondary.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
        }
    }
    .padding(.horizontal, 4)
}
```

- [ ] **Step 6: characterSection에 streakCalendar 추가**

기존 `characterSection` 안의 `streakBadge` 블록:

```swift
if pet.streakDays > 0 {
    streakBadge
        .transition(.scale.combined(with: .opacity))
}
```

변경 후:

```swift
if pet.streakDays > 0 {
    streakBadge
        .transition(.scale.combined(with: .opacity))
    streakCalendar
        .transition(.opacity)
}
```

- [ ] **Step 7: 빌드 확인**

```bash
xcodebuild build -scheme CruxPet -destination "platform=macOS" -quiet 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: 앱 실행 후 수동 확인**

Xcode에서 앱 실행 후:
1. 메뉴바 아이콘 클릭 → 팝업 열기
2. streakDays > 0이면 배지 아래에 7칸 점 캘린더 보임 확인
3. 오늘 날짜 요일 레이블이 굵게 표시되는지 확인
4. 활동한 날은 채워진 원, 아닌 날은 빈 원 확인
5. streakDays >= 3이면 배지에 `×1.1` 텍스트 보임 확인

streakDays를 테스트하려면 UserDefaults를 임시로 조작:

```bash
defaults write kr.co.cruxdata.CruxPet cruxpet.streakDays -int 7
defaults write kr.co.cruxdata.CruxPet cruxpet.streakDate "2026-06-11"
```

앱 재시작 후 `🔥 7일 연속 ×1.2` 배지 + 캘린더 확인. 테스트 후 원복:

```bash
defaults delete kr.co.cruxdata.CruxPet cruxpet.streakDays
defaults delete kr.co.cruxdata.CruxPet cruxpet.streakDate
```

- [ ] **Step 9: 커밋**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: streak calendar (7-day grid) + multiplier badge"
```
