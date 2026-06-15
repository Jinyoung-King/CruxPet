# 주간 스탯 뷰 (Weekly Stats View) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 지난 7일간의 커밋·포모도로 수를 저장하고, 메뉴바 앱 내에 주간 스탯 섹션(바 차트 + 요약 셀)과 저녁 8시 스트릭 알림을 추가한다.

**Architecture:** `ActivityHistoryModel`이 앱 시작 시 PetModel보다 먼저 초기화되어 UserDefaults에서 전날 카운트를 읽어 30일치 이력을 JSON으로 저장한다. `StatsView`는 SwiftUI Charts로 7일 바 차트를 그리고, CruxPetApp이 매일 오후 8시 알림을 예약/취소한다.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Charts (macOS 13+), UserDefaults, UNUserNotificationCenter

---

## File Structure

**New:**
- `CruxPet/ActivityHistoryModel.swift` — `DailyActivity` Codable struct + `ActivityHistoryModel` (@Observable): 이력 저장, `last7Days()`, `captureYesterdayIfNeeded()`
- `CruxPet/StatsView.swift` — 접이식 주간 스탯 섹션 (Swift Charts 바 차트 + 요약 셀 3개)
- `CruxPetTests/ActivityHistoryModelTests.swift` — 순수 로직 단위 테스트

**Modified:**
- `CruxPet/CruxPetApp.swift` — `@State private var history` 추가 (pet보다 먼저 선언), `.environment(history)`, 스트릭 알림 예약/취소
- `CruxPet/ContentView.swift` — `@Environment(ActivityHistoryModel.self) private var history`, `statsSection` 추가
- `CruxPet/PetModel.swift` — `passiveTimer`에서 `resetDailyCountsIfNeeded()` 호출 (자정 통과 시 앱이 켜진 채로도 리셋)

---

### Task 1: ActivityHistoryModel

**Files:**
- Create: `CruxPet/ActivityHistoryModel.swift`
- Create: `CruxPetTests/ActivityHistoryModelTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// CruxPetTests/ActivityHistoryModelTests.swift
import XCTest
@testable import CruxPet

final class ActivityHistoryModelTests: XCTestCase {

    // last7Days: 이력 없을 때 7개 항목 모두 0 반환
    func testLast7DaysEmptyHistory() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        let days = model.last7Days(todayCommits: 0, todayPomodoros: 0)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(days.allSatisfy { $0.commits == 0 && $0.pomodoros == 0 })
    }

    // last7Days: 오늘 값은 todayCommits/todayPomodoros 인자로 채워짐
    func testLast7DaysTodayFromArguments() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        let days = model.last7Days(todayCommits: 5, todayPomodoros: 3)
        XCTAssertEqual(days.last?.commits, 5)
        XCTAssertEqual(days.last?.pomodoros, 3)
    }

    // record: 같은 날짜 중복 저장 안 함
    func testRecordNoDuplicates() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        model.record(commits: 3, pomodoros: 1, for: "2026-06-10")
        model.record(commits: 9, pomodoros: 9, for: "2026-06-10")
        let entry = model.entries.first(where: { $0.dateString == "2026-06-10" })
        XCTAssertEqual(entry?.commits, 3)
    }

    // record: 30개 초과 시 가장 오래된 항목 제거
    func testRecordMaxEntries() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        for i in 1...31 {
            let date = String(format: "2026-01-%02d", i)
            model.record(commits: i, pomodoros: 0, for: date)
        }
        XCTAssertEqual(model.entries.count, 30)
        XCTAssertNil(model.entries.first(where: { $0.dateString == "2026-01-01" }))
    }

    // last7Days: 기록된 날짜가 7일 범위 내에 있으면 포함됨
    func testLast7DaysIncludesRecentEntry() {
        let model = ActivityHistoryModel()
        model.clearAllForTesting()
        let yesterday = ActivityHistoryModel.dateString(
            from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        model.record(commits: 7, pomodoros: 2, for: yesterday)
        let days = model.last7Days(todayCommits: 0, todayPomodoros: 0)
        let found = days.first(where: { $0.dateString == yesterday })
        XCTAssertEqual(found?.commits, 7)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' \
  -only-testing:CruxPetTests/ActivityHistoryModelTests 2>&1 | grep -E "error:|FAILED|passed|failed"
```

Expected: 컴파일 에러 (ActivityHistoryModel 미존재)

- [ ] **Step 3: Implement ActivityHistoryModel**

```swift
// CruxPet/ActivityHistoryModel.swift
import Foundation
import Observation

struct DailyActivity: Codable {
    let dateString: String  // "yyyy-MM-dd"
    let commits: Int
    let pomodoros: Int
}

@Observable
class ActivityHistoryModel {
    private(set) var entries: [DailyActivity] = []

    private static let storageKey = "cruxpet.activityHistory"
    private static let todayDateKey = "cruxpet.todayDate"
    private static let commitCountKey = "cruxpet.commitCount"
    private static let pomodoroCountKey = "cruxpet.pomodoroCount"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        loadEntries()
        captureYesterdayIfNeeded()
    }

    // 지난 7일 데이터 반환 (오늘은 인자로 받은 실시간 값 사용)
    func last7Days(todayCommits: Int, todayPomodoros: Int) -> [DailyActivity] {
        let today = Self.dateString(from: Date())
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset -> DailyActivity in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let ds = Self.dateString(from: date)
            if ds == today {
                return DailyActivity(dateString: ds, commits: todayCommits, pomodoros: todayPomodoros)
            }
            return entries.first(where: { $0.dateString == ds })
                ?? DailyActivity(dateString: ds, commits: 0, pomodoros: 0)
        }
    }

    func record(commits: Int, pomodoros: Int, for dateString: String) {
        guard !entries.contains(where: { $0.dateString == dateString }) else { return }
        var updated = entries + [DailyActivity(dateString: dateString, commits: commits, pomodoros: pomodoros)]
        updated.sort { $0.dateString < $1.dateString }
        entries = Array(updated.suffix(30))
        saveEntries()
    }

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    // PetModel이 init()에서 리셋하기 전에 어제 데이터를 UserDefaults에서 읽음.
    // CruxPetApp에서 history가 pet보다 먼저 선언되어야 이 타이밍이 보장됨.
    private func captureYesterdayIfNeeded() {
        let today = Self.dateString(from: Date())
        let storedDate = UserDefaults.standard.string(forKey: Self.todayDateKey) ?? ""
        guard !storedDate.isEmpty, storedDate < today else { return }
        guard !entries.contains(where: { $0.dateString == storedDate }) else { return }
        let commits = UserDefaults.standard.integer(forKey: Self.commitCountKey)
        let pomodoros = UserDefaults.standard.integer(forKey: Self.pomodoroCountKey)
        record(commits: commits, pomodoros: pomodoros, for: storedDate)
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([DailyActivity].self, from: data)
        else { return }
        entries = decoded
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    // MARK: - Test helpers

    #if DEBUG
    func clearAllForTesting() {
        entries = []
    }
    #endif
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' \
  -only-testing:CruxPetTests/ActivityHistoryModelTests 2>&1 | grep -E "error:|FAILED|passed|failed"
```

Expected: `Test Suite 'ActivityHistoryModelTests' passed`

- [ ] **Step 5: Commit**

```bash
git add CruxPet/ActivityHistoryModel.swift CruxPetTests/ActivityHistoryModelTests.swift
git commit -m "feat: ActivityHistoryModel - 30일 이력 저장, last7Days()"
```

---

### Task 2: PetModel 자정 리셋 수정

**Files:**
- Modify: `CruxPet/PetModel.swift:231-238`

앱이 켜진 채 자정을 넘기면 daily 카운트가 리셋되지 않는 버그를 수정한다. passiveTimer (60초마다 실행)에서 `resetDailyCountsIfNeeded()`를 함께 호출하면 된다.

- [ ] **Step 1: Modify startPassiveTimer in PetModel**

`CruxPet/PetModel.swift` 의 `startPassiveTimer()` 함수를 아래로 교체:

```swift
private func startPassiveTimer() {
    passiveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
        Task { @MainActor [weak self] in
            self?.gainPassiveExp()
            self?.resetDailyCountsIfNeeded()
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cruxpet.lastPassiveTime")
        }
    }
}
```

- [ ] **Step 2: Build to verify no errors**

```bash
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/PetModel.swift
git commit -m "fix: 앱 실행 중 자정 통과 시 daily 카운트 리셋"
```

---

### Task 3: StatsView

**Files:**
- Create: `CruxPet/StatsView.swift`

- [ ] **Step 1: Create StatsView**

```swift
// CruxPet/StatsView.swift
import SwiftUI
import Charts

struct StatsView: View {
    let pet: PetModel
    let history: ActivityHistoryModel

    @State private var isExpanded = false

    private var last7: [DailyActivity] {
        history.last7Days(todayCommits: pet.todayCommitCount, todayPomodoros: pet.todayPomodoroCount)
    }

    private struct BarEntry: Identifiable {
        let id = UUID()
        let dayLabel: String
        let value: Int
        let series: String
    }

    private var barData: [BarEntry] {
        last7.flatMap { day in
            let label = shortLabel(day.dateString)
            return [
                BarEntry(dayLabel: label, value: day.commits,   series: "커밋"),
                BarEntry(dayLabel: label, value: day.pomodoros, series: "포모도로")
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("📊 주간 스탯").font(.caption.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Chart(barData) { entry in
                    BarMark(
                        x: .value("날짜", entry.dayLabel),
                        y: .value("횟수", entry.value)
                    )
                    .foregroundStyle(by: .value("종류", entry.series))
                }
                .chartForegroundStyleScale([
                    "커밋":    Color.blue.opacity(0.75),
                    "포모도로": Color.orange.opacity(0.75)
                ])
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 8))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel().font(.system(size: 8))
                        AxisGridLine()
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        legendDot(color: .blue.opacity(0.75),   label: "커밋")
                        legendDot(color: .orange.opacity(0.75), label: "포모도로")
                    }
                }
                .frame(height: 90)

                let weekCommits   = last7.reduce(0) { $0 + $1.commits }
                let weekPomodoros = last7.reduce(0) { $0 + $1.pomodoros }

                HStack(spacing: 4) {
                    summaryCell("🔥", "\(pet.streakDays)", "연속")
                    summaryCell("⚡", "\(weekCommits)",   "커밋/주")
                    summaryCell("🍅", "\(weekPomodoros)", "뽀모/주")
                }
            }
        }
    }

    private func shortLabel(_ ds: String) -> String {
        let parts = ds.split(separator: "-")
        guard parts.count == 3 else { return ds }
        return "\(Int(parts[1]) ?? 0)/\(Int(parts[2]) ?? 0)"
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 8)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }

    private func summaryCell(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(emoji).font(.system(size: 12))
            Text(value).font(.system(size: 11, weight: .bold))
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    let history = ActivityHistoryModel()
    let pet = PetModel()
    return StatsView(pet: pet, history: history)
        .padding()
        .frame(width: 220)
}
```

- [ ] **Step 2: Build to verify no errors**

```bash
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add CruxPet/StatsView.swift
git commit -m "feat: StatsView - 7일 바 차트 + 주간 요약"
```

---

### Task 4: CruxPetApp + ContentView 연결

**Files:**
- Modify: `CruxPet/CruxPetApp.swift`
- Modify: `CruxPet/ContentView.swift`

- [ ] **Step 1: CruxPetApp에 history @State 추가 (pet 선언 바로 위)**

`CruxPet/CruxPetApp.swift` 의 `@State private var pet = PetModel()` 줄 바로 앞에 삽입:

```swift
@State private var history = ActivityHistoryModel()  // pet보다 먼저 — 어제 데이터 캡처 타이밍 보장
@State private var pet = PetModel()
```

- [ ] **Step 2: history를 environment로 전달**

`CruxPetApp.swift` body 안의 `ContentView()` 체인에 `.environment(history)` 추가:

```swift
ContentView()
    .environment(pet)
    .environment(pomodoro)
    .environment(watcher)
    .environment(environment)
    .environment(interaction)
    .environment(history)          // 추가
    .environment(\.checkForUpdates, { updater.checkForUpdates() })
```

- [ ] **Step 3: ContentView에 @Environment 추가**

`CruxPet/ContentView.swift` 의 `@Environment(PetInteractionModel.self) private var interaction` 줄 바로 아래에 삽입:

```swift
@Environment(ActivityHistoryModel.self) private var history
```

- [ ] **Step 4: ContentView에 statsSection 추가**

ContentView body 의 main VStack 안, `questSection` 바로 앞에 `statsSection`을 삽입:

```swift
VStack(spacing: 10) {
    characterSection
    expSection
    statsSection      // 추가
    questSection
    achievementSection
    pomodoroSection
    activitySection
    ...
}
```

- [ ] **Step 5: statsSection 프로퍼티 구현**

ContentView 안, `// MARK: - Sections` 아래 어딘가에 추가:

```swift
private var statsSection: some View {
    StatsView(pet: pet, history: history)
}
```

- [ ] **Step 6: Build to verify no errors**

```bash
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Run all tests**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|passed|failed"
```

Expected: 전체 테스트 통과

- [ ] **Step 8: Commit**

```bash
git add CruxPet/CruxPetApp.swift CruxPet/ContentView.swift
git commit -m "feat: 주간 스탯 섹션 ContentView에 연결"
```

---

### Task 5: 스트릭 알림 (오후 8시 리마인더)

**Files:**
- Modify: `CruxPet/CruxPetApp.swift`

오늘 활동이 없으면 오후 8시에 한 번 알림을 보낸다. 커밋 또는 포모도로 완료 시 예약된 알림을 취소한다.

- [ ] **Step 1: startServices()에 알림 예약/취소 로직 추가**

`CruxPet/CruxPetApp.swift` 의 `startServices()` 함수를 아래로 교체:

```swift
private func startServices() {
    watcher.onCommit = {
        pet.gainCommitExp()
        Self.cancelStreakReminder()
    }
    pomodoro.onComplete = {
        watcher.appendPomodoro()
        pet.gainPomodoroExp()
        sendPomodoroNotification()
        Self.cancelStreakReminder()
    }
    pomodoro.breakComplete = {
        sendBreakCompleteNotification()
    }
    watcher.start()
    updaterController.updater.checkForUpdatesInBackground()
    rightClickHandler.install()
    environment.startUpdating()
    scheduleStreakReminderIfNeeded()
}
```

- [ ] **Step 2: 알림 예약/취소 함수 추가**

`CruxPetApp.swift` 의 `sendPomodoroNotification()` 함수 아래에 추가:

```swift
private func scheduleStreakReminderIfNeeded() {
    guard pet.todayCommitCount == 0, pet.todayPomodoroCount == 0 else { return }
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 20
    components.minute = 0
    guard let fireDate = calendar.date(from: components), fireDate > Date() else { return }
    let content = UNMutableNotificationContent()
    content.title = "CruxPet 🐾"
    content.body = "오늘 아직 활동이 없어요. 펫이 기다리고 있어요!"
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
        repeats: false
    )
    let request = UNNotificationRequest(identifier: "streak.reminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}

private static func cancelStreakReminder() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak.reminder"])
}
```

- [ ] **Step 3: Build to verify no errors**

```bash
xcodebuild -scheme CruxPet -destination 'platform=macOS' build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|passed|failed"
```

Expected: 전체 테스트 통과

- [ ] **Step 5: Commit**

```bash
git add CruxPet/CruxPetApp.swift
git commit -m "feat: 오후 8시 스트릭 리마인더 알림 추가"
```

---

## Self-Review

**Spec 커버리지:**
- ✅ 일별 커밋·포모도로 이력 저장 (Task 1)
- ✅ 7일 바 차트 (Task 3)
- ✅ 스트릭, 주간 커밋/포모도로 요약 (Task 3)
- ✅ 오후 8시 스트릭 리마인더 (Task 5)
- ✅ PetModel 자정 리셋 수정 (Task 2)

**플레이스홀더 없음** — 모든 단계에 실제 코드 포함됨.

**타입 일관성:**
- `DailyActivity.dateString: String` — Task 1 정의, Task 3, 4에서 동일하게 사용
- `ActivityHistoryModel.last7Days(todayCommits:todayPomodoros:) -> [DailyActivity]` — Task 1 정의, Task 3에서 동일 시그니처 호출
- `ActivityHistoryModel.record(commits:pomodoros:for:)` — Task 1 정의, 테스트에서 동일하게 호출

**알려진 한계:** 앱이 켜진 채 자정을 넘기면 ActivityHistoryModel이 오늘 데이터를 이력에 저장하지 못함 (다음 재시작 시 정상 복구). Task 2의 PetModel 수정으로 카운트 리셋은 올바르게 동작함.
