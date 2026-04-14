# 프로젝트 컨텍스트 — Nudge (넛지) 앱

> ⚠️ **0순위 필독:** `~/Desktop/Projects/WORKFLOW_RULES.md` (모든 프로젝트 공통 마스터 규칙)
> ⚠️ 이 파일은 새로운 대화에서 이 프로젝트를 이어서 작업할 때 반드시 먼저 읽어야 하는 파일입니다.
> Claude가 이 프로젝트 작업 시 항상 인지해야 할 규칙과 컨텍스트를 담고 있습니다.
>
> **읽기 순서:** WORKFLOW_RULES.md → 이 파일(PROJECT_CONTEXT.md) → APP_PLAN.md → PROGRESS.md

---

## 프로젝트 개요

- **한 줄 요약**: 위젯 탭 한 번 = 운동 1회 기록. 초미니멀 운동 카운터 앱.
- **타겟**: 운동할 마음은 있지만 "세트/반복수/스케줄" 같은 부담 때문에 시작 못 하는 사람
- **철학**: 계획·목표·세트 없음. 오직 "방금 한 개 했음"만 기록.
- **운동 종목**: 푸시업, 풀업, 스쿼트 (3개 고정)
- **플랫폼**: iOS (앱 + 위젯) + watchOS
- **기술 스택**: SwiftUI + WidgetKit + App Intents + SwiftData + CloudKit
- **상세 기획**: `APP_PLAN.md` 참조

---

## 🔴 작업 시 반드시 수행해야 할 4가지

### 1. 메인 마스터보드 업데이트 (양방향 연동)
Nudge 작업 완료/추가 시 `~/Desktop/Projects/masterboard/` 의 아래 파일들을 함께 업데이트:
- **project-data.js** — `tasks` 배열에서 Nudge 항목(id: n1~) 의 `done` 값 업데이트, 새 작업 추가
- **project-data.json** — project-data.js와 동일하게 동기화
- **index.html** — Nudge 카드의 진행률(%), Phase 상태, 태그 업데이트

※ 두 데이터 파일(js, json)은 항상 동일한 내용을 유지해야 한다.

### 2. nudge/PROGRESS.md 업데이트
매 작업 세션마다 아래 항목을 반영:
- 완료한 작업 → "✅ 완료한 작업" 테이블에 날짜와 함께 추가
- 새로운 작업 발생 시 → 해당 Phase 체크리스트에 추가
- 새로운 아이디어 → "💡 아이디어 & 메모" 섹션에 추가
- 버그/이슈 발견 → "🐛 알려진 이슈" 테이블에 추가
- 현재 단계(Phase) 상태 업데이트

### 3. 개발일지 작성 (통합 devlog 위치)
매 작업 세션마다 `~/Desktop/Projects/masterboard/devlog/YYYY-MM-DD-nudge.md` 파일 생성
(같은 날 두 번째 세션이면 `-2`, `-3` 추가 — 예: `2026-04-14-nudge-2.md`):
- 오늘 한 일 (구체적으로)
- 결정 사항
- 다음에 할 일
- 문제점/해결 과정 (있으면)
- 느낀 점

> 📌 2026-04-14부터 모든 프로젝트의 devlog는 `masterboard/devlog/`에 통합 보관합니다.
> 자세한 규칙은 `~/Desktop/Projects/WORKFLOW_RULES.md` 5번 항목 참조.

### 4. 이 파일(PROJECT_CONTEXT.md) 업데이트
프로젝트 방향, 규칙, 기술적 결정이 바뀌면 이 파일도 함께 업데이트.

---

## 📂 양방향 연동 구조

```
~/Desktop/Projects/
├── masterboard/
│   ├── index.html                      ← Nudge 카드 포함
│   ├── project-masterboard.html
│   ├── project-data.js                 ← Nudge tasks: n1~
│   ├── project-data.json               ← 동일 동기화
│   └── devlog/
│       └── YYYY-MM-DD-nudge.md         ← Nudge 개발 일지
│
└── nudge/                              ← Nudge 프로젝트 폴더
    ├── APP_PLAN.md                     ← 앱 기획안 (전체 설계)
    ├── PROGRESS.md                     ← 진행 상황 마스터 (마크다운)
    ├── PROJECT_CONTEXT.md              ← 이 파일
    └── (추후) Xcode 프로젝트 폴더
```

**4곳 동시 업데이트 체크리스트 (작업 변경 시):**
1. `nudge/PROGRESS.md`
2. `masterboard/project-data.js`
3. `masterboard/project-data.json`
4. `masterboard/devlog/YYYY-MM-DD-nudge.md`

---

## 핵심 설계 결정 이력

| 날짜 | 결정 | 이유 |
|------|------|------|
| 2026-04-14 | 이름: Nudge / 넛지 확정 | 행동경제학 "넛지"(부담 없는 작은 유도)가 앱 철학과 완벽히 호응. Onely/Tally/Plusone/Notch 후보 중 컨셉 설명력이 가장 강함 |
| 2026-04-14 | 운동 3가지 고정(푸시업/풀업/스쿼트) | 맨몸으로 언제 어디서든 가능한 운동으로 한정 (푸시업=어디서나, 풀업=집에 풀업바, 스쿼트=어디서나) |
| 2026-04-14 | 위젯 중심 UX | 앱을 열어야 기록되는 마찰을 제거. 탭 1회 = +1. iOS 17 Interactive Widget + App Intents 활용 |
| 2026-04-14 | "없는 것" 목록을 기획의 핵심으로 | 목표/세트/스케줄/알림/소셜 전부 제외. 미니멀리즘이 앱의 정체성 |
| 2026-04-14 | 맥스아웃과 대비 관계 확립 | 같은 개발자의 두 앱이 정반대 페르소나를 커버 (Nudge=입문, 맥스아웃=점진적 과부하) |

---

## 현재 상태
- **단계**: Phase 0 — 기획 완료, 개발 준비 중
- **다음 작업**: 아이콘·컬러 컨셉 스케치 → Xcode 프로젝트 셋업 (App Group + 위젯 Extension)
- **마지막 작업일**: 2026-04-14
