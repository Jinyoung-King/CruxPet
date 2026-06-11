# 스트릭 캘린더 & EXP 배율 Design

**Goal:** 7칸 점 캘린더로 최근 7일 활동을 시각화하고, 스트릭 길수록 EXP 배율을 높여 일일 습관 형성을 강화한다.

**Architecture:** `EventWatcher`가 기존 `events.json`을 재파싱해 날짜별 활동 Set을 반환한다. `PetModel`은 `streakDays`로 배율을 계산해 gain 메서드에 적용한다. ContentView는 배지와 캘린더 두 UI 컴포넌트를 업데이트한다.

**Tech Stack:** Swift, SwiftUI, UserDefaults, `~/.cruxpet/events.json`

---

## 데이터 레이어

### EventWatcher — `activityDays(last:)`

`events.json`의 모든 이벤트를 읽어 날짜별로 집계한다. 기존 `parseLines`를 재사용한다.

```swift
// 반환: "yyyy-MM-dd" 형식 문자열 Set
nonisolated func activityDays(last n: Int) -> Set<String>
```

- `events.json` 전체를 읽어 타임스탬프를 `yyyy-MM-dd`로 변환
- 오늘 포함 최근 n일의 날짜만 필터링해 반환
- 파일 읽기 실패 시 빈 Set 반환

### PetModel — `streakMultiplier`

```swift
var streakMultiplier: Double {
    switch streakDays {
    case 3...6:   return 1.1
    case 7...13:  return 1.2
    case 14...29: return 1.3
    case 30...:   return 1.5
    default:      return 1.0
    }
}
```

`gainCommitExp`, `gainPomodoroExp`에서 `computeGain` 호출 후 배율 적용:

```swift
let multiplied = Int((Double(gained) * streakMultiplier).rounded())
totalExp += Double(multiplied)
```

---

## UI

### 스트릭 배지 (ContentView.streakBadge)

배율이 1.0 초과일 때 뒤에 `×1.2` 텍스트 추가.

```
🔥 7일 연속 ×1.2
```

배율 1.0이면 기존과 동일하게 숫자만 표시.

### 7칸 점 캘린더 (ContentView.streakCalendar)

배지 바로 아래에 위치. 너비 전체를 균등 분할.

```
월  화  수  목  금  토  일
●  ●  ○  ●  ●  ●  ○
```

- 각 칸: 요일 레이블(caption2) + 원 아이콘
- 활동 있는 날: `circle.fill`, `streakColor` 색상
- 활동 없는 날: `circle`, `.tertiary` 색상
- 오늘 칸: 요일 레이블에 `.bold` 적용

`EventWatcher.activityDays(last: 7)` 결과를 `onAppear`와 `onChange(of: pet.todayCommitCount/todayPomodoroCount)`에서 갱신.

---

## 변경 파일

| 파일 | 변경 |
|------|------|
| `EventWatcher.swift` | `activityDays(last:)` 추가 |
| `PetModel.swift` | `streakMultiplier` 프로퍼티 + gain 로직에 배율 적용 |
| `ContentView.swift` | `streakBadge` 배율 텍스트 + `streakCalendar` 컴포넌트 추가 |

---

## 테스트 범위

- `EventWatcher.activityDays`: 오늘 포함 7일, 활동 없는 날, 파일 없는 경우
- `PetModel.streakMultiplier`: 각 구간 경계값 (0, 3, 7, 14, 30일)
- `PetModel.gainCommitExp`: 배율이 EXP에 실제로 반영되는지
