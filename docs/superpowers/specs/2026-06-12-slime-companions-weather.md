# 슬라임 친구 + 날씨/시간 반응 Design Spec

## Goal

메인 슬라임 옆에 조건 달성 시 동료 슬라임이 나란히 등장하고, 현재 시간대와 실제 날씨에 따라 슬라임에 자동 액세서리가 오버레이된다.

---

## Feature 1: 슬라임 친구 (Companion Slimes)

### 잠금 해제 조건 및 외형

| ID | 이름 | 조건 | bodyHex | size | 특징 |
|---|---|---|---|---|---|
| `baby` | 아기 슬라임 | Lv.10 도달 | `#7EC8E3` | 14 | 기본 미니 슬라임 |
| `flame` | 불꽃 슬라임 | 스트릭 7일 | `#FF5722` | 14 | 위에 🔥 표시 |
| `star` | 별빛 슬라임 | 업적 5개 달성 | `#FFD700` | 14 | 위에 ✨ 표시 |
| `night` | 야왕 슬라임 | Night Owl 커밋 1회 | `#212121` | 14 | 위에 🌙 표시 |
| `pomo` | 포모 슬라임 | 포모도로 20회 누적 | `#E53935` | 14 | 위에 🍅 표시 |

### 동작

- 조건 달성 시 즉시 잠금 해제, UserDefaults에 저장
- 팝업 characterSection에서 메인 슬라임 옆에 HStack으로 나열 (간격 8pt)
- 각 친구는 단순 Canvas 기반 미니 슬라임 (배회 없음, 아주 느린 bob 애니메이션만)
- 친구 위의 이모지는 슬라임 바로 위 중앙에 작게 (font size 8)
- 잠금 해제 시 toast: "🐾 {이름} 등장!" + 새 친구 spring 애니메이션으로 나타남

### 아키텍처

**`CruxPet/CompanionModel.swift`** (새 파일)
- `Companion` struct: `id`, `name`, `bodyHex`, `emoji`, `unlockDescription`
- `CompanionModel` class (`@Observable`): `unlockedIDs: Set<String>` (UserDefaults)
- `func checkUnlocks(pet: PetModel) -> [Companion]` — 새로 달성된 친구 반환
- 순수 static 로직으로 테스트 가능하게 설계

**`CruxPet/CompanionSlimeView.swift`** (새 파일)
- `companion: Companion`을 받아 미니 슬라임 Canvas 렌더링
- `size: 14`, 느린 bob (sinusoidal y offset), 색상은 `companion.bodyHex`
- 슬라임 위에 `companion.emoji` Text 오버레이

**`ContentView.swift`** 수정
- `characterSection`에 `CompanionModel` 환경 추가
- 메인 슬라임 ZStack 아래 `companionRow` HStack 추가
- level/achievement 변화 onChange에서 `checkUnlocks` 호출

---

## Feature 2: 날씨/시간 반응 (Environment Reactions)

### 시간대별 반응

| 시간대 | 범위 | 오버레이 |
|---|---|---|
| 새벽 | 0–4시 | 🌙 달 |
| 아침 | 5–8시 | 🌤 해 |
| 낮 | 9–17시 | 없음 (기본) |
| 저녁 | 18–21시 | 🌇 노을빛 tint |
| 밤 | 22–23시 | ⭐ 별 |

### 날씨별 반응

| 날씨 WMO 코드 범위 | 조건 | 오버레이 |
|---|---|---|
| 0–1 | 맑음 | 🕶 선글라스 |
| 2–3 | 흐림 | 없음 |
| 51–67, 80–82 | 비 | ☂ 우산 |
| 71–77, 85–86 | 눈 | 🧣 목도리 |
| 기온 < 0°C | 영하 | 🧥 코트 |

시간대와 날씨 반응은 동시에 적용 가능 (예: 새벽 + 비 → 달 + 우산 둘 다).

### 날씨 API

- **Open-Meteo** (무료, API 키 불필요): `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=weathercode,temperature_2m`
- CoreLocation으로 위치 획득 (최초 1회 권한 요청)
- 위치/날씨 30분 캐시 (UserDefaults에 마지막 fetch 시각 저장)
- 위치 권한 거부 시 날씨 반응 비활성화, 시간 반응만 유지

### 오버레이 렌더링

기존 `SlimeView.swift`의 Canvas 드로잉 확장:
- `environmentAccessory: EnvironmentAccessory?` 파라미터 추가
- `EnvironmentAccessory` enum: `moon`, `sun`, `umbrella`, `scarf`, `coat`, `star`
- 각 액세서리는 슬라임 바디 위/옆에 SF Symbol 또는 Text 이모지로 그림
- 사용자 지정 액세서리와 겹치는 경우: 날씨 액세서리를 슬라임 반대편(좌측)에 배치

### 아키텍처

**`CruxPet/EnvironmentModel.swift`** (새 파일)
- `TimeOfDay` enum: `dawn`, `morning`, `daytime`, `evening`, `night`
- `WeatherCondition` enum: `clear`, `cloudy`, `rainy`, `snowy`, `freezing`
- `EnvironmentAccessory` enum: `moon`, `sun`, `umbrella`, `scarf`, `coat`, `star`
- `EnvironmentModel` class (`@Observable`, `@MainActor`):
  - `currentAccessory: EnvironmentAccessory?` (computed from time + weather)
  - `func startUpdating()` — 30분 타이머 + 즉시 1회 fetch
  - CoreLocation delegate 내장
- `static func accessory(for time: TimeOfDay, weather: WeatherCondition?, temp: Double?) -> EnvironmentAccessory?` — 순수 로직, 테스트 가능

**`CruxPet/SlimeView.swift`** 수정
- `var environmentAccessory: EnvironmentAccessory? = nil` 파라미터 추가
- Canvas 내 `drawEnvironmentAccessory()` 함수 추가

**`CruxPet/CruxPetApp.swift`** 수정
- `@State private var environment = EnvironmentModel()`
- `startServices()`에서 `environment.startUpdating()` 호출
- `.environment(environment)` 주입

**`ContentView.swift`** 수정
- `@Environment(EnvironmentModel.self)` 추가
- `SlimeView`에 `environmentAccessory: environment.currentAccessory` 전달

---

## 파일 변경 요약

| 파일 | 변경 |
|---|---|
| `CompanionModel.swift` | 신규 |
| `CompanionSlimeView.swift` | 신규 |
| `EnvironmentModel.swift` | 신규 |
| `ContentView.swift` | companion 표시, environment 주입 |
| `SlimeView.swift` | `environmentAccessory` 파라미터 추가 |
| `CruxPetApp.swift` | `EnvironmentModel` 생성 및 주입 |

---

## 테스트 대상

- `CompanionModel.checkUnlocks` — 각 조건별 유닛 테스트
- `EnvironmentModel.accessory(for:weather:temp:)` — 시간대/날씨 조합 테스트
- WMO 코드 파싱 테스트
