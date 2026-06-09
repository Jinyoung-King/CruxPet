# 슬롯 기반 악세사리 시스템 — Design Spec

## Goal

슬라임에 부위별(머리/얼굴/몸/오라) 4개 슬롯을 도입해 여러 악세사리를 동시에 장착할 수 있도록 한다.

## Architecture

- **`PetCustomization`** — `accessory: String` → `accessories: [String: String]` 로 교체
- **`AccessorySlot`** — 4개 슬롯을 표현하는 enum (신규)
- **`CustomizeView`** — 탭 방식으로 슬롯 전환, 슬롯별 이모지 그리드
- **`SlimeView`** — 슬롯별 고정 위치에 이모지 렌더링 (4곳)

## 데이터 모델

```swift
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
```

`PetCustomization`:
```swift
struct PetCustomization: Codable {
    var name: String = "Crux"
    var useCustomColor: Bool = false
    var customColorHex: String = "#7EC8E3"
    var accessories: [String: String] = [:]   // AccessorySlot.rawValue → emoji
    var pomodoroMinutes: Int = 25
    // 기존 accessory: String 제거
}
```

저장 키(`"cruxpet.customization"`)는 유지. 기존 데이터는 자동으로 `accessories` 가 빈 딕셔너리로 마이그레이션됨 (Codable 기본값).

## 악세사리 풀 (총 30개)

| 슬롯 | 아이템 |
|------|--------|
| head | 🎩 👒 🎀 👑 🪖 🎓 🪄 |
| face | 👓 🕶️ 🥸 😷 🎭 |
| body | ⭐ 🌸 💎 🍀 🎸 🎮 🏆 🎯 |
| aura | 🔥 ⚡ ❄️ 🌊 ✨ 🌈 |

모든 악세사리는 처음부터 잠금 해제 상태.

## UI — CustomizeView

슬롯 탭 바 + 그리드:

```
[🎩 머리] [👓 얼굴] [💎 몸] [🔥 오라]
┌─────────────────────────────┐
│  🎩  👒  🎀  👑  🪖  🎓  🪄  │
│  (현재 선택 항목은 파란 테두리)  │
│                   [해제 ✕]  │
└─────────────────────────────┘
```

- 탭 전환 시 해당 슬롯의 아이템 그리드 표시
- 아이템 탭 → 장착. 동일 아이템 재탭 → 해제
- 슬롯당 1개만 장착 가능

## 렌더링 — SlimeView

`drawAccessory` → 슬롯별 `drawSlotAccessory` 4개 함수:

| 슬롯 | 위치 | 앵커 |
|------|------|------|
| head | `bodyRect` 위 중앙 | `.bottom` |
| face | `bodyRect` 중앙 (눈 위 30%) | `.center` |
| body | `bodyRect` 오른쪽 하단 | `.bottomTrailing` |
| aura | `bodyRect` 왼쪽 하단 | `.bottomLeading` |

크기: `bodyRect.width * 0.35` (head는 0.40으로 약간 크게)

## 변경 파일

| 파일 | 변경 내용 |
|------|-----------|
| `PetCustomization.swift` | `AccessorySlot` enum 추가, `accessory` → `accessories` 교체 |
| `CustomizeView.swift` | 탭 바 + 슬롯별 그리드로 전면 교체 |
| `SlimeView.swift` | 슬롯별 렌더링 위치 4곳으로 분리 |
| `SlimeView.swift` | `accessory: String` 파라미터 → `accessories: [String: String]` 로 변경 |
| `ContentView.swift` | `customization.accessory` 참조 → `customization.accessories` 로 업데이트 |
