# CruxPet 생산성 연동 펫 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** macOS 메뉴바 앱에 Git 커밋·포모도로 타이머 연동 EXP 시스템과 레벨업 슬라임 캐릭터를 구현한다.

**Architecture:** Git post-commit hook이 `~/.cruxpet/events.json`에 이벤트를 기록하고, EventWatcher가 2초 폴링으로 읽어 PetModel에 EXP를 반영한다. 포모도로 완료도 같은 파일에 기록한다. 슬라임은 SwiftUI Canvas + TimelineView로 레벨에 따라 모양·색·왕관·반짝이가 달라진다.

**Tech Stack:** Swift 5.9+, SwiftUI, Swift Observation (`@Observable`), Foundation, UserNotifications, XCTest

---

## File Map

| 파일 | 역할 |
|------|------|
| `CruxPet/PetModel.swift` | 신규 — EXP 수치, 레벨, SlimeAppearance 계산 (순수 로직, 테스트 가능) |
| `CruxPet/SlimeView.swift` | 신규 — Canvas 도트 캐릭터 렌더링 + 애니메이션 |
| `CruxPet/PomodoroTimer.swift` | 신규 — 포모도로 상태 머신 (idle/running/paused/completed) |
| `CruxPet/EventWatcher.swift` | 신규 — `~/.cruxpet/events.json` 폴링·파싱 |
| `CruxPet/ContentView.swift` | 수정 — 전체 UI 재작성 (TamagotchiModel 제거) |
| `CruxPet/CruxPetApp.swift` | 수정 — 알림 권한 요청 추가 |
| `CruxPetTests/PetModelTests.swift` | 신규 — PetModel 순수 로직 단위 테스트 |
| `CruxPetTests/PomodoroTimerTests.swift` | 신규 — PomodoroTimer 상태 전이 테스트 |
| `CruxPetTests/EventWatcherTests.swift` | 신규 — JSON Lines 파싱 테스트 |
| `scripts/install-hook.sh` | 신규 — git global post-commit hook 설치 스크립트 |

---

## Task 1: Xcode 테스트 타겟 추가

기존 프로젝트에 테스트 타겟이 없으므로 Xcode에서 직접 추가해야 한다.

**Files:**
- Create: `CruxPetTests/PetModelTests.swift` (타겟 추가 후)

- [ ] **Step 1: Xcode에서 테스트 타겟 추가**

  Xcode에서 `CruxPet.xcodeproj`를 열고:
  1. `File → New → Target` 선택
  2. `macOS → Unit Testing Bundle` 선택
  3. Product Name: `CruxPetTests`
  4. Target to be Tested: `CruxPet`
  5. Finish

- [ ] **Step 2: 빈 smoke test 작성**

  `CruxPetTests/CruxPetTests.swift` (자동 생성된 파일) 내용을 아래로 교체:

  ```swift
  import XCTest

  final class SmokeTests: XCTestCase {
      func testTrue() {
          XCTAssertTrue(true)
      }
  }
  ```

- [ ] **Step 3: 테스트 실행 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(PASS|FAIL|error:)" | head -10
  ```

  Expected: `Test Suite 'All tests' passed`

---

## Task 2: PetModel — EXP·레벨 순수 로직

**Files:**
- Create: `CruxPet/PetModel.swift`
- Create: `CruxPetTests/PetModelTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

  `CruxPetTests/PetModelTests.swift`:

  ```swift
  import XCTest
  @testable import CruxPet

  final class PetModelTests: XCTestCase {

      // 레벨 1에서는 100 EXP 필요
      func testExpNeededForLevel1() {
          XCTAssertEqual(PetModel.expNeededForLevel(1), 100)
      }

      // 레벨 2에서는 floor(100 * 2^1.5) = floor(282.84) = 282
      func testExpNeededForLevel2() {
          XCTAssertEqual(PetModel.expNeededForLevel(2), 282)
      }

      // 총 EXP 0 → 레벨 1
      func testLevelForExpZero() {
          XCTAssertEqual(PetModel.levelForExp(0), 1)
      }

      // 총 EXP 99 → 레벨 1 (99 < 100이므로 아직 레벨업 불가)
      func testLevelForExp99() {
          XCTAssertEqual(PetModel.levelForExp(99), 1)
      }

      // 총 EXP 100 → 레벨 2
      func testLevelForExp100() {
          XCTAssertEqual(PetModel.levelForExp(100), 2)
      }

      // 총 EXP 382 (100 + 282) → 레벨 3
      func testLevelForExp382() {
          XCTAssertEqual(PetModel.levelForExp(382), 3)
      }

      // 레벨 1 시작점 EXP = 0
      func testTotalExpAtLevel1() {
          XCTAssertEqual(PetModel.totalExpAtLevelStart(1), 0)
      }

      // 레벨 2 시작점 EXP = 100
      func testTotalExpAtLevel2() {
          XCTAssertEqual(PetModel.totalExpAtLevelStart(2), 100)
      }

      // computeGain: 결과가 base*√level*0.8 ~ base*√level*1.2*2 범위 안에 있어야 함
      func testComputeGainRange() {
          let level = 10
          let base = 15.0
          let minExpected = Int((base * sqrt(Double(level)) * 0.8).rounded())
          let maxExpected = Int((base * sqrt(Double(level)) * 1.2 * 2.0).rounded())
          for _ in 0..<100 {
              let (gained, _) = PetModel.computeGain(base: base, level: level)
              XCTAssertGreaterThanOrEqual(gained, minExpected)
              XCTAssertLessThanOrEqual(gained, maxExpected)
          }
      }

      // 크리티컬은 gained가 non-crit 최솟값보다 크거나 같아야 함
      func testComputeGainCritical() {
          var sawCritical = false
          for _ in 0..<1000 {
              let (_, isCrit) = PetModel.computeGain(base: 50, level: 1)
              if isCrit { sawCritical = true; break }
          }
          XCTAssertTrue(sawCritical, "1000번 중 크리티컬이 한 번도 안 나오면 실패")
      }

      // 레벨 1 → 파랑 슬라임
      func testAppearanceLevel1() {
          let a = PetModel.appearance(for: 1)
          XCTAssertEqual(a.size, 24)
          XCTAssertEqual(a.crownType, .none)
          XCTAssertEqual(a.sparkleCount, 0)
          XCTAssertFalse(a.isRainbow)
      }

      // 레벨 10 → 동관
      func testAppearanceLevel10() {
          let a = PetModel.appearance(for: 10)
          XCTAssertEqual(a.crownType, .bronze)
      }

      // 레벨 30 → 무지개 + 금관
      func testAppearanceLevel30() {
          let a = PetModel.appearance(for: 30)
          XCTAssertTrue(a.isRainbow)
          XCTAssertEqual(a.crownType, .gold)
      }

      // 레벨 100 → 성좌관 + isPearl
      func testAppearanceLevel100() {
          let a = PetModel.appearance(for: 100)
          XCTAssertEqual(a.crownType, .constellation)
          XCTAssertTrue(a.isPearl)
      }
  }
  ```

- [ ] **Step 2: 테스트 실패 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|FAIL)" | head -5
  ```

  Expected: 컴파일 에러 (`PetModel` 없음)

- [ ] **Step 3: PetModel 구현**

  `CruxPet/PetModel.swift`:

  ```swift
  import Foundation
  import SwiftUI
  import Observation

  enum CrownType: Int, Equatable {
      case none, bronze, silver, gold, diamond, constellation
      var symbol: String {
          switch self {
          case .none:           return ""
          case .bronze:         return "🥉"
          case .silver:         return "🥈"
          case .gold:           return "👑"
          case .diamond:        return "💎"
          case .constellation:  return "✨"
          }
      }
  }

  struct SlimeAppearance {
      let bodyHex: String
      let size: CGFloat
      let crownType: CrownType
      let sparkleCount: Int
      let hasHalo: Bool
      let isRainbow: Bool
      let isPearl: Bool
  }

  @Observable
  class PetModel {
      private(set) var totalExp: Double = 0
      private(set) var todayCommitCount: Int = 0
      private(set) var todayPomodoroCount: Int = 0
      private(set) var showCritical: Bool = false

      var level: Int { PetModel.levelForExp(totalExp) }
      var expInCurrentLevel: Double { totalExp - PetModel.totalExpAtLevelStart(level) }
      var expNeededThisLevel: Double { PetModel.expNeededForLevel(level) }
      var slimeAppearance: SlimeAppearance { PetModel.appearance(for: level) }

      init() {
          totalExp = UserDefaults.standard.double(forKey: "cruxpet.totalExp")
          todayCommitCount = UserDefaults.standard.integer(forKey: "cruxpet.commitCount")
          todayPomodoroCount = UserDefaults.standard.integer(forKey: "cruxpet.pomodoroCount")
          resetDailyCountsIfNeeded()
      }

      func gainCommitExp() {
          let (gained, isCrit) = PetModel.computeGain(base: 15, level: level)
          totalExp += Double(gained)
          todayCommitCount += 1
          if isCrit { triggerCritical() }
          persist()
      }

      func gainPomodoroExp() {
          let (gained, isCrit) = PetModel.computeGain(base: 50, level: level)
          totalExp += Double(gained)
          todayPomodoroCount += 1
          if isCrit { triggerCritical() }
          persist()
      }

      // MARK: - Pure static logic (테스트 가능)

      static func expNeededForLevel(_ level: Int) -> Double {
          floor(100 * pow(Double(level), 1.5))
      }

      static func totalExpAtLevelStart(_ level: Int) -> Double {
          guard level > 1 else { return 0 }
          return (1..<level).reduce(0.0) { $0 + expNeededForLevel($1) }
      }

      static func levelForExp(_ totalExp: Double) -> Int {
          var level = 1
          var accumulated = 0.0
          while true {
              let needed = expNeededForLevel(level)
              if accumulated + needed > totalExp { return level }
              accumulated += needed
              level += 1
          }
      }

      static func computeGain(base: Double, level: Int) -> (gained: Int, isCritical: Bool) {
          let jitter = Double.random(in: 0.8...1.2)
          let isCritical = Double.random(in: 0..<1) < 0.1
          let mult = isCritical ? 2.0 : 1.0
          let gained = Int((base * sqrt(Double(level)) * jitter * mult).rounded())
          return (gained, isCritical)
      }

      static func appearance(for level: Int) -> SlimeAppearance {
          switch level {
          case 1...2:
              return SlimeAppearance(bodyHex: "#7EC8E3", size: 24, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
          case 3...4:
              return SlimeAppearance(bodyHex: "#4FC3F7", size: 24, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
          case 5...7:
              return SlimeAppearance(bodyHex: "#66BB6A", size: 32, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
          case 8...9:
              return SlimeAppearance(bodyHex: "#FFEE58", size: 32, crownType: .none,          sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
          case 10...14:
              return SlimeAppearance(bodyHex: "#FFA726", size: 32, crownType: .bronze,        sparkleCount: 0,  hasHalo: false, isRainbow: false, isPearl: false)
          case 15...19:
              return SlimeAppearance(bodyHex: "#EF5350", size: 32, crownType: .bronze,        sparkleCount: 1,  hasHalo: false, isRainbow: false, isPearl: false)
          case 20...24:
              return SlimeAppearance(bodyHex: "#7E57C2", size: 40, crownType: .silver,        sparkleCount: 2,  hasHalo: false, isRainbow: false, isPearl: false)
          case 25...29:
              return SlimeAppearance(bodyHex: "#AB47BC", size: 40, crownType: .silver,        sparkleCount: 3,  hasHalo: false, isRainbow: false, isPearl: false)
          case 30...39:
              return SlimeAppearance(bodyHex: "#000000", size: 40, crownType: .gold,          sparkleCount: 4,  hasHalo: false, isRainbow: true,  isPearl: false)
          case 40...49:
              return SlimeAppearance(bodyHex: "#000000", size: 48, crownType: .gold,          sparkleCount: 6,  hasHalo: false, isRainbow: true,  isPearl: false)
          case 50...59:
              return SlimeAppearance(bodyHex: "#FFD700", size: 48, crownType: .diamond,       sparkleCount: 8,  hasHalo: false, isRainbow: false, isPearl: false)
          case 60...79:
              return SlimeAppearance(bodyHex: "#E0E0E0", size: 48, crownType: .diamond,       sparkleCount: 10, hasHalo: false, isRainbow: false, isPearl: false)
          case 80...99:
              return SlimeAppearance(bodyHex: "#F48FB1", size: 56, crownType: .diamond,       sparkleCount: 10, hasHalo: true,  isRainbow: false, isPearl: false)
          default:
              return SlimeAppearance(bodyHex: "#000000", size: 56, crownType: .constellation, sparkleCount: 10, hasHalo: true,  isRainbow: true,  isPearl: true)
          }
      }

      // MARK: - Private

      private func triggerCritical() {
          showCritical = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
              self?.showCritical = false
          }
      }

      private func persist() {
          UserDefaults.standard.set(totalExp,          forKey: "cruxpet.totalExp")
          UserDefaults.standard.set(todayCommitCount,  forKey: "cruxpet.commitCount")
          UserDefaults.standard.set(todayPomodoroCount,forKey: "cruxpet.pomodoroCount")
      }

      private func resetDailyCountsIfNeeded() {
          let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
          let stored = UserDefaults.standard.string(forKey: "cruxpet.todayDate") ?? ""
          if stored != today {
              todayCommitCount = 0
              todayPomodoroCount = 0
              UserDefaults.standard.set(String(today), forKey: "cruxpet.todayDate")
              persist()
          }
      }
  }
  ```

- [ ] **Step 4: 테스트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL|error:)" | head -15
  ```

  Expected: `Test Suite 'PetModelTests' passed`

- [ ] **Step 5: 커밋**

  ```bash
  git add CruxPet/PetModel.swift CruxPetTests/PetModelTests.swift
  git commit -m "feat: add PetModel with EXP/level math and slime appearance"
  ```

---

## Task 3: PomodoroTimer — 상태 머신

**Files:**
- Create: `CruxPet/PomodoroTimer.swift`
- Create: `CruxPetTests/PomodoroTimerTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

  `CruxPetTests/PomodoroTimerTests.swift`:

  ```swift
  import XCTest
  @testable import CruxPet

  final class PomodoroTimerTests: XCTestCase {

      func testInitialStateIsIdle() {
          let timer = PomodoroTimer()
          XCTAssertEqual(timer.state, .idle)
          XCTAssertEqual(timer.timeRemaining, 25 * 60)
      }

      func testStartTransitionsToRunning() {
          let timer = PomodoroTimer()
          timer.start()
          XCTAssertEqual(timer.state, .running)
      }

      func testPauseTransitionsToPaused() {
          let timer = PomodoroTimer()
          timer.start()
          timer.pause()
          XCTAssertEqual(timer.state, .paused)
      }

      func testResumeFromPausedTransitionsToRunning() {
          let timer = PomodoroTimer()
          timer.start()
          timer.pause()
          timer.resume()
          XCTAssertEqual(timer.state, .running)
      }

      func testResetFromRunningGoesBackToIdle() {
          let timer = PomodoroTimer()
          timer.start()
          timer.reset()
          XCTAssertEqual(timer.state, .idle)
          XCTAssertEqual(timer.timeRemaining, 25 * 60)
      }

      func testResetFromPausedGoesBackToIdle() {
          let timer = PomodoroTimer()
          timer.start()
          timer.pause()
          timer.reset()
          XCTAssertEqual(timer.state, .idle)
      }

      func testStartFromIdleIsNoOpIfAlreadyRunning() {
          let timer = PomodoroTimer()
          timer.start()
          timer.start()  // 두 번 start해도 running 유지
          XCTAssertEqual(timer.state, .running)
      }

      func testDisplayTime() {
          let timer = PomodoroTimer()
          // 25:00 표시
          XCTAssertEqual(timer.displayTime, "25:00")
      }
  }
  ```

- [ ] **Step 2: 테스트 실패 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|FAIL)" | head -5
  ```

  Expected: 컴파일 에러 (`PomodoroTimer` 없음)

- [ ] **Step 3: PomodoroTimer 구현**

  `CruxPet/PomodoroTimer.swift`:

  ```swift
  import Foundation
  import Observation

  enum PomodoroState: Equatable {
      case idle, running, paused, completed
  }

  @Observable
  class PomodoroTimer {
      private(set) var state: PomodoroState = .idle
      private(set) var timeRemaining: TimeInterval = 25 * 60

      var displayTime: String {
          let m = Int(timeRemaining) / 60
          let s = Int(timeRemaining) % 60
          return String(format: "%02d:%02d", m, s)
      }

      var onComplete: (() -> Void)?

      private var timer: Timer?

      func start() {
          guard state == .idle else { return }
          state = .running
          scheduleTimer()
      }

      func pause() {
          guard state == .running else { return }
          state = .paused
          timer?.invalidate()
      }

      func resume() {
          guard state == .paused else { return }
          state = .running
          scheduleTimer()
      }

      func reset() {
          timer?.invalidate()
          state = .idle
          timeRemaining = 25 * 60
      }

      private func scheduleTimer() {
          timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
              guard let self else { return }
              if self.timeRemaining > 0 {
                  self.timeRemaining -= 1
              } else {
                  self.timer?.invalidate()
                  self.state = .completed
                  self.onComplete?()
              }
          }
      }
  }
  ```

- [ ] **Step 4: 테스트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL)" | head -10
  ```

  Expected: `Test Suite 'PomodoroTimerTests' passed`

- [ ] **Step 5: 커밋**

  ```bash
  git add CruxPet/PomodoroTimer.swift CruxPetTests/PomodoroTimerTests.swift
  git commit -m "feat: add PomodoroTimer state machine"
  ```

---

## Task 4: EventWatcher — 파일 폴링·파싱

**Files:**
- Create: `CruxPet/EventWatcher.swift`
- Create: `CruxPetTests/EventWatcherTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

  `CruxPetTests/EventWatcherTests.swift`:

  ```swift
  import XCTest
  @testable import CruxPet

  final class EventWatcherTests: XCTestCase {

      func testParseEmptyLines() {
          let events = EventWatcher.parseLines("")
          XCTAssertTrue(events.isEmpty)
      }

      func testParseSingleCommitEvent() {
          let line = #"{"type":"commit","timestamp":1780634297}"#
          let events = EventWatcher.parseLines(line)
          XCTAssertEqual(events.count, 1)
          XCTAssertEqual(events[0].type, "commit")
          XCTAssertEqual(events[0].timestamp, 1780634297)
      }

      func testParseSinglePomodoroEvent() {
          let line = #"{"type":"pomodoro","timestamp":1780637000}"#
          let events = EventWatcher.parseLines(line)
          XCTAssertEqual(events.count, 1)
          XCTAssertEqual(events[0].type, "pomodoro")
      }

      func testParseMultipleLines() {
          let lines = """
          {"type":"commit","timestamp":100}
          {"type":"pomodoro","timestamp":200}
          {"type":"commit","timestamp":300}
          """
          let events = EventWatcher.parseLines(lines)
          XCTAssertEqual(events.count, 3)
          XCTAssertEqual(events[2].timestamp, 300)
      }

      func testSkipMalformedLines() {
          let lines = """
          {"type":"commit","timestamp":100}
          this is not json
          {"type":"pomodoro","timestamp":200}
          """
          let events = EventWatcher.parseLines(lines)
          XCTAssertEqual(events.count, 2)
      }

      func testFilterByLastProcessed() {
          let lines = """
          {"type":"commit","timestamp":100}
          {"type":"commit","timestamp":200}
          {"type":"commit","timestamp":300}
          """
          let all = EventWatcher.parseLines(lines)
          let fresh = EventWatcher.filterNew(events: all, after: 150)
          XCTAssertEqual(fresh.count, 2)
          XCTAssertEqual(fresh[0].timestamp, 200)
      }
  }
  ```

- [ ] **Step 2: 테스트 실패 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|FAIL)" | head -5
  ```

  Expected: 컴파일 에러 (`EventWatcher` 없음)

- [ ] **Step 3: EventWatcher 구현**

  `CruxPet/EventWatcher.swift`:

  ```swift
  import Foundation
  import Observation

  struct PetEvent {
      let type: String
      let timestamp: Double
  }

  @Observable
  class EventWatcher {
      private var pollTimer: Timer?
      private let eventsURL = URL(fileURLWithPath: NSHomeDirectory())
          .appendingPathComponent(".cruxpet/events.json")
      var onCommit: (() -> Void)?
      var onPomodoro: (() -> Void)?

      func start() {
          createEventsFileIfNeeded()
          pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
              self?.poll()
          }
      }

      func stop() {
          pollTimer?.invalidate()
      }

      func appendPomodoro() {
          let entry = "{\"type\":\"pomodoro\",\"timestamp\":\(Date().timeIntervalSince1970)}\n"
          if let data = entry.data(using: .utf8) {
              if let handle = try? FileHandle(forWritingTo: eventsURL) {
                  handle.seekToEndOfFile()
                  handle.write(data)
                  handle.closeFile()
              }
          }
      }

      // MARK: - Pure static logic (테스트 가능)

      static func parseLines(_ content: String) -> [PetEvent] {
          content.split(separator: "\n", omittingEmptySubsequences: true)
              .compactMap { line -> PetEvent? in
                  guard let data = line.data(using: .utf8),
                        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let type = obj["type"] as? String,
                        let ts = obj["timestamp"] as? Double else { return nil }
                  return PetEvent(type: type, timestamp: ts)
              }
      }

      static func filterNew(events: [PetEvent], after lastProcessed: Double) -> [PetEvent] {
          events.filter { $0.timestamp > lastProcessed }
      }

      // MARK: - Private

      private func poll() {
          guard let content = try? String(contentsOf: eventsURL, encoding: .utf8) else { return }
          let lastProcessed = UserDefaults.standard.double(forKey: "cruxpet.lastProcessed")
          let newEvents = EventWatcher.filterNew(
              events: EventWatcher.parseLines(content),
              after: lastProcessed
          )
          guard !newEvents.isEmpty else { return }

          let maxTs = newEvents.map(\.timestamp).max() ?? lastProcessed
          UserDefaults.standard.set(maxTs, forKey: "cruxpet.lastProcessed")

          for event in newEvents {
              switch event.type {
              case "commit":   onCommit?()
              case "pomodoro": onPomodoro?()
              default: break
              }
          }
      }

      private func createEventsFileIfNeeded() {
          let dir = eventsURL.deletingLastPathComponent()
          try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
          if !FileManager.default.fileExists(atPath: eventsURL.path) {
              FileManager.default.createFile(atPath: eventsURL.path, contents: nil)
          }
      }
  }
  ```

- [ ] **Step 4: 테스트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL)" | head -10
  ```

  Expected: `Test Suite 'EventWatcherTests' passed`

- [ ] **Step 5: 커밋**

  ```bash
  git add CruxPet/EventWatcher.swift CruxPetTests/EventWatcherTests.swift
  git commit -m "feat: add EventWatcher for polling events.json"
  ```

---

## Task 5: SlimeView — Canvas 도트 캐릭터

UI-only. 단위 테스트 없음 — Xcode Preview로 시각 확인.

**Files:**
- Create: `CruxPet/SlimeView.swift`

- [ ] **Step 1: SlimeView 구현**

  `CruxPet/SlimeView.swift`:

  ```swift
  import SwiftUI

  struct SlimeView: View {
      let appearance: SlimeAppearance
      var isPomodoroActive: Bool = false

      private var totalWidth: CGFloat { appearance.size + 32 }
      private var totalHeight: CGFloat { appearance.size + 40 }

      var body: some View {
          TimelineView(.animation) { timeline in
              Canvas { context, size in
                  let t = timeline.date.timeIntervalSinceReferenceDate
                  let bobY = sin(t * 2.5) * 3

                  // 후광 (Lv 80+)
                  if appearance.hasHalo {
                      drawHalo(context: &context, center: CGPoint(x: size.width/2, y: size.height/2 - 4 + bobY), radius: appearance.size * 0.7)
                  }

                  // 슬라임 몸통
                  let bodyRect = CGRect(
                      x: (size.width - appearance.size) / 2,
                      y: (size.height - appearance.size) / 2 + bobY,
                      width: appearance.size,
                      height: appearance.size * 0.85
                  )
                  drawBody(context: &context, rect: bodyRect, t: t)

                  // 눈
                  drawEyes(context: &context, bodyRect: bodyRect)

                  // 왕관
                  if appearance.crownType != .none {
                      drawCrown(context: &context, bodyRect: bodyRect)
                  }

                  // 반짝이
                  drawSparkles(context: &context, bodyRect: bodyRect, t: t, count: appearance.sparkleCount)
              }
              .frame(width: totalWidth, height: totalHeight)
          }
      }

      private func drawBody(context: inout GraphicsContext, rect: CGRect, t: Double) {
          // 포모도로 진행 중엔 🍅 오버레이
          if isPomodoroActive {
              var tomato = context.resolve(Text("🍅").font(.system(size: rect.width * 0.9)))
              context.draw(tomato, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
              return
          }
          let path = Path(roundedRect: rect, cornerRadius: rect.width * 0.4)
          if appearance.isRainbow {
              // 무지개: hue를 시간에 따라 순환
              let hue = (t * 0.2).truncatingRemainder(dividingBy: 1.0)
              context.fill(path, with: .color(Color(hue: hue, saturation: 0.8, brightness: 0.9)))
          } else {
              context.fill(path, with: .color(Color(hex: appearance.bodyHex)))
          }
          // 하단 그림자
          let shadowRect = CGRect(x: rect.minX + 2, y: rect.maxY - 6, width: rect.width - 4, height: 6)
          let shadowPath = Path(roundedRect: shadowRect, cornerRadius: 3)
          context.fill(shadowPath, with: .color(Color(hex: appearance.bodyHex).opacity(0.5)))

          // 펄 이펙트 (Lv 100+) — 반짝이는 하이라이트
          if appearance.isPearl {
              let highlightRect = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.1, width: rect.width * 0.25, height: rect.height * 0.2)
              let highlightPath = Path(ellipseIn: highlightRect)
              context.fill(highlightPath, with: .color(Color.white.opacity(0.6 + 0.3 * sin(t * 4))))
          }
      }

      private func drawEyes(context: inout GraphicsContext, bodyRect: CGRect) {
          let eyeY = bodyRect.minY + bodyRect.height * 0.35
          let eyeSize = bodyRect.width * 0.12
          let pupilSize = eyeSize * 0.6
          let spacing = bodyRect.width * 0.22

          for xOffset in [-spacing, spacing] {
              let cx = bodyRect.midX + xOffset
              // 흰자
              let white = Path(ellipseIn: CGRect(x: cx - eyeSize/2, y: eyeY - eyeSize/2, width: eyeSize, height: eyeSize))
              context.fill(white, with: .color(.white))
              // 눈동자
              let black = Path(ellipseIn: CGRect(x: cx - pupilSize/2, y: eyeY - pupilSize/2 + 1, width: pupilSize, height: pupilSize))
              context.fill(black, with: .color(.black))
          }
      }

      private func drawCrown(context: inout GraphicsContext, bodyRect: CGRect) {
          var text = context.resolve(Text(appearance.crownType.symbol).font(.system(size: bodyRect.width * 0.45)))
          let textSize = text.measure(in: CGSize(width: 100, height: 100))
          context.draw(text, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY - textSize.height * 0.3))
      }

      private func drawHalo(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
          let haloPath = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.3, width: radius * 2, height: radius * 0.6))
          context.stroke(haloPath, with: .color(Color.yellow.opacity(0.6)), lineWidth: 2)
      }

      private func drawSparkles(context: inout GraphicsContext, bodyRect: CGRect, t: Double, count: Int) {
          guard count > 0 else { return }
          let positions: [(Double, Double)] = [
              (-1.1, -0.6), (1.1, -0.4), (-0.9, 0.4), (1.0, 0.6),
              (-1.3, 0.0), (1.3, 0.1), (-0.7, -1.0), (0.8, -0.9),
              (-1.2, 0.9), (1.1, 1.0)
          ]
          for i in 0..<min(count, positions.count) {
              let (dx, dy) = positions[i]
              let x = bodyRect.midX + CGFloat(dx) * bodyRect.width * 0.65
              let y = bodyRect.midY + CGFloat(dy) * bodyRect.height * 0.65
              let phase = Double(i) * 0.7
              let alpha = 0.4 + 0.6 * abs(sin(t * 3 + phase))
              var sparkle = context.resolve(Text("✦").font(.system(size: 8)))
              context.draw(sparkle, at: CGPoint(x: x, y: y), anchor: .center)
          }
      }
  }

  // Color(hex:) 확장
  extension Color {
      init(hex: String) {
          let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
          var int: UInt64 = 0
          Scanner(string: hex).scanHexInt64(&int)
          let r = Double((int >> 16) & 0xFF) / 255
          let g = Double((int >> 8) & 0xFF) / 255
          let b = Double(int & 0xFF) / 255
          self.init(red: r, green: g, blue: b)
      }
  }

  #Preview {
      VStack(spacing: 8) {
          SlimeView(appearance: PetModel.appearance(for: 1))
          SlimeView(appearance: PetModel.appearance(for: 10))
          SlimeView(appearance: PetModel.appearance(for: 30))
          SlimeView(appearance: PetModel.appearance(for: 100))
      }
      .padding()
  }
  ```

- [ ] **Step 2: Xcode Preview에서 슬라임 4단계 시각 확인**

  Xcode에서 `SlimeView.swift`를 열고 Preview 패널에서 Lv1/10/30/100 슬라임이 정상 렌더링되는지 확인한다.

- [ ] **Step 3: 커밋**

  ```bash
  git add CruxPet/SlimeView.swift
  git commit -m "feat: add SlimeView with Canvas pixel-art rendering and animations"
  ```

---

## Task 6: ContentView — UI 전체 재작성

**Files:**
- Modify: `CruxPet/ContentView.swift` (전체 교체)

- [ ] **Step 1: ContentView 재작성**

  `CruxPet/ContentView.swift` 전체를 아래로 교체:

  ```swift
  import SwiftUI
  import Observation

  struct ContentView: View {
      @State private var pet = PetModel()
      @State private var pomodoro = PomodoroTimer()
      @State private var watcher = EventWatcher()

      var body: some View {
          VStack(spacing: 10) {
              characterSection
              expSection
              pomodoroSection
              activitySection
              Divider()
              Button("종료") { NSApplication.shared.terminate(nil) }
                  .buttonStyle(.plain)
                  .foregroundStyle(.secondary)
                  .font(.caption)
          }
          .padding(12)
          .frame(width: 200)
          .onAppear { setupWatcher() }
      }

      // MARK: - Sections

      private var characterSection: some View {
          ZStack {
              SlimeView(
                  appearance: pet.slimeAppearance,
                  isPomodoroActive: pomodoro.state == .running
              )
              if pet.showCritical {
                  Text("💥 CRITICAL!")
                      .font(.system(size: 11, weight: .bold))
                      .foregroundStyle(.orange)
                      .offset(y: -pet.slimeAppearance.size * 0.8)
                      .transition(.opacity)
              }
          }
          .animation(.easeInOut(duration: 0.2), value: pet.showCritical)
          Text("Lv. \(pet.level)")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.secondary)
      }

      private var expSection: some View {
          VStack(alignment: .leading, spacing: 2) {
              HStack {
                  Label("EXP", systemImage: "star.fill")
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                  Spacer()
                  Text("\(Int(pet.expInCurrentLevel)) / \(Int(pet.expNeededThisLevel))")
                      .font(.caption2.monospacedDigit())
                      .foregroundStyle(.secondary)
              }
              GeometryReader { geo in
                  ZStack(alignment: .leading) {
                      RoundedRectangle(cornerRadius: 4)
                          .fill(Color.secondary.opacity(0.2))
                      RoundedRectangle(cornerRadius: 4)
                          .fill(Color.blue.gradient)
                          .frame(width: geo.size.width * min(pet.expInCurrentLevel / max(pet.expNeededThisLevel, 1), 1))
                          .animation(.spring(duration: 0.4), value: pet.expInCurrentLevel)
                  }
              }
              .frame(height: 8)
              Text("Lv.\(pet.level + 1)까지 \(Int(pet.expNeededThisLevel - pet.expInCurrentLevel)) EXP")
                  .font(.caption2)
                  .foregroundStyle(.tertiary)
          }
      }

      private var pomodoroSection: some View {
          VStack(spacing: 6) {
              HStack {
                  Image(systemName: "timer")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  Text("포모도로")
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              Text(pomodoro.displayTime)
                  .font(.system(size: 24, weight: .bold, design: .monospaced))
                  .foregroundStyle(pomodoro.state == .running ? .primary : .secondary)
              HStack(spacing: 8) {
                  switch pomodoro.state {
                  case .idle:
                      Button("▶ 시작") { pomodoro.start() }
                          .buttonStyle(.borderedProminent)
                          .controlSize(.small)
                  case .running:
                      Button("⏸ 일시정지") { pomodoro.pause() }
                          .buttonStyle(.bordered)
                          .controlSize(.small)
                      Button("↺") { pomodoro.reset() }
                          .buttonStyle(.bordered)
                          .controlSize(.small)
                  case .paused:
                      Button("▶ 계속") { pomodoro.resume() }
                          .buttonStyle(.borderedProminent)
                          .controlSize(.small)
                      Button("↺") { pomodoro.reset() }
                          .buttonStyle(.bordered)
                          .controlSize(.small)
                  case .completed:
                      Button("↺ 다시") { pomodoro.reset() }
                          .buttonStyle(.borderedProminent)
                          .controlSize(.small)
                  }
              }
          }
          .padding(8)
          .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
      }

      private var activitySection: some View {
          HStack {
              Label("\(pet.todayCommitCount)회", systemImage: "externaldrive")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              Spacer()
              Label("\(pet.todayPomodoroCount)회", systemImage: "timer")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
          }
      }

      // MARK: - Setup

      private func setupWatcher() {
          watcher.onCommit = { pet.gainCommitExp() }
          // watcher.onPomodoro 는 의도적으로 미설정:
          // 포모도로 EXP는 onComplete에서 직접 지급하므로,
          // appendPomodoro()가 기록한 이벤트를 다시 읽어 이중 지급되는 것을 막는다.
          watcher.start()
          pomodoro.onComplete = {
              watcher.appendPomodoro()   // 기록 전용 — EXP는 아래에서만 지급
              pet.gainPomodoroExp()
              sendPomodoroNotification()
          }
      }

      private func sendPomodoroNotification() {
          let content = UNMutableNotificationContent()
          content.title = "포모도로 완료! 🍅"
          content.body = "EXP 획득! 슬라임이 기뻐해요."
          content.sound = .default
          let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
          UNUserNotificationCenter.current().add(request)
      }
  }

  #Preview {
      ContentView()
  }
  ```

- [ ] **Step 2: 필요한 import 추가 확인**

  `ContentView.swift` 상단에 `import UserNotifications` 추가:

  ```swift
  import SwiftUI
  import Observation
  import UserNotifications
  ```

- [ ] **Step 3: 빌드 확인**

  ```bash
  xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | tail -5
  ```

  Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: 커밋**

  ```bash
  git add CruxPet/ContentView.swift
  git commit -m "feat: rewrite ContentView with EXP bar, slime, and pomodoro UI"
  ```

---

## Task 7: CruxPetApp — 알림 권한 요청

**Files:**
- Modify: `CruxPet/CruxPetApp.swift`

- [ ] **Step 1: 알림 권한 요청 추가**

  `CruxPet/CruxPetApp.swift`:

  ```swift
  import SwiftUI
  import UserNotifications

  @main
  struct CruxPetApp: App {
      init() {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
      }

      var body: some Scene {
          MenuBarExtra("CruxPet", systemImage: "pawprint.fill") {
              ContentView()
          }
          .menuBarExtraStyle(.window)
      }
  }
  ```

- [ ] **Step 2: 빌드·실행 확인**

  ```bash
  xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | tail -3
  ```

  Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

  ```bash
  git add CruxPet/CruxPetApp.swift
  git commit -m "feat: request notification permission on launch"
  ```

---

## Task 8: install-hook.sh — Git Hook 설치 스크립트

**Files:**
- Create: `scripts/install-hook.sh`

- [ ] **Step 1: 스크립트 작성**

  ```bash
  mkdir -p /Users/jiny/dev/CruxPet/scripts
  ```

  `scripts/install-hook.sh`:

  ```sh
  #!/bin/sh
  set -e

  HOOKS_DIR="$HOME/.config/git/hooks"
  HOOK_FILE="$HOOKS_DIR/post-commit"
  EVENTS_DIR="$HOME/.cruxpet"
  EVENTS_FILE="$EVENTS_DIR/events.json"
  HOOK_LINE='echo "{\"type\":\"commit\",\"timestamp\":$(date +%s)}" >> "$HOME/.cruxpet/events.json"'

  # 디렉터리 생성
  mkdir -p "$HOOKS_DIR"
  mkdir -p "$EVENTS_DIR"
  touch "$EVENTS_FILE"

  # post-commit hook 파일 생성 또는 append
  if [ ! -f "$HOOK_FILE" ]; then
      printf '#!/bin/sh\n%s\n' "$HOOK_LINE" > "$HOOK_FILE"
  else
      if ! grep -qF "cruxpet" "$HOOK_FILE"; then
          printf '\n# CruxPet\n%s\n' "$HOOK_LINE" >> "$HOOK_FILE"
      fi
  fi
  chmod +x "$HOOK_FILE"

  # git global hooksPath 설정
  git config --global core.hooksPath "$HOOKS_DIR"

  echo "✅ CruxPet git hook 설치 완료"
  echo "   hook:  $HOOK_FILE"
  echo "   events: $EVENTS_FILE"
  ```

- [ ] **Step 2: 실행 권한 부여 및 동작 확인**

  ```bash
  chmod +x /Users/jiny/dev/CruxPet/scripts/install-hook.sh
  /Users/jiny/dev/CruxPet/scripts/install-hook.sh
  ```

  Expected 출력:
  ```
  ✅ CruxPet git hook 설치 완료
     hook:  /Users/.../.config/git/hooks/post-commit
     events: /Users/.../.cruxpet/events.json
  ```

- [ ] **Step 3: hook 동작 테스트**

  ```bash
  # 테스트용 빈 커밋 (hook이 실행되는지 확인)
  git commit --allow-empty -m "test: verify cruxpet hook"
  cat ~/.cruxpet/events.json | tail -3
  ```

  Expected: `{"type":"commit","timestamp":...}` 줄이 추가됨

- [ ] **Step 4: 커밋**

  ```bash
  git add scripts/install-hook.sh
  git commit -m "feat: add install-hook.sh for git post-commit integration"
  ```

---

## Task 9: 전체 통합 테스트

- [ ] **Step 1: 전체 테스트 스위트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite 'All|PASS|FAIL)" | head -5
  ```

  Expected: `Test Suite 'All tests' passed`

- [ ] **Step 2: 앱 실행 후 수동 검증**

  Xcode에서 앱을 실행하고 메뉴바 아이콘 클릭 후 확인:
  1. 슬라임 캐릭터가 위아래로 보빙 애니메이션
  2. EXP 바 표시 (Lv.1, 0/100)
  3. 포모도로 "▶ 시작" 버튼 동작
  4. `install-hook.sh` 실행 후 `git commit --allow-empty -m "test"` → 2초 내 EXP 증가 확인

- [ ] **Step 3: 최종 커밋**

  ```bash
  git add -A
  git commit -m "feat: complete productivity-linked pet with EXP, slime, pomodoro, and git hook"
  ```
