# CruxPet 커스터마이징 설계

**Date:** 2026-06-05
**Status:** Approved

---

## 개요

메인 UI에 ⚙️ 버튼을 추가하고, 클릭 시 설정 화면으로 전환한다. 슬라임 이름, 색상, 악세서리, 포모도로 시간을 설정할 수 있다.

---

## 기능 목록

### 1. 이름
- 슬라임에 이름을 붙여줄 수 있다 (최대 10자)
- 기본값: `"Crux"`
- 메인 화면의 `Lv. N · {이름}` 표시에 반영

### 2. 색상 고정
- 7가지 프리셋 색상 중 선택 가능
  - 파랑 `#7EC8E3`, 빨강 `#EF5350`, 초록 `#66BB6A`, 주황 `#FFA726`, 보라 `#AB47BC`, 황금 `#FFD700`, 핑크 `#F48FB1`
- "레벨 색 사용" 체크박스: 체크 시 커스텀 색상 무시하고 레벨 기반 색상 사용 (기본값: 체크됨)
- 색상 고정 시 `SlimeAppearance.bodyHex`와 `isRainbow`를 덮어쓴다

### 3. 악세서리
- 9종 + 없음(✕) 중 1개 선택
  - 🎩 탑햇, 👒 밀짚모자, 🎀 리본, 👓 안경, ⭐ 별, 🌸 꽃, 🔥 불꽃, 💎 다이아, 🍀 클로버
- 없음 선택 시 악세서리 미표시 (기본값)
- SlimeView의 왕관 위치(bodyRect 위)에 이모지로 렌더링
- 레벨 기반 왕관(CrownType)과 공존: 악세서리는 왕관 오른쪽 위에 작게 표시

### 4. 포모도로 시간
- 15분 / 25분 / 50분 중 선택 (기본값: 25분)
- PomodoroTimer의 초기 `timeRemaining`에 반영

---

## UI 구조

```
메인 화면
  └── 하단 바에 ⚙️ 버튼 추가 (공유 버튼 옆)
        └── 클릭 시 ContentView가 설정 화면으로 슬라이드 전환
              ├── 미리보기: 슬라임 (실시간 반영)
              ├── 이름 입력 (TextField)
              ├── 색상 선택 (HStack of ColorDot buttons)
              ├── 악세서리 선택 (LazyVGrid)
              ├── 포모도로 시간 (SegmentedPicker or 3 buttons)
              └── [취소] [저장] 버튼
```

설정 화면은 별도 뷰(`CustomizeView`)로 분리하며, `ContentView`에서 `@State private var showCustomize = false`로 표시 제어한다. 취소 시 변경 사항 무시, 저장 시 `PetCustomization`에 반영 후 `UserDefaults` 저장.

---

## 데이터 모델

```swift
struct PetCustomization: Codable {
    var name: String = "Crux"
    var useCustomColor: Bool = false   // false = 레벨 색 사용
    var customColorHex: String = "#7EC8E3"
    var accessory: String = ""         // 이모지 문자열, 빈 문자열 = 없음
    var pomodoroMinutes: Int = 25
}
```

`SlimeAppearance`에 색상 덮어쓰기용 메서드 추가:
```swift
extension SlimeAppearance {
    func applying(_ customization: PetCustomization) -> SlimeAppearance {
        guard customization.useCustomColor else { return self }
        return SlimeAppearance(bodyHex: customization.customColorHex, size: size,
            crownType: crownType, sparkleCount: sparkleCount,
            hasHalo: hasHalo, isRainbow: false, isPearl: isPearl)
    }
}
```

`ContentView`에서 SlimeView에 넘길 때 적용:
```swift
SlimeView(appearance: pet.slimeAppearance.applying(customization), ...)
```

`UserDefaults` 키:
- `cruxpet.customization` — JSON 인코딩된 `PetCustomization`

---

## 파일 구조

| 파일 | 변경 |
|------|------|
| `CruxPet/PetCustomization.swift` | 신규 — 데이터 모델 + UserDefaults 저장/로드 |
| `CruxPet/CustomizeView.swift` | 신규 — 설정 UI |
| `CruxPet/ContentView.swift` | 수정 — ⚙️ 버튼 추가, CustomizeView 전환 |
| `CruxPet/SlimeView.swift` | 수정 — 악세서리 이모지 렌더링 추가 |
| `CruxPet/PomodoroTimer.swift` | 수정 — duration 파라미터 지원 |

---

## 동작 흐름

1. 앱 시작 시 `PetCustomization`을 UserDefaults에서 로드
2. `SlimeAppearance` 계산 시 `useCustomColor == true`면 `customColorHex`로 bodyHex 덮어쓰기
3. `PomodoroTimer` 초기화 시 `pomodoroMinutes`로 `timeRemaining` 설정
4. 설정 저장 시: `PetCustomization` UserDefaults 저장 → 포모도로 타이머 reset → SlimeView 즉시 반영
