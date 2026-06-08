# Daily Quest System — Design Spec

## Goal

매일 자정에 리셋되는 5개의 일일 퀘스트를 제공하고, 완료 시 EXP를 보상으로 지급한다.

## Architecture

- **`QuestModel.swift`** (신규): 퀘스트 타입 정의, 퀘스트 풀, 날짜 시드 기반 일일 퀘스트 생성, 완료 체크, 보상 지급 기록
- **`PetModel.swift`** (수정): `gainQuestExp(_ amount: Int)` 메서드 추가
- **`ContentView.swift`** (수정): expSection과 pomodoroSection 사이에 퀘스트 섹션 추가, 접힘/펼침 토글

## Quest Types

```swift
enum QuestType {
    case commit(Int)           // 오늘 커밋 n회
    case pomodoro(Int)         // 오늘 포모도로 n회
    case combo(Int, Int)       // 커밋 c회 + 포모도로 p회
    case streak(Int)           // n일 이상 연속 활동 중
}
```

## Quest Pool

**쉬움 (3개 선택, +30 EXP each):**
- commit(1): 커밋 1회
- commit(2): 커밋 2회
- pomodoro(1): 포모도로 1회
- pomodoro(2): 포모도로 2회
- combo(1, 1): 커밋 1회 + 포모도로 1회
- streak(3): 3일 이상 연속 활동 중

**어려움 (2개 선택, +80 EXP each):**
- commit(5): 커밋 5회
- pomodoro(3): 포모도로 3회
- combo(3, 1): 커밋 3회 + 포모도로 1회
- combo(2, 2): 커밋 2회 + 포모도로 2회
- streak(7): 7일 이상 연속 활동 중

**올클리어 보너스:** 5개 전부 완료 시 +100 EXP 추가 지급

## Daily Generation

```
seed = hash("yyyy-MM-dd")
easyQuests  = seededShuffle(easyPool,  seed)[0..<3]
hardQuests  = seededShuffle(hardPool,  seed + 1)[0..<2]
dailyQuests = easyQuests + hardQuests
```

- `seededShuffle`: Fisher-Yates 알고리즘, 시드로 결정론적 셔플
- 같은 날 앱을 재시작해도 동일한 5개 퀘스트 보장

## Progress Calculation

별도 저장 없이 `PetModel` 기존 값으로 실시간 계산:

| 타입 | 완료 조건 |
|---|---|
| commit(n) | `todayCommitCount >= n` |
| pomodoro(n) | `todayPomodoroCount >= n` |
| combo(c, p) | `todayCommitCount >= c && todayPomodoroCount >= p` |
| streak(n) | `streakDays >= n` |

## Reward & Dedup

- 완료된 퀘스트 ID 목록을 `UserDefaults["cruxpet.quest.claimedIds"]`에 저장
- 클레임 날짜를 `UserDefaults["cruxpet.quest.claimedDate"]`에 저장
- 날짜가 바뀌면 클레임 목록 자동 초기화
- 올클리어 보너스 지급 여부: `UserDefaults["cruxpet.quest.allClearClaimed"]` (동일 날짜 기준)
- `QuestModel.claimReward(questId:)`: 미지급 상태일 때만 `pet.gainQuestExp()` 호출

## Quest ID

각 퀘스트는 타입 기반 결정론적 ID를 가짐:
- `"commit_1"`, `"pomodoro_3"`, `"combo_2_2"`, `"streak_7"` 등

## UI — ContentView 퀘스트 섹션

**위치:** `expSection` 아래, `pomodoroSection` 위

**접힌 상태:**
```
📋 일일 퀘스트    ✅ 2/5    ›
```

**펼친 상태:**
```
📋 일일 퀘스트    ✅ 2/5    ∨
┌─────────────────────────────┐
│ ☑ 커밋 1회       ████████ +30 EXP │
│ ☑ 포모도로 1회   ████████ +30 EXP │
│ ☐ 커밋 2회       ████░░░░ 1/2    │
│ ☐ 포모도로 3회   ██░░░░░░ 1/3    │
│ ☐ 커밋3+포모1    ░░░░░░░░ 0/3    │
└─────────────────────────────┘
```

- 완료 퀘스트: 초록 체크마크 + "+30 EXP" 텍스트 (흐리게)
- 진행 중: 캡슐 프로그레스 바 + "현재/목표" 숫자
- 올클리어 시: "🎉 오늘 퀘스트 올클리어! +100 EXP" 토스트

## Daily Reset

`QuestModel.refreshIfNeeded()` — 오늘 날짜와 `claimedDate`가 다르면 클레임 목록 초기화.  
`ContentView.onAppear` 또는 앱 포그라운드 진입 시 호출.

## QuestModel Public Interface

```swift
@Observable class QuestModel {
    private(set) var todayQuests: [Quest]       // 오늘 5개 퀘스트
    private(set) var isExpanded: Bool = false   // UI 접힘 상태

    func refreshIfNeeded()                      // 날짜 변경 시 리셋
    func claimCompleted(pet: PetModel)          // 완료된 미지급 퀘스트 일괄 처리
    func toggle()                               // 펼침/접힘 토글
    func progress(for quest: Quest, pet: PetModel) -> (current: Int, total: Int)
    func isCompleted(_ quest: Quest, pet: PetModel) -> Bool
    func isClaimed(_ quest: Quest) -> Bool
}

struct Quest: Identifiable {
    let id: String
    let type: QuestType
    let difficulty: QuestDifficulty  // .easy / .hard
    var expReward: Int { difficulty == .easy ? 30 : 80 }
    var description: String          // "커밋 2회" 등 한국어 설명
}
```
