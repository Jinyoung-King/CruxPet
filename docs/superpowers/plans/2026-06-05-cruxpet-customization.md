# CruxPet 커스터마이징 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 슬라임 이름·색상·악세서리·포모도로 시간을 ⚙️ 설정 화면에서 변경하고 UserDefaults에 저장한다.

**Architecture:** `PetCustomization` 모델이 UserDefaults에 JSON으로 저장되며, `ContentView`가 이를 로드해 `SlimeView`의 appearance 적용과 포모도로 duration 설정에 사용한다. 설정 화면은 `CustomizeView`로 분리, draft 패턴으로 저장/취소를 구현한다.

**Tech Stack:** Swift 5.9+, SwiftUI, @Observable, XCTest, Foundation (JSONEncoder/Decoder)

---

## File Map

| 파일 | 역할 |
|------|------|
| `CruxPet/PetCustomization.swift` | 신규 — Codable 모델 + save/load |
| `CruxPet/CustomizeView.swift` | 신규 — 설정 UI (draft 패턴) |
| `CruxPet/PetModel.swift` | 수정 — SlimeAppearance.applying() 추가 |
| `CruxPet/SlimeView.swift` | 수정 — accessory: String 파라미터 추가 |
| `CruxPet/PomodoroTimer.swift` | 수정 — duration 프로퍼티 + setDuration() |
| `CruxPet/ContentView.swift` | 수정 — customization 상태, ⚙️ 버튼, 이름 표시 |
| `CruxPetTests/PetCustomizationTests.swift` | 신규 — 모델 단위 테스트 |
| `CruxPetTests/PomodoroTimerTests.swift` | 수정 — duration 테스트 추가 |

---

## Task 1: PetCustomization 모델

**Files:**
- Create: `CruxPet/PetCustomization.swift`
- Create: `CruxPetTests/PetCustomizationTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

  `CruxPetTests/PetCustomizationTests.swift`:

  ```swift
  import XCTest
  @testable import CruxPet

  final class PetCustomizationTests: XCTestCase {

      override func tearDown() {
          UserDefaults.standard.removeObject(forKey: "cruxpet.customization")
      }

      func testDefaultValues() {
          let c = PetCustomization()
          XCTAssertEqual(c.name, "Crux")
          XCTAssertFalse(c.useCustomColor)
          XCTAssertEqual(c.customColorHex, "#7EC8E3")
          XCTAssertEqual(c.accessory, "")
          XCTAssertEqual(c.pomodoroMinutes, 25)
      }

      func testSaveAndLoad() {
          var c = PetCustomization()
          c.name = "TestSlime"
          c.useCustomColor = true
          c.customColorHex = "#EF5350"
          c.accessory = "🎩"
          c.pomodoroMinutes = 50
          c.save()

          let loaded = PetCustomization.load()
          XCTAssertEqual(loaded.name, "TestSlime")
          XCTAssertTrue(loaded.useCustomColor)
          XCTAssertEqual(loaded.customColorHex, "#EF5350")
          XCTAssertEqual(loaded.accessory, "🎩")
          XCTAssertEqual(loaded.pomodoroMinutes, 50)
      }

      func testLoadReturnsDefaultWhenNotSaved() {
          let c = PetCustomization.load()
          XCTAssertEqual(c.name, "Crux")
          XCTAssertEqual(c.pomodoroMinutes, 25)
      }
  }
  ```

- [ ] **Step 2: 테스트 실패 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|FAIL)" | head -5
  ```

  Expected: 컴파일 에러 (`PetCustomization` 없음)

- [ ] **Step 3: PetCustomization 구현**

  `CruxPet/PetCustomization.swift`:

  ```swift
  import Foundation

  struct PetCustomization: Codable {
      var name: String = "Crux"
      var useCustomColor: Bool = false
      var customColorHex: String = "#7EC8E3"
      var accessory: String = ""
      var pomodoroMinutes: Int = 25

      static let presetColors: [String] = [
          "#7EC8E3", "#EF5350", "#66BB6A",
          "#FFA726", "#AB47BC", "#FFD700", "#F48FB1"
      ]

      static let accessories: [String] = [
          "🎩", "👒", "🎀", "👓", "⭐", "🌸", "🔥", "💎", "🍀"
      ]

      func save() {
          guard let data = try? JSONEncoder().encode(self) else { return }
          UserDefaults.standard.set(data, forKey: "cruxpet.customization")
      }

      static func load() -> PetCustomization {
          guard let data = UserDefaults.standard.data(forKey: "cruxpet.customization"),
                let c = try? JSONDecoder().decode(PetCustomization.self, from: data)
          else { return PetCustomization() }
          return c
      }
  }
  ```

- [ ] **Step 4: 테스트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL)" | head -10
  ```

  Expected: `Test Suite 'PetCustomizationTests' passed`

- [ ] **Step 5: 커밋**

  ```bash
  git add CruxPet/PetCustomization.swift CruxPetTests/PetCustomizationTests.swift
  git commit -m "feat: add PetCustomization model with save/load"
  ```

---

## Task 2: SlimeAppearance.applying() + SlimeView 악세서리

**Files:**
- Modify: `CruxPet/PetModel.swift` — applying() extension 추가
- Modify: `CruxPet/SlimeView.swift` — accessory 파라미터 추가
- Modify: `CruxPetTests/PetModelTests.swift` — applying() 테스트 추가

- [ ] **Step 1: applying() 테스트 추가**

  `CruxPetTests/PetModelTests.swift` 끝에 추가:

  ```swift
  func testApplyingKeepsLevelColorWhenUseCustomColorFalse() {
      let base = PetModel.appearance(for: 1)   // #7EC8E3
      var c = PetCustomization()
      c.useCustomColor = false
      c.customColorHex = "#EF5350"
      let result = base.applying(c)
      XCTAssertEqual(result.bodyHex, base.bodyHex)
      XCTAssertEqual(result.isRainbow, base.isRainbow)
  }

  func testApplyingOverridesColorWhenUseCustomColorTrue() {
      let base = PetModel.appearance(for: 1)
      var c = PetCustomization()
      c.useCustomColor = true
      c.customColorHex = "#EF5350"
      let result = base.applying(c)
      XCTAssertEqual(result.bodyHex, "#EF5350")
      XCTAssertFalse(result.isRainbow)
  }
  ```

- [ ] **Step 2: 테스트 실패 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|FAIL)" | head -5
  ```

  Expected: 컴파일 에러 (`applying` 없음)

- [ ] **Step 3: PetModel.swift에 extension 추가**

  `CruxPet/PetModel.swift` 파일 맨 끝에 추가:

  ```swift
  extension SlimeAppearance {
      func applying(_ customization: PetCustomization) -> SlimeAppearance {
          guard customization.useCustomColor else { return self }
          return SlimeAppearance(
              bodyHex: customization.customColorHex,
              size: size, crownType: crownType,
              sparkleCount: sparkleCount,
              hasHalo: hasHalo, isRainbow: false, isPearl: isPearl
          )
      }
  }
  ```

- [ ] **Step 4: SlimeView에 accessory 파라미터 추가**

  `CruxPet/SlimeView.swift`에서 `struct SlimeView: View` 프로퍼티에 추가:

  ```swift
  var accessory: String = ""
  ```

  그리고 `drawCrown` 호출 직후 악세서리 렌더링 추가:

  ```swift
  // 악세서리 (왕관 오른쪽 위)
  if !accessory.isEmpty {
      drawAccessory(context: &context, bodyRect: bodyRect)
  }
  ```

  `SlimeView`에 `drawAccessory` 메서드 추가:

  ```swift
  private func drawAccessory(context: inout GraphicsContext, bodyRect: CGRect) {
      let size = bodyRect.width * 0.38
      let resolved = context.resolve(Text(accessory).font(.system(size: size)))
      let x = bodyRect.maxX - size * 0.1
      let y = bodyRect.minY - size * 0.1
      context.draw(resolved, at: CGPoint(x: x, y: y), anchor: .bottomTrailing)
  }
  ```

- [ ] **Step 5: 테스트 통과 + 빌드 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL)" | head -10
  ```

  Expected: `PetModelTests` 전체 통과

- [ ] **Step 6: 커밋**

  ```bash
  git add CruxPet/PetModel.swift CruxPet/SlimeView.swift CruxPetTests/PetModelTests.swift
  git commit -m "feat: add SlimeAppearance.applying(), SlimeView accessory rendering"
  ```

---

## Task 3: PomodoroTimer duration 지원

**Files:**
- Modify: `CruxPet/PomodoroTimer.swift`
- Modify: `CruxPetTests/PomodoroTimerTests.swift`

- [ ] **Step 1: 테스트 추가**

  `CruxPetTests/PomodoroTimerTests.swift`에 추가:

  ```swift
  func testSetDurationUpdatesTimeRemaining() {
      let timer = PomodoroTimer()
      timer.setDuration(15)
      XCTAssertEqual(timer.timeRemaining, 15 * 60)
      XCTAssertEqual(timer.state, .idle)
  }

  func testResetUsesCurrentDuration() {
      let timer = PomodoroTimer()
      timer.setDuration(50)
      timer.start()
      timer.reset()
      XCTAssertEqual(timer.timeRemaining, 50 * 60)
  }
  ```

- [ ] **Step 2: 테스트 실패 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|FAIL)" | head -5
  ```

  Expected: 컴파일 에러 (`setDuration` 없음)

- [ ] **Step 3: PomodoroTimer 수정**

  `CruxPet/PomodoroTimer.swift`에서:

  1. `private(set) var timeRemaining: TimeInterval = 25 * 60` 위에 duration 프로퍼티 추가:
  ```swift
  private(set) var duration: TimeInterval = 25 * 60
  ```

  2. `reset()` 함수를 아래로 교체:
  ```swift
  func reset() {
      timer?.invalidate()
      timer = nil
      state = .idle
      timeRemaining = duration
  }
  ```

  3. `reset()` 다음에 `setDuration` 추가:
  ```swift
  func setDuration(_ minutes: Int) {
      duration = TimeInterval(minutes * 60)
      reset()
  }
  ```

- [ ] **Step 4: 테스트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL)" | head -10
  ```

  Expected: `PomodoroTimerTests` 전체 통과

- [ ] **Step 5: 커밋**

  ```bash
  git add CruxPet/PomodoroTimer.swift CruxPetTests/PomodoroTimerTests.swift
  git commit -m "feat: add PomodoroTimer.setDuration(), reset() uses current duration"
  ```

---

## Task 4: CustomizeView — 설정 UI

**Files:**
- Create: `CruxPet/CustomizeView.swift`

- [ ] **Step 1: CustomizeView 구현**

  `CruxPet/CustomizeView.swift`:

  ```swift
  import SwiftUI

  struct CustomizeView: View {
      let current: PetCustomization
      let petLevel: Int
      let onSave: (PetCustomization) -> Void
      let onCancel: () -> Void

      @State private var draft: PetCustomization

      init(current: PetCustomization, petLevel: Int,
           onSave: @escaping (PetCustomization) -> Void,
           onCancel: @escaping () -> Void) {
          self.current = current
          self.petLevel = petLevel
          self.onSave = onSave
          self.onCancel = onCancel
          _draft = State(initialValue: current)
      }

      private var previewAppearance: SlimeAppearance {
          PetModel.appearance(for: petLevel).applying(draft)
      }

      var body: some View {
          ScrollView {
              VStack(spacing: 12) {
                  // 실시간 미리보기
                  SlimeView(appearance: previewAppearance, accessory: draft.accessory)
                      .frame(height: 80)

                  Divider()

                  // 이름
                  VStack(alignment: .leading, spacing: 4) {
                      Text("이름").font(.caption.bold()).foregroundStyle(.secondary)
                      TextField("슬라임 이름", text: $draft.name)
                          .textFieldStyle(.roundedBorder)
                          .font(.caption)
                          .onChange(of: draft.name) { _, new in
                              if new.count > 10 { draft.name = String(new.prefix(10)) }
                          }
                  }

                  // 색상
                  VStack(alignment: .leading, spacing: 6) {
                      HStack {
                          Text("색상").font(.caption.bold()).foregroundStyle(.secondary)
                          Spacer()
                          Toggle("레벨 색 사용", isOn: Binding(
                              get: { !draft.useCustomColor },
                              set: { draft.useCustomColor = !$0 }
                          ))
                          .toggleStyle(.checkbox)
                          .font(.caption2)
                      }
                      HStack(spacing: 6) {
                          ForEach(PetCustomization.presetColors, id: \.self) { hex in
                              Circle()
                                  .fill(Color(hex: hex))
                                  .frame(width: 22, height: 22)
                                  .overlay(
                                      Circle().stroke(Color.white, lineWidth: draft.customColorHex == hex && draft.useCustomColor ? 2 : 0)
                                  )
                                  .opacity(draft.useCustomColor ? 1.0 : 0.4)
                                  .onTapGesture {
                                      draft.customColorHex = hex
                                      draft.useCustomColor = true
                                  }
                          }
                      }
                  }

                  // 악세서리
                  VStack(alignment: .leading, spacing: 6) {
                      Text("악세서리").font(.caption.bold()).foregroundStyle(.secondary)
                      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                          ForEach(PetCustomization.accessories, id: \.self) { emoji in
                              Text(emoji)
                                  .font(.title3)
                                  .frame(width: 32, height: 32)
                                  .background(draft.accessory == emoji ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                  .onTapGesture { draft.accessory = draft.accessory == emoji ? "" : emoji }
                          }
                          Text("✕")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                              .frame(width: 32, height: 32)
                              .background(draft.accessory.isEmpty ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                              .onTapGesture { draft.accessory = "" }
                      }
                  }

                  // 포모도로 시간
                  VStack(alignment: .leading, spacing: 6) {
                      Text("포모도로 시간").font(.caption.bold()).foregroundStyle(.secondary)
                      HStack(spacing: 6) {
                          ForEach([15, 25, 50], id: \.self) { min in
                              Button("\(min)분") { draft.pomodoroMinutes = min }
                                  .buttonStyle(.bordered)
                                  .controlSize(.small)
                                  .tint(draft.pomodoroMinutes == min ? .blue : .secondary)
                          }
                      }
                  }

                  // 버튼
                  HStack(spacing: 8) {
                      Button("취소", action: onCancel)
                          .buttonStyle(.bordered)
                          .controlSize(.small)
                      Button("저장") { onSave(draft) }
                          .buttonStyle(.borderedProminent)
                          .controlSize(.small)
                  }
                  .padding(.top, 4)
              }
              .padding(12)
          }
          .frame(width: 200)
      }
  }
  ```

- [ ] **Step 2: 빌드 확인**

  ```bash
  xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | tail -3
  ```

  Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

  ```bash
  git add CruxPet/CustomizeView.swift
  git commit -m "feat: add CustomizeView settings UI with live preview"
  ```

---

## Task 5: ContentView 연결

**Files:**
- Modify: `CruxPet/ContentView.swift`

- [ ] **Step 1: ContentView 수정**

  1. `@State private var watcher = EventWatcher()` 다음 줄에 추가:
  ```swift
  @State private var customization = PetCustomization.load()
  @State private var showCustomize = false
  ```

  2. `body`의 `VStack` 내용 전체를 `ZStack`으로 감싸서 CustomizeView 오버레이 추가:
  ```swift
  var body: some View {
      ZStack {
          // 메인 화면
          VStack(spacing: 10) {
              characterSection
              expSection
              pomodoroSection
              activitySection
              Divider()
              HStack {
                  Button(action: shareCard) {
                      Label("공유", systemImage: "square.and.arrow.up")
                          .font(.caption)
                  }
                  .buttonStyle(.plain)
                  .foregroundStyle(.secondary)
                  Spacer()
                  Button {
                      showCustomize = true
                  } label: {
                      Image(systemName: "gearshape")
                          .font(.caption)
                  }
                  .buttonStyle(.plain)
                  .foregroundStyle(.secondary)
                  Spacer()
                  Button("종료") { NSApplication.shared.terminate(nil) }
                      .buttonStyle(.plain)
                      .foregroundStyle(.secondary)
                      .font(.caption)
              }
          }
          .padding(12)
          .opacity(showCustomize ? 0 : 1)

          // 설정 화면
          if showCustomize {
              CustomizeView(
                  current: customization,
                  petLevel: pet.level,
                  onSave: { newCustomization in
                      customization = newCustomization
                      customization.save()
                      pomodoro.setDuration(newCustomization.pomodoroMinutes)
                      showCustomize = false
                  },
                  onCancel: { showCustomize = false }
              )
              .transition(.opacity)
          }
      }
      .frame(width: 200)
      .background(.ultraThinMaterial)
      .animation(.easeInOut(duration: 0.15), value: showCustomize)
      .onAppear { setupWatcher() }
  }
  ```

  3. `characterSection`에서 SlimeView 호출을 아래로 수정:
  ```swift
  SlimeView(
      appearance: pet.slimeAppearance.applying(customization),
      isPomodoroActive: pomodoro.state == .running,
      accessory: customization.accessory
  )
  ```

  4. `characterSection`의 레벨 텍스트를 이름 포함으로 수정:
  ```swift
  Text("Lv. \(pet.level) · \(customization.name)")
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(.secondary)
  ```

  5. `setupWatcher()` 내 `pomodoro.onComplete` 설정 **전에** duration 초기화 추가:
  ```swift
  private func setupWatcher() {
      pomodoro.setDuration(customization.pomodoroMinutes)
      watcher.onCommit = { pet.gainCommitExp() }
      watcher.start()
      pomodoro.onComplete = {
          watcher.appendPomodoro()
          pet.gainPomodoroExp()
          sendPomodoroNotification()
      }
  }
  ```

- [ ] **Step 2: 빌드 확인**

  ```bash
  xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | tail -3
  ```

  Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

  ```bash
  git add CruxPet/ContentView.swift
  git commit -m "feat: wire CustomizeView into ContentView, apply customization to SlimeView"
  ```

---

## Task 6: 통합 테스트

- [ ] **Step 1: 전체 테스트 통과 확인**

  ```bash
  xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "(TEST SUCCEEDED|TEST FAILED|FAIL)" | tail -3
  ```

  Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: 수동 검증**

  앱 실행 후:
  1. 하단에 ⚙️ 버튼이 공유 버튼 옆에 생겼는지 확인
  2. ⚙️ 클릭 → 설정 화면으로 전환, 슬라임 미리보기 보임
  3. 이름 변경 → 메인 화면에서 `Lv. N · 새이름` 확인
  4. 색상 선택 + "레벨 색 사용" 토글 해제 → 미리보기에서 색 바뀜
  5. 악세서리 선택 → 슬라임 옆에 이모지 표시됨
  6. 포모도로 시간 15분 선택 후 저장 → 타이머가 15:00으로 변경됨
  7. 취소 → 변경 사항 무시되고 메인 화면 복귀

- [ ] **Step 3: 최종 커밋**

  ```bash
  git add -A
  git commit -m "feat: complete slime customization (name, color, accessory, pomodoro time)"
  ```
