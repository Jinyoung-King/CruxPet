# 슬롯 기반 악세사리 시스템 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 슬라임 악세사리를 머리/얼굴/몸/오라 4개 슬롯으로 확장해 동시 장착을 지원한다.

**Architecture:** `AccessorySlot` enum이 슬롯 정의와 아이템 풀을 소유하고, `PetCustomization.accessories: [String: String]`으로 슬롯별 장착 상태를 저장한다. SlimeView는 슬롯별 고정 위치 4곳에 렌더링하고, CustomizeView는 탭 방식으로 슬롯을 전환한다.

**Tech Stack:** Swift, SwiftUI Canvas, XCTest, UserDefaults (Codable)

---

## File Structure

| 파일 | 변경 내용 |
|------|-----------|
| `CruxPet/PetCustomization.swift` | `AccessorySlot` enum 추가, `accessory: String` → `accessories: [String: String]` |
| `CruxPet/CustomizeView.swift` | 탭 바 + 슬롯별 그리드로 악세서리 섹션 교체 |
| `CruxPet/SlimeView.swift` | `accessory: String` → `accessories: [String: String]`, 4위치 렌더링 |
| `CruxPet/ContentView.swift` | `customization.accessory` → `customization.accessories` |
| `CruxPet/ShareCardView.swift` | `customization.accessory` → `customization.accessories` |
| `CruxPetTests/PetCustomizationTests.swift` | 기존 `accessory` 테스트 → `accessories` 테스트로 교체 |

---

### Task 1: AccessorySlot enum + PetCustomization 데이터 모델

**Files:**
- Modify: `CruxPet/PetCustomization.swift`
- Modify: `CruxPetTests/PetCustomizationTests.swift`

- [ ] **Step 1: 실패하는 테스트 작성**

`CruxPetTests/PetCustomizationTests.swift` 전체를 아래로 교체:

```swift
import XCTest
@testable import CruxPet

final class PetCustomizationTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "cruxpet.customization")
    }

    // MARK: - AccessorySlot

    func testAccessorySlotItems() {
        XCTAssertEqual(AccessorySlot.head.items,  ["🎩", "👒", "🎀", "👑", "🪖", "🎓", "🪄"])
        XCTAssertEqual(AccessorySlot.face.items,  ["👓", "🕶️", "🥸", "😷", "🎭"])
        XCTAssertEqual(AccessorySlot.body.items,  ["⭐", "🌸", "💎", "🍀", "🎸", "🎮", "🏆", "🎯"])
        XCTAssertEqual(AccessorySlot.aura.items,  ["🔥", "⚡", "❄️", "🌊", "✨", "🌈"])
    }

    func testAccessorySlotAllCasesCount() {
        XCTAssertEqual(AccessorySlot.allCases.count, 4)
    }

    // MARK: - PetCustomization defaults

    func testDefaultValues() {
        let c = PetCustomization()
        XCTAssertEqual(c.name, "Crux")
        XCTAssertFalse(c.useCustomColor)
        XCTAssertEqual(c.customColorHex, "#7EC8E3")
        XCTAssertTrue(c.accessories.isEmpty)
        XCTAssertEqual(c.pomodoroMinutes, 25)
    }

    // MARK: - Save / Load

    func testSaveAndLoad() {
        var c = PetCustomization()
        c.name = "TestSlime"
        c.useCustomColor = true
        c.customColorHex = "#EF5350"
        c.accessories = ["head": "🎩", "aura": "🔥"]
        c.pomodoroMinutes = 50
        c.save()

        let loaded = PetCustomization.load()
        XCTAssertEqual(loaded.name, "TestSlime")
        XCTAssertTrue(loaded.useCustomColor)
        XCTAssertEqual(loaded.customColorHex, "#EF5350")
        XCTAssertEqual(loaded.accessories["head"], "🎩")
        XCTAssertEqual(loaded.accessories["aura"], "🔥")
        XCTAssertNil(loaded.accessories["face"])
        XCTAssertEqual(loaded.pomodoroMinutes, 50)
    }

    func testLoadReturnsDefaultWhenNotSaved() {
        let c = PetCustomization.load()
        XCTAssertEqual(c.name, "Crux")
        XCTAssertTrue(c.accessories.isEmpty)
        XCTAssertEqual(c.pomodoroMinutes, 25)
    }

    func testOldDataMigration() {
        // 구버전 데이터 (accessory: String) 는 accessories 키가 없어
        // Codable 기본값인 빈 딕셔너리로 디코딩되어야 한다.
        let oldJSON = """
        {"name":"OldSlime","useCustomColor":false,"customColorHex":"#7EC8E3",
         "accessory":"🎩","pomodoroMinutes":25}
        """.data(using: .utf8)!
        UserDefaults.standard.set(oldJSON, forKey: "cruxpet.customization")

        let c = PetCustomization.load()
        XCTAssertEqual(c.name, "OldSlime")
        XCTAssertTrue(c.accessories.isEmpty)   // accessory 필드 무시, 기본값
    }
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "error:|failed|passed"
```

Expected: 컴파일 에러 (`AccessorySlot` not found, `c.accessories` not found)

- [ ] **Step 3: PetCustomization.swift 구현**

`CruxPet/PetCustomization.swift` 전체를 아래로 교체:

```swift
import Foundation

enum AccessorySlot: String, CaseIterable, Codable {
    case head, face, body, aura

    var label: String {
        switch self {
        case .head: return "🎩 머리"
        case .face: return "👓 얼굴"
        case .body: return "💎 몸"
        case .aura: return "🔥 오라"
        }
    }

    var items: [String] {
        switch self {
        case .head: return ["🎩", "👒", "🎀", "👑", "🪖", "🎓", "🪄"]
        case .face: return ["👓", "🕶️", "🥸", "😷", "🎭"]
        case .body: return ["⭐", "🌸", "💎", "🍀", "🎸", "🎮", "🏆", "🎯"]
        case .aura: return ["🔥", "⚡", "❄️", "🌊", "✨", "🌈"]
        }
    }
}

struct PetCustomization: Codable {
    var name: String = "Crux"
    var useCustomColor: Bool = false
    var customColorHex: String = "#7EC8E3"
    var accessories: [String: String] = [:]
    var pomodoroMinutes: Int = 25

    static let presetColors: [String] = [
        "#7EC8E3", "#EF5350", "#66BB6A",
        "#FFA726", "#AB47BC", "#FFD700", "#F48FB1"
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
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "Test.*passed|Test.*failed|error:"
```

Expected: PetCustomizationTests 5개 통과. 다른 테스트는 컴파일 에러 가능 (아직 SlimeView, ContentView 미수정).

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/PetCustomization.swift CruxPetTests/PetCustomizationTests.swift
git commit -m "feat: AccessorySlot enum + PetCustomization 4슬롯 데이터 모델"
```

---

### Task 2: SlimeView — 4슬롯 렌더링

**Files:**
- Modify: `CruxPet/SlimeView.swift:1-10` (파라미터), `CruxPet/SlimeView.swift:80-92` (드로우 호출), `CruxPet/SlimeView.swift:345-353` (드로우 함수)

- [ ] **Step 1: SlimeView 파라미터 교체**

`SlimeView.swift` 6번째 줄:
```swift
// 변경 전
var accessory: String = ""

// 변경 후
var accessories: [String: String] = [:]
```

- [ ] **Step 2: 드로우 호출 교체**

`SlimeView.swift` 86-88번째 줄 (기존 `if !accessory.isEmpty { drawAccessory(...) }`):

```swift
// 변경 전
if !accessory.isEmpty {
    drawAccessory(context: &context, bodyRect: bodyRect)
}

// 변경 후
drawSlotAccessories(context: &context, bodyRect: bodyRect)
```

- [ ] **Step 3: 드로우 함수 교체**

`SlimeView.swift` 345-352번째 줄 (기존 `drawAccessory` 함수):

```swift
// 변경 전
// MARK: - Accessory

private func drawAccessory(context: inout GraphicsContext, bodyRect: CGRect) {
    let size = bodyRect.width * 0.38
    let r = context.resolve(Text(accessory).font(.system(size: size)))
    context.draw(r, at: CGPoint(x: bodyRect.maxX - size*0.1,
                                y: bodyRect.minY - size*0.1), anchor: .bottomTrailing)
}

// 변경 후
// MARK: - Accessories

private func drawSlotAccessories(context: inout GraphicsContext, bodyRect: CGRect) {
    if let emoji = accessories[AccessorySlot.head.rawValue] {
        let size = bodyRect.width * 0.40
        let r = context.resolve(Text(emoji).font(.system(size: size)))
        context.draw(r, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY), anchor: .bottom)
    }
    if let emoji = accessories[AccessorySlot.face.rawValue] {
        let size = bodyRect.width * 0.30
        let r = context.resolve(Text(emoji).font(.system(size: size)))
        context.draw(r, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY + bodyRect.height * 0.3), anchor: .center)
    }
    if let emoji = accessories[AccessorySlot.body.rawValue] {
        let size = bodyRect.width * 0.35
        let r = context.resolve(Text(emoji).font(.system(size: size)))
        context.draw(r, at: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY), anchor: .bottomTrailing)
    }
    if let emoji = accessories[AccessorySlot.aura.rawValue] {
        let size = bodyRect.width * 0.35
        let r = context.resolve(Text(emoji).font(.system(size: size)))
        context.draw(r, at: CGPoint(x: bodyRect.minX, y: bodyRect.maxY), anchor: .bottomLeading)
    }
}
```

- [ ] **Step 4: 빌드 확인 (ContentView/ShareCardView 에러 예상)**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep "error:"
```

Expected: `ContentView.swift`와 `ShareCardView.swift`에서 `accessory:` 파라미터 에러만 남음.

- [ ] **Step 5: 커밋**

```bash
git add CruxPet/SlimeView.swift
git commit -m "feat: SlimeView 4슬롯 위치 렌더링"
```

---

### Task 3: CustomizeView — 탭 방식 슬롯 UI

**Files:**
- Modify: `CruxPet/CustomizeView.swift:9` (State 추가), `CruxPet/CustomizeView.swift:29` (SlimeView 호출), `CruxPet/CustomizeView.swift:74-92` (악세서리 섹션 전체 교체)

- [ ] **Step 1: selectedSlot State 추가**

`CustomizeView.swift` 9번째 줄 (`@State private var draft` 아래):

```swift
// 추가
@State private var selectedSlot: AccessorySlot = .head
```

- [ ] **Step 2: SlimeView 호출 수정**

`CustomizeView.swift` 29번째 줄:

```swift
// 변경 전
SlimeView(appearance: previewAppearance, accessory: draft.accessory)

// 변경 후
SlimeView(appearance: previewAppearance, accessories: draft.accessories)
```

- [ ] **Step 3: 악세서리 섹션 전체 교체**

`CustomizeView.swift` 74-92번째 줄 (기존 악세서리 `VStack`):

```swift
// 변경 전
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

// 변경 후
// 악세서리
VStack(alignment: .leading, spacing: 6) {
    Text("악세서리").font(.caption.bold()).foregroundStyle(.secondary)

    // 슬롯 탭 바
    HStack(spacing: 4) {
        ForEach(AccessorySlot.allCases, id: \.self) { slot in
            Text(slot.label)
                .font(.system(size: 10))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(selectedSlot == slot ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedSlot == slot ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1))
                .onTapGesture { selectedSlot = slot }
        }
    }

    // 선택된 슬롯의 아이템 그리드
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
        ForEach(selectedSlot.items, id: \.self) { emoji in
            Text(emoji)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(draft.accessories[selectedSlot.rawValue] == emoji ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 6))
                .onTapGesture {
                    if draft.accessories[selectedSlot.rawValue] == emoji {
                        draft.accessories.removeValue(forKey: selectedSlot.rawValue)
                    } else {
                        draft.accessories[selectedSlot.rawValue] = emoji
                    }
                }
        }
        Text("✕")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 32)
            .background(draft.accessories[selectedSlot.rawValue] == nil ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 6))
            .onTapGesture { draft.accessories.removeValue(forKey: selectedSlot.rawValue) }
    }
}
```

- [ ] **Step 4: CustomizeView 높이 조정**

`CustomizeView.swift` 120번째 줄 (`.frame(width: 220, height: 380)`):

```swift
// 변경 전
.frame(width: 220, height: 380)

// 변경 후
.frame(width: 220, height: 420)
```

- [ ] **Step 5: 빌드 확인**

```bash
xcodebuild build -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep "error:"
```

Expected: `ContentView.swift`와 `ShareCardView.swift`에서 `accessory:` 파라미터 에러만 남음.

- [ ] **Step 6: 커밋**

```bash
git add CruxPet/CustomizeView.swift
git commit -m "feat: CustomizeView 탭 방식 4슬롯 악세서리 UI"
```

---

### Task 4: ContentView + ShareCardView 호출 수정 + 전체 테스트

**Files:**
- Modify: `CruxPet/ContentView.swift:199`
- Modify: `CruxPet/ShareCardView.swift:134`

- [ ] **Step 1: ContentView.swift 수정**

`ContentView.swift` 199번째 줄:

```swift
// 변경 전
accessory: customization.accessory,

// 변경 후
accessories: customization.accessories,
```

- [ ] **Step 2: ShareCardView.swift 수정**

`ShareCardView.swift` 134번째 줄:

```swift
// 변경 전
SlimeView(appearance: appearance, accessory: customization.accessory)

// 변경 후
SlimeView(appearance: appearance, accessories: customization.accessories)
```

- [ ] **Step 3: 전체 빌드 + 테스트 통과 확인**

```bash
xcodebuild test -scheme CruxPet -destination 'platform=macOS' 2>&1 | grep -E "Test Suite|passed|failed|error:"
```

Expected: 모든 테스트 통과, 에러 없음.

- [ ] **Step 4: 커밋**

```bash
git add CruxPet/ContentView.swift CruxPet/ShareCardView.swift
git commit -m "feat: ContentView, ShareCardView 4슬롯 악세서리 참조 업데이트"
```
