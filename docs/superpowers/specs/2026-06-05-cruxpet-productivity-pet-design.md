# CruxPet — 생산성 연동 펫 설계

**Date:** 2026-06-05  
**Status:** Approved

---

## 개요

macOS 메뉴바에 상주하는 다마고치 앱. Git 커밋과 내장 포모도로 타이머 완료 시 EXP를 획득하고, 레벨업할수록 슬라임 캐릭터가 진화한다.

---

## 시스템 아키텍처

```
git commit
    └─→ post-commit hook (shell script)
            └─→ ~/.cruxpet/events.json  (이벤트 append)
                        ↑
포모도로 완료                │
    └─→ 앱 내부에서 직접 write ─┘
                        │
                 CruxPet 앱 (EventWatcher가 파일 감시, 2초 폴링)
                        │
                 PetModel (EXP·레벨 계산)
                        │
                 UserDefaults (펫 상태 영속 저장)
```

**이유:** 파일 기반이 가장 단순하고, 앱이 꺼져 있는 동안 발생한 커밋도 유실 없이 기록된다.

---

## EXP 시스템

### 레벨업 필요 EXP

```
필요EXP(N → N+1) = floor(100 × N^1.5)
```

| 레벨 | 필요 EXP |
|------|---------|
| 1→2 | 100 |
| 2→3 | 283 |
| 5→6 | 559 |
| 10→11 | 3,162 |
| 20→21 | 17,889 |
| 50→51 | 353,553 |
| 100→101 | 계속 증가 |

레벨 상한 없음. 누적 EXP를 UserDefaults에 저장하며, 레벨은 누적 EXP로부터 역산한다.

### EXP 획득 공식

```
획득EXP = round(base × √level × jitter × critMultiplier)

jitter         = uniform random in [0.8, 1.2]
critMultiplier = 2.0  (10% 확률), 1.0  (90% 확률)
```

| 행동 | base값 | Lv1 기대값 | Lv10 기대값 | Lv50 기대값 |
|------|--------|-----------|------------|------------|
| 💾 git commit | 15 | ~15 | ~47 | ~106 |
| 🍅 포모도로 완료 | 50 | ~50 | ~158 | ~354 |

크리티컬 발생 시 UI에 "💥 CRITICAL!" 텍스트를 0.8초 표시한다.

### 이벤트 파일 포맷

`~/.cruxpet/events.json` — JSON Lines (한 줄에 JSON 객체 하나):

```jsonl
{"type":"commit","timestamp":1780634297}
{"type":"pomodoro","timestamp":1780637000}
```

앱이 읽은 이벤트는 마지막으로 처리한 타임스탬프를 UserDefaults(`cruxpet.lastProcessed`)에 저장해 중복 처리를 방지한다.

---

## 포모도로 타이머

- 기본 25분, 앱 내장
- 상태: `idle → running → paused → completed → idle`
- 완료 시: EXP 지급 + macOS UserNotification 발송 + events.json에 기록
- UI: 타이머 숫자(MM:SS) + 시작/일시정지/리셋 버튼
- 포모도로 진행 중 슬라임 이모지가 🍅로 변경됨

---

## 슬라임 캐릭터

SwiftUI `Canvas` + `TimelineView`로 도트 애니메이션 구현. 프레임마다 위아래로 보빙(bobbing) 애니메이션.

### 진화표

| 레벨 | 색상 | 크기 | 왕관 | 이펙트 |
|------|------|------|------|--------|
| 1–2 | 파랑 `#7EC8E3` | S (24px) | 없음 | 없음 |
| 3–4 | 밝은 파랑 `#4FC3F7` | S (24px) | 없음 | 없음 |
| 5–7 | 초록 `#66BB6A` | M (32px) | 없음 | 없음 |
| 8–9 | 노랑 `#FFEE58` | M (32px) | 없음 | 없음 |
| 10–14 | 주황 `#FFA726` | M (32px) | 🥉 동관 | 없음 |
| 15–19 | 빨강 `#EF5350` | M (32px) | 🥉 동관 | ✦ 1개 |
| 20–24 | 남색 `#7E57C2` | L (40px) | 🥈 은관 | ✦ 2개 |
| 25–29 | 보라 `#AB47BC` | L (40px) | 🥈 은관 | ✦ 3개 |
| 30–39 | 무지개 (7색 순환) | L (40px) | 👑 금관 | ✦ 4개 |
| 40–49 | 무지개 (7색 순환) | XL (48px) | 👑 금관 | ✦✦ 6개 |
| 50–59 | 황금 `#FFD700` | XL (48px) | 💎 다이아관 | ✦✦ 8개 |
| 60–79 | 은빛 `#E0E0E0` | XL (48px) | 💎 다이아관 | ✦✦✦ 10개 |
| 80–99 | 크리스탈 `#F48FB1` | XXL (56px) | 💎 다이아관 | ✦✦✦ + 후광 |
| 100+ | 초월 (무지개+펄) | XXL (56px) | ✨ 성좌관 | 풀 이펙트 |

반짝이(✦)는 슬라임 주변에 랜덤 위치로 배치되며 독립적인 깜빡임 애니메이션을 가진다.

---

## UI 레이아웃

```
┌─────────────────────┐
│   [슬라임 도트 캐릭터]   │  ← SlimeView (Canvas, animated)
│   Lv. 7 · Crux      │
│                     │
│ ⭐ EXP  ████░░░ 420/1000│  ← shimmer 애니메이션
│         Lv.8까지 580  │
│                     │
│ ┌── 🍅 포모도로 ──────┐│
│ │     24:13          ││  ← 모노스페이스 폰트
│ │  [▶ 시작]  [↺]     ││
│ └────────────────────┘│
│                     │
│ 💾 커밋 3회  🍅 2회   │  ← 오늘 활동 요약
└─────────────────────┘
  width: 200px
```

---

## 파일 구조

```
CruxPet/
├── CruxPetApp.swift        기존 (최소 변경)
├── ContentView.swift       UI 재작성
├── PetModel.swift          신규 — EXP, 레벨, 진화 상태 계산
├── SlimeView.swift         신규 — Canvas 도트 캐릭터 렌더링
├── PomodoroTimer.swift     신규 — 타이머 상태 머신
└── EventWatcher.swift      신규 — events.json 폴링 및 파싱

scripts/
└── install-hook.sh         신규 — git global hook 설치
    (~/.config/git/hooks/post-commit 에 설치)
```

---

## Git Hook 설치

`install-hook.sh` 실행 시:

1. `~/.config/git/hooks/` 디렉터리 생성
2. `post-commit` 스크립트 설치 (기존 hook이 있으면 append)
3. `git config --global core.hooksPath ~/.config/git/hooks` 설정
4. `~/.cruxpet/` 디렉터리 생성

`post-commit` 스크립트 내용:

```sh
#!/bin/sh
echo "{\"type\":\"commit\",\"timestamp\":$(date +%s)}" >> ~/.cruxpet/events.json
```

---

## 상태 영속성

| 키 (UserDefaults) | 타입 | 내용 |
|---|---|---|
| `cruxpet.totalExp` | Double | 누적 EXP |
| `cruxpet.lastProcessed` | Double | 마지막으로 처리한 이벤트 타임스탬프 |
| `cruxpet.pomodoroCount` | Int | 오늘 완료한 포모도로 수 |
| `cruxpet.commitCount` | Int | 오늘 커밋 수 |
| `cruxpet.todayDate` | String | "yyyy-MM-dd" — 날짜 바뀌면 일별 카운터 초기화 |
