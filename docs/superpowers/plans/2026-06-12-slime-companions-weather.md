# 슬라임 친구 + 날씨/시간 반응 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 조건 달성 시 동료 슬라임 5종이 메인 슬라임 옆에 나타나고, 시간대/날씨에 따라 슬라임에 자동 이모지 액세서리가 오버레이된다.

**Architecture:** `CompanionModel`이 잠금 해제 조건을 추적하고 `CompanionSlimeView`가 미니 슬라임을 Canvas로 렌더링. `EnvironmentModel`이 CoreLocation + Open-Meteo API로 시간/날씨를 가져오고, `SlimeView`에 `environmentAccessories: [EnvironmentAccessory]`로 전달한다. 앱은 샌드박스 OFF(`com.apple.security.app-sandbox = false`)이므로 위치 엔타이틀먼트 불필요, Info.plist 사용 설명만 추가.

**Tech Stack:** Swift, SwiftUI, `@Observable`, CoreLocation, URLSession (Open-Meteo REST API, 무료/키 불필요)

---

## 파일 구조

| 파일 | 역할 |
|---|---|
| `CruxPet/CompanionModel.swift` | 신규 — 친구 데이터 + 잠금 해제 로직 |
| `CruxPet/CompanionSlimeView.swift` | 신규 — 미니 슬라임 Canvas 뷰 |
| `CruxPet/EnvironmentModel.swift` | 신규 — 시간/날씨 상태 + CoreLocation + API |
| `CruxPet/SlimeView.swift` | 수정 — `environmentAccessories` 파라미터 추가 |
| `CruxPet/ContentView.swift` | 수정 — companion 행 + environment 연결 |
| `CruxPet/CruxPetApp.swift` | 수정 — EnvironmentModel 생성 및 주입 |
| `CruxPet/Info.plist` | 수정 — `NSLocationWhenInUseUsageDescription` 추가 |
| `CruxPetTests/CompanionModelTests.swift` | 신규 — 잠금 해제 조건 유닛 테스트 |
| `CruxPetTests/EnvironmentModelTests.swift` | 신규 — 시간대/날씨 액세서리 유닛 테스트 |

---

## Task 1: CompanionModel

**Files:**
- Create: `CruxPet/CompanionModel.swift`
- Create: `CruxPetTests/CompanionModelTests.swift`

- [ ] **Step 1: 실패하는 테스트 작성**

`CruxPetTests/CompanionModelTests.swift`:
```swift
import XCTest
@testable import CruxPet

final class CompanionModelTests: XCTestCase {

    func testBabyUnlocksAtLevel10() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 10, streakDays: 0, achievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("baby"))
    }

    func testBabyDoesNotUnlockBeforeLevel10() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 9, streakDays: 0, achievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertFalse(result.contains("baby"))
    }

    func testFlameUnlocksAtStreak7() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 7, achievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("flame"))
    }

    func testStarUnlocksAt5Achievements() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, achievementCount: 5,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("star"))
    }

    func testNightUnlocksWithNightOwlCommit() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, achievementCount: 0,
            hasNightOwlCommit: true, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("night"))
    }

    func testPomoUnlocksAt20Pomodoros() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, achievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 20,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.contains("pomo"))
    }

    func testAlreadyUnlockedNotReturned() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 10, streakDays: 0, achievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: ["baby"]
        )
        XCTAssertFalse(result.contains("baby"))
    }

    func testNoConditionsMetReturnsEmpty() {
        let result = CompanionModel.newlyUnlockedIDs(
            level: 1, streakDays: 0, achievementCount: 0,
            hasNightOwlCommit: false, totalPomodoroCount: 0,
            alreadyUnlocked: []
        )
        XCTAssertTrue(result.isEmpty)
    }
}
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -only-testing:CruxPetTests/CompanionModelTests 2>&1 | grep -E "error:|FAIL|PASS"
```
Expected: `error: cannot find type 'CompanionModel'`

- [ ] **Step 3: CompanionModel 구현**

`CruxPet/CompanionModel.swift`:
```swift
import Foundation
import Observation

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

    var unlockedCompanions: [Companion] {
        CompanionModel.all.filter { unlockedIDs.contains($0.id) }
    }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "cruxpet.companions.unlocked") ?? []
        unlockedIDs = Set(saved)
    }

    /// 새로 달성된 친구를 반환하고 UserDefaults에 저장
    @discardableResult
    func checkUnlocks(level: Int, streakDays: Int, achievementCount: Int,
                      hasNightOwlCommit: Bool, totalPomodoroCount: Int) -> [Companion] {
        let newIDs = CompanionModel.newlyUnlockedIDs(
            level: level, streakDays: streakDays, achievementCount: achievementCount,
            hasNightOwlCommit: hasNightOwlCommit, totalPomodoroCount: totalPomodoroCount,
            alreadyUnlocked: unlockedIDs
        )
        guard !newIDs.isEmpty else { return [] }
        unlockedIDs.formUnion(newIDs)
        UserDefaults.standard.set(Array(unlockedIDs), forKey: "cruxpet.companions.unlocked")
        return CompanionModel.all.filter { newIDs.contains($0.id) }
    }

    static func newlyUnlockedIDs(
        level: Int, streakDays: Int, achievementCount: Int,
        hasNightOwlCommit: Bool, totalPomodoroCount: Int,
        alreadyUnlocked: Set<String>
    ) -> Set<String> {
        var result: Set<String> = []
        if level >= 10,              !alreadyUnlocked.contains("baby")  { result.insert("baby") }
        if streakDays >= 7,          !alreadyUnlocked.contains("flame") { result.insert("flame") }
        if achievementCount >= 5,    !alreadyUnlocked.contains("star")  { result.insert("star") }
        if hasNightOwlCommit,        !alreadyUnlocked.contains("night") { result.insert("night") }
        if totalPomodoroCount >= 20, !alreadyUnlocked.contains("pomo")  { result.insert("pomo") }
        return result
    }
}
```

- [ ] **Step 4: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -only-testing:CruxPetTests/CompanionModelTests 2>&1 | grep -E "error:|FAIL|passed"
```
Expected: `Test Suite 'CompanionModelTests' passed`

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/CompanionModel.swift CruxPetTests/CompanionModelTests.swift
git commit -m "feat: add CompanionModel with unlock logic and tests"
```

---

## Task 2: CompanionSlimeView

**Files:**
- Create: `CruxPet/CompanionSlimeView.swift`

- [ ] **Step 1: CompanionSlimeView 구현**

`CruxPet/CompanionSlimeView.swift`:
```swift
import SwiftUI

struct CompanionSlimeView: View {
    let companion: Companion

    private let bodySize: CGFloat = 14
    private var canvasSize: CGFloat { bodySize + 20 }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let bobY = CGFloat(sin(t * 1.1)) * 1.5
                let bodyRect = CGRect(
                    x: (size.width - bodySize) / 2,
                    y: (size.height - bodySize) / 2 + bobY + 3,
                    width: bodySize,
                    height: bodySize * 0.85
                )

                // 그림자
                let shadowRect = CGRect(
                    x: bodyRect.midX - bodyRect.width * 0.4,
                    y: bodyRect.maxY - 1,
                    width: bodyRect.width * 0.8,
                    height: bodyRect.height * 0.12
                )
                var shadowCtx = context; shadowCtx.opacity = 0.12
                shadowCtx.fill(Path(ellipseIn: shadowRect), with: .color(.black))

                // 몸통
                let color = Color(hex: companion.bodyHex)
                context.fill(Path(ellipseIn: bodyRect), with: .color(color))

                // 외곽선
                var outCtx = context; outCtx.opacity = 0.2
                outCtx.stroke(Path(ellipseIn: bodyRect), with: .color(color), lineWidth: bodyRect.width * 0.08)

                // 하이라이트
                let hlRect = CGRect(
                    x: bodyRect.minX + bodyRect.width * 0.15,
                    y: bodyRect.minY + bodyRect.height * 0.08,
                    width: bodyRect.width * 0.3,
                    height: bodyRect.height * 0.22
                )
                var hlCtx = context; hlCtx.opacity = 0.75
                hlCtx.fill(Path(ellipseIn: hlRect), with: .radialGradient(
                    Gradient(colors: [.white, .clear]),
                    center: CGPoint(x: hlRect.midX, y: hlRect.midY),
                    startRadius: 0, endRadius: max(hlRect.width, hlRect.height) * 0.7
                ))

                // 눈 (작은 점 두 개)
                let eyeY = bodyRect.minY + bodyRect.height * 0.40
                let eyeSize: CGFloat = bodyRect.width * 0.13
                for xOff: CGFloat in [-bodyRect.width * 0.20, bodyRect.width * 0.20] {
                    let eyeRect = CGRect(
                        x: bodyRect.midX + xOff - eyeSize / 2,
                        y: eyeY - eyeSize / 2,
                        width: eyeSize, height: eyeSize
                    )
                    context.fill(Path(ellipseIn: eyeRect), with: .color(.black.opacity(0.75)))
                }

                // 이모지 (슬라임 위)
                let resolved = context.resolve(
                    Text(companion.emoji).font(.system(size: 8))
                )
                context.draw(resolved,
                             at: CGPoint(x: size.width / 2, y: bodyRect.minY - 1),
                             anchor: .bottom)
            }
            .frame(width: canvasSize, height: canvasSize)
        }
    }
}

#Preview {
    HStack {
        ForEach(CompanionModel.all) { c in
            CompanionSlimeView(companion: c)
        }
    }
    .padding()
}
```

- [ ] **Step 2: Preview로 시각 확인**

Xcode에서 `CompanionSlimeView.swift` 열고 Canvas Preview 실행. 5종 미니 슬라임이 이모지와 함께 표시되는지 확인.

- [ ] **Step 3: 커밋**

```bash
git add CruxPet/CompanionSlimeView.swift
git commit -m "feat: add CompanionSlimeView mini canvas renderer"
```

---

## Task 3: ContentView — companion row 통합

**Files:**
- Modify: `CruxPet/ContentView.swift`

현재 `ContentView.swift`의 `characterSection` (line ~294)에 companion row를 추가하고, 잠금 해제 감지 onChange를 연결한다.

- [ ] **Step 1: State 추가 및 companionRow 뷰 작성**

`ContentView.swift`에서 `@State private var activityDays` 아래에 추가:
```swift
@State private var companionModel = CompanionModel()
```

`characterSection` 내 `streakCalendar` 아래 (`.animation` modifier 전)에 companion row 추가:
```swift
if !companionModel.unlockedCompanions.isEmpty {
    companionRow
        .transition(.scale.combined(with: .opacity))
}
```

`streakCalendar` property 아래에 추가:
```swift
private var companionRow: some View {
    HStack(spacing: 8) {
        ForEach(companionModel.unlockedCompanions) { companion in
            CompanionSlimeView(companion: companion)
        }
    }
}
```

- [ ] **Step 2: 잠금 해제 체크 연결**

`setupWatcher()` 함수 아래에 helper 추가:
```swift
private func checkCompanionUnlocks() {
    let newOnes = companionModel.checkUnlocks(
        level: pet.level,
        streakDays: pet.streakDays,
        achievementCount: achievementModel.claimedCount,
        hasNightOwlCommit: pet.hasNightOwlCommit,
        totalPomodoroCount: pet.totalPomodoroCount
    )
    for companion in newOnes {
        showToast(ToastData(emoji: "🐾", title: "\(companion.name) 등장!",
                            subtitle: "새 친구를 얻었어요"))
    }
}
```

`.onAppear` 블록의 `setupWatcher()` 호출 뒤에 추가:
```swift
checkCompanionUnlocks()
```

기존 `onChange(of: pet.level)` 블록 끝에 추가:
```swift
checkCompanionUnlocks()
```

기존 `onChange(of: pet.streakDays)` 블록 끝에 추가:
```swift
checkCompanionUnlocks()
```

기존 `onChange(of: pet.totalPomodoroCount)` onChange가 없으므로 `onChange(of: pet.totalPomodoroCount)` 추가:
```swift
.onChange(of: pet.totalPomodoroCount) { _, _ in
    checkCompanionUnlocks()
}
```

기존 `onChange(of: pet.hasNightOwlCommit)` onChange 추가:
```swift
.onChange(of: pet.hasNightOwlCommit) { _, val in
    if val { checkCompanionUnlocks() }
}
```

기존 achievement onChange (`onChange(of: pet.questClearCount)`) 끝에 추가:
```swift
checkCompanionUnlocks()
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -scheme CruxPet -configuration Debug -quiet 2>&1 | grep "error:"
```
Expected: 출력 없음 (에러 없음)

- [ ] **Step 4: 커밋**

```bash
git add CruxPet/ContentView.swift
git commit -m "feat: display companion slimes in character section"
```

---

## Task 4: EnvironmentModel — 순수 로직

**Files:**
- Create: `CruxPet/EnvironmentModel.swift` (순수 로직 부분)
- Create: `CruxPetTests/EnvironmentModelTests.swift`

- [ ] **Step 1: 실패하는 테스트 작성**

`CruxPetTests/EnvironmentModelTests.swift`:
```swift
import XCTest
@testable import CruxPet

final class EnvironmentModelTests: XCTestCase {

    // MARK: - TimeOfDay

    func testTimeOfDay_dawn() {
        XCTAssertEqual(TimeOfDay.from(hour: 0), .dawn)
        XCTAssertEqual(TimeOfDay.from(hour: 3), .dawn)
        XCTAssertEqual(TimeOfDay.from(hour: 4), .dawn)
    }

    func testTimeOfDay_morning() {
        XCTAssertEqual(TimeOfDay.from(hour: 5), .morning)
        XCTAssertEqual(TimeOfDay.from(hour: 8), .morning)
    }

    func testTimeOfDay_daytime() {
        XCTAssertEqual(TimeOfDay.from(hour: 9), .daytime)
        XCTAssertEqual(TimeOfDay.from(hour: 17), .daytime)
    }

    func testTimeOfDay_evening() {
        XCTAssertEqual(TimeOfDay.from(hour: 18), .evening)
        XCTAssertEqual(TimeOfDay.from(hour: 21), .evening)
    }

    func testTimeOfDay_night() {
        XCTAssertEqual(TimeOfDay.from(hour: 22), .night)
        XCTAssertEqual(TimeOfDay.from(hour: 23), .night)
    }

    // MARK: - timeAccessory

    func testTimeAccessory_dawn_returnsMoon() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .dawn), .moon)
    }

    func testTimeAccessory_morning_returnsSun() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .morning), .sun)
    }

    func testTimeAccessory_daytime_returnsNil() {
        XCTAssertNil(EnvironmentModel.timeAccessory(for: .daytime))
    }

    func testTimeAccessory_evening_returnsSunset() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .evening), .sunset)
    }

    func testTimeAccessory_night_returnsStar() {
        XCTAssertEqual(EnvironmentModel.timeAccessory(for: .night), .star)
    }

    // MARK: - weatherAccessory

    func testWeatherAccessory_clear_returnsSunglasses() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 0, temp: 20), .sunglasses)
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 1, temp: 20), .sunglasses)
    }

    func testWeatherAccessory_cloudy_returnsNil() {
        XCTAssertNil(EnvironmentModel.weatherAccessory(wmoCode: 2, temp: 15))
        XCTAssertNil(EnvironmentModel.weatherAccessory(wmoCode: 3, temp: 15))
    }

    func testWeatherAccessory_rain_returnsUmbrella() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 51, temp: 10), .umbrella)
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 80, temp: 10), .umbrella)
    }

    func testWeatherAccessory_snow_returnsScarf() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 71, temp: -2), .scarf)
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 85, temp: 0), .scarf)
    }

    func testWeatherAccessory_freezing_returnsCoat() {
        XCTAssertEqual(EnvironmentModel.weatherAccessory(wmoCode: 0, temp: -1), .coat)
    }

    func testWeatherAccessory_nil_wmo_returnsNil() {
        XCTAssertNil(EnvironmentModel.weatherAccessory(wmoCode: nil, temp: nil))
    }
}
```

- [ ] **Step 2: 테스트 실행 — FAIL 확인**

```bash
xcodebuild test -scheme CruxPet -only-testing:CruxPetTests/EnvironmentModelTests 2>&1 | grep -E "error:|FAIL|PASS"
```
Expected: `error: cannot find type 'TimeOfDay'`

- [ ] **Step 3: 순수 로직 구현 (네트워크/위치 제외)**

`CruxPet/EnvironmentModel.swift`:
```swift
import CoreLocation
import Foundation
import Observation

enum TimeOfDay: Equatable {
    case dawn, morning, daytime, evening, night

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 0...4:  return .dawn
        case 5...8:  return .morning
        case 9...17: return .daytime
        case 18...21: return .evening
        default:     return .night
        }
    }

    static func current() -> TimeOfDay {
        from(hour: Calendar.current.component(.hour, from: Date()))
    }
}

enum EnvironmentAccessory: String, Equatable {
    case moon, sun, sunset, star, sunglasses, umbrella, scarf, coat

    var emoji: String {
        switch self {
        case .moon:       return "🌙"
        case .sun:        return "🌤"
        case .sunset:     return "🌇"
        case .star:       return "⭐"
        case .sunglasses: return "🕶️"
        case .umbrella:   return "☂️"
        case .scarf:      return "🧣"
        case .coat:       return "🧥"
        }
    }
}

@Observable
@MainActor
class EnvironmentModel: NSObject, CLLocationManagerDelegate {
    private(set) var currentAccessories: [EnvironmentAccessory] = []

    private let locationManager = CLLocationManager()
    private var cachedWMOCode: Int? = nil
    private var cachedTemp: Double? = nil
    private var timers: [Timer] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        restoreCache()
    }

    // MARK: - Pure static logic (테스트 가능)

    nonisolated static func timeAccessory(for time: TimeOfDay) -> EnvironmentAccessory? {
        switch time {
        case .dawn:    return .moon
        case .morning: return .sun
        case .evening: return .sunset
        case .night:   return .star
        case .daytime: return nil
        }
    }

    nonisolated static func weatherAccessory(wmoCode: Int?, temp: Double?) -> EnvironmentAccessory? {
        guard let wmo = wmoCode else { return nil }
        if let t = temp, t < 0 { return .coat }
        switch wmo {
        case 0...1:              return .sunglasses
        case 51...67, 80...82:   return .umbrella
        case 71...77, 85...86:   return .scarf
        default:                 return nil
        }
    }

    // MARK: - Internal update

    func updateAccessories() {
        var result: [EnvironmentAccessory] = []
        if let ta = EnvironmentModel.timeAccessory(for: TimeOfDay.current()) {
            result.append(ta)
        }
        if let wa = EnvironmentModel.weatherAccessory(wmoCode: cachedWMOCode, temp: cachedTemp) {
            result.append(wa)
        }
        currentAccessories = result
    }

    // MARK: - Cache persistence

    private func restoreCache() {
        let lastFetch = UserDefaults.standard.double(forKey: "cruxpet.env.lastFetch")
        guard lastFetch > 0, Date().timeIntervalSince1970 - lastFetch < 30 * 60 else { return }
        let wmo = UserDefaults.standard.integer(forKey: "cruxpet.env.wmoCode")
        let temp = UserDefaults.standard.double(forKey: "cruxpet.env.temp")
        if wmo > 0 {
            cachedWMOCode = wmo
            cachedTemp = temp
        }
        updateAccessories()
    }

    private func saveCache(wmo: Int, temp: Double) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "cruxpet.env.lastFetch")
        UserDefaults.standard.set(wmo, forKey: "cruxpet.env.wmoCode")
        UserDefaults.standard.set(temp, forKey: "cruxpet.env.temp")
    }

    // MARK: - Stubs (Task 5에서 구현)

    func startUpdating() {
        updateAccessories()
        timers.append(Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateAccessories() }
        })
    }

    // CLLocationManagerDelegate stubs
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {}
}
```

- [ ] **Step 4: 테스트 실행 — PASS 확인**

```bash
xcodebuild test -scheme CruxPet -only-testing:CruxPetTests/EnvironmentModelTests 2>&1 | grep -E "error:|FAIL|passed"
```
Expected: `Test Suite 'EnvironmentModelTests' passed`

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/EnvironmentModel.swift CruxPetTests/EnvironmentModelTests.swift
git commit -m "feat: add EnvironmentModel pure logic with TimeOfDay and accessory resolution"
```

---

## Task 5: EnvironmentModel — 위치 + 날씨 API

**Files:**
- Modify: `CruxPet/EnvironmentModel.swift`
- Modify: `CruxPet/Info.plist`

- [ ] **Step 1: Info.plist에 위치 사용 설명 추가**

`CruxPet/Info.plist`의 `<dict>` 안에 추가:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>현재 날씨에 따라 슬라임이 달라져요.</string>
```

- [ ] **Step 2: EnvironmentModel에 위치/날씨 구현**

`CruxPet/EnvironmentModel.swift`의 `startUpdating()` 함수를 아래로 교체하고, delegate 메서드 구현 교체:

`startUpdating()` 함수 교체:
```swift
func startUpdating() {
    updateAccessories()
    requestLocationUpdate()
    // 60초마다 시간대 갱신
    timers.append(Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
        Task { @MainActor [weak self] in self?.updateAccessories() }
    })
    // 30분마다 날씨 갱신
    timers.append(Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
        Task { @MainActor [weak self] in self?.requestLocationUpdate() }
    })
}

private func requestLocationUpdate() {
    let lastFetch = UserDefaults.standard.double(forKey: "cruxpet.env.lastFetch")
    let elapsed = Date().timeIntervalSince1970 - lastFetch
    guard elapsed > 30 * 60 else { return }  // 캐시 유효 시 스킵

    switch locationManager.authorizationStatus {
    case .notDetermined:
        locationManager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
        locationManager.requestLocation()
    default:
        break
    }
}
```

delegate 스텁 3개를 아래로 교체:
```swift
nonisolated func locationManager(_ manager: CLLocationManager,
                                  didUpdateLocations locations: [CLLocation]) {
    guard let loc = locations.last else { return }
    manager.stopUpdatingLocation()
    let lat = loc.coordinate.latitude
    let lon = loc.coordinate.longitude
    Task { @MainActor [weak self] in
        await self?.fetchWeather(lat: lat, lon: lon)
    }
}

nonisolated func locationManager(_ manager: CLLocationManager,
                                  didFailWithError error: Error) {
    // 위치 실패 시 날씨 반응 없이 시간 반응만 유지 (currentAccessories는 그대로)
}

nonisolated func locationManager(_ manager: CLLocationManager,
                                  didChangeAuthorization status: CLAuthorizationStatus) {
    if status == .authorizedWhenInUse || status == .authorizedAlways {
        Task { @MainActor [weak self] in self?.requestLocationUpdate() }
    }
}

private func fetchWeather(lat: Double, lon: Double) async {
    let urlString = "https://api.open-meteo.com/v1/forecast"
        + "?latitude=\(lat)&longitude=\(lon)"
        + "&current=weathercode,temperature_2m"
    guard let url = URL(string: urlString),
          let (data, _) = try? await URLSession.shared.data(from: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let current = json["current"] as? [String: Any],
          let wmo = current["weathercode"] as? Int,
          let temp = current["temperature_2m"] as? Double
    else { return }

    cachedWMOCode = wmo
    cachedTemp = temp
    saveCache(wmo: wmo, temp: temp)
    updateAccessories()
}
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -scheme CruxPet -configuration Debug -quiet 2>&1 | grep "error:"
```
Expected: 출력 없음

- [ ] **Step 4: 커밋**

```bash
git add CruxPet/EnvironmentModel.swift CruxPet/Info.plist
git commit -m "feat: add CoreLocation and Open-Meteo weather fetching to EnvironmentModel"
```

---

## Task 6: SlimeView — environment accessories 렌더링

**Files:**
- Modify: `CruxPet/SlimeView.swift`

현재 `SlimeView`는 `appearance`, `isPomodoroActive`, `accessories`, `isWandering`, `emotion` 파라미터를 가진다. `environmentAccessories` 파라미터를 추가하고 Canvas 끝에 드로잉 함수를 호출한다.

- [ ] **Step 1: 파라미터 추가**

`SlimeView.swift` 상단 파라미터 선언부 (`var emotion: EmotionState = .normal` 다음 줄)에 추가:
```swift
var environmentAccessories: [EnvironmentAccessory] = []
```

- [ ] **Step 2: Canvas 드로잉 호출 추가**

`drawSlotAccessories(context: &context, bodyRect: bodyRect)` 호출 바로 다음 줄에 추가:
```swift
drawEnvironmentAccessories(context: &context, bodyRect: bodyRect)
```

- [ ] **Step 3: drawEnvironmentAccessories 함수 추가**

`SlimeView.swift`의 `// MARK: - Accessories` 섹션 끝 (`}` 닫기 직전, `extension Color` 앞)에 추가:

```swift
private func drawEnvironmentAccessories(context: inout GraphicsContext, bodyRect: CGRect) {
    for accessory in environmentAccessories {
        let point: CGPoint
        let fontSize: CGFloat
        switch accessory {
        case .moon:
            point = CGPoint(x: bodyRect.minX - bodyRect.width * 0.15,
                            y: bodyRect.minY + bodyRect.height * 0.05)
            fontSize = bodyRect.width * 0.38
        case .sun:
            point = CGPoint(x: bodyRect.maxX + bodyRect.width * 0.12,
                            y: bodyRect.minY)
            fontSize = bodyRect.width * 0.38
        case .sunset:
            point = CGPoint(x: bodyRect.midX,
                            y: bodyRect.minY - bodyRect.height * 0.45)
            fontSize = bodyRect.width * 0.38
        case .star:
            point = CGPoint(x: bodyRect.minX - bodyRect.width * 0.15,
                            y: bodyRect.minY + bodyRect.height * 0.05)
            fontSize = bodyRect.width * 0.32
        case .sunglasses:
            point = CGPoint(x: bodyRect.midX,
                            y: bodyRect.minY + bodyRect.height * 0.38)
            fontSize = bodyRect.width * 0.38
        case .umbrella:
            point = CGPoint(x: bodyRect.midX - bodyRect.width * 0.1,
                            y: bodyRect.minY - bodyRect.height * 0.55)
            fontSize = bodyRect.width * 0.42
        case .scarf:
            point = CGPoint(x: bodyRect.maxX + bodyRect.width * 0.08,
                            y: bodyRect.minY + bodyRect.height * 0.55)
            fontSize = bodyRect.width * 0.30
        case .coat:
            point = CGPoint(x: bodyRect.maxX + bodyRect.width * 0.08,
                            y: bodyRect.midY)
            fontSize = bodyRect.width * 0.30
        }
        let resolved = context.resolve(Text(accessory.emoji).font(.system(size: fontSize)))
        context.draw(resolved, at: point, anchor: .center)
    }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
xcodebuild -scheme CruxPet -configuration Debug -quiet 2>&1 | grep "error:"
```
Expected: 출력 없음

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/SlimeView.swift
git commit -m "feat: add environmentAccessories rendering to SlimeView"
```

---

## Task 7: EnvironmentModel 연결 (CruxPetApp + ContentView)

**Files:**
- Modify: `CruxPet/CruxPetApp.swift`
- Modify: `CruxPet/ContentView.swift`

- [ ] **Step 1: CruxPetApp에 EnvironmentModel 추가**

`CruxPetApp.swift`의 `@State private var watcher = EventWatcher()` 다음 줄에 추가:
```swift
@State private var environment = EnvironmentModel()
```

`body`의 `.environment(watcher)` 다음 줄에 추가:
```swift
.environment(environment)
```

`startServices()` 내 `rightClickHandler.install()` 다음 줄에 추가:
```swift
environment.startUpdating()
```

- [ ] **Step 2: ContentView에서 environment 수신**

`ContentView.swift`의 `@Environment(EventWatcher.self) private var watcher` 다음 줄에 추가:
```swift
@Environment(EnvironmentModel.self) private var environment
```

- [ ] **Step 3: SlimeView에 environmentAccessories 전달**

`ContentView.swift`의 `characterSection` 내 `SlimeView(...)` 호출에 파라미터 추가:
```swift
SlimeView(
    appearance: pet.slimeAppearance.applying(customization),
    isPomodoroActive: pomodoro.state == .running,
    accessories: customization.accessories,
    isWandering: pomodoro.state != .running,
    emotion: pomodoro.state == .running ? .normal : pet.emotion,
    environmentAccessories: environment.currentAccessories  // ← 추가
)
```

- [ ] **Step 4: 빌드 및 전체 테스트 확인**

```bash
xcodebuild test -scheme CruxPet 2>&1 | grep -E "error:|FAIL|passed"
```
Expected: `Test Suite 'All tests' passed`

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/CruxPetApp.swift CruxPet/ContentView.swift
git commit -m "feat: wire up EnvironmentModel to SlimeView for weather/time accessories"
```

---

## Task 8: 릴리즈

- [ ] **Step 1: 릴리즈**

```bash
bash scripts/release.sh 1.0.24
```

- [ ] **Step 2: 결과 확인**

- 친구 슬라임: Lv.10 이상이면 아기 슬라임 등장, Night Owl 커밋 있으면 야왕 슬라임 등장
- 날씨 반응: 새벽 실행 시 🌙, 맑은 날 낮에는 🕶️
- 위치 권한 요청 다이얼로그 표시 확인
