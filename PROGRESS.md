# 🫱 Nudge (넛지) 앱 프로젝트 마스터보드

> 마지막 업데이트: 2026-04-22 (Complication NudgeSync 3-copy 정합화 마무리 + Watch ContentView didBecomeActive push 훅 추가 — 실기기 로그 캡처 직전 정리)

---

## 📊 프로젝트 요약

| 항목 | 내용 |
|------|------|
| 프로젝트명 | Nudge (넛지) — 초미니멀 운동 카운터 |
| 한 줄 요약 | 위젯 탭 1회 = 운동 1회 기록 |
| 운동 종목 | 푸시업, 풀업, 스쿼트 (3개 고정) |
| 기술 스택 | SwiftUI + WidgetKit + App Intents + SwiftData + CloudKit |
| 플랫폼 | iOS 17+ / watchOS |
| 현재 단계 | Phase 3 — 컴플리케이션 타겟까지 구현 완료 (실기기 검증 대기) |
| 예상 기간 | 4~5주 |
| 시작일 | 2026-04-14 |

---

## 🚀 진행 현황

### Phase 0: 기획 — ✅ 완료
- [x] 이름 확정 (Nudge / 넛지)
- [x] APP_PLAN.md 작성
- [x] PROJECT_CONTEXT.md 작성
- [x] PROGRESS.md 작성 (이 파일)
- [x] 마스터보드 연동 (project-data.js/json + index.html 카드 + 타임라인)
- [x] devlog 작성
- [x] 아이콘 & 컬러 컨셉 스케치 (`DESIGN.md` + `icon-concepts/` 4종 SVG + preview.html, A안 가결정)

### Phase 1: 기초 (예상 1주) — 🟡 구현 완료 / 검증 중
- [x] Xcode 프로젝트 셋업 (iOS 앱 + Widget Extension + watchOS 앱 타겟)
- [x] Watch 타겟 임시 제외 (iOS nudge 타겟의 Embed Watch Content / 의존성 제거 — Phase 3에서 재활성화)
- [x] App Group 설정 (`group.site.salarykorea.nudge`, iOS + 위젯 entitlements 양쪽)
- [x] Exercise 모델 + SharedStore (App Group UserDefaults 기반, 앱↔위젯 공유)
- [x] 활성 운동 선택 화면 (iOS, 세그먼트 Picker)
- [x] 기본 카운터 화면 (iOS, +1 / -1 취소, 햅틱)
- [ ] 시뮬레이터에서 동작 검증 (+1 / 운동 전환 / 앱 재진입 시 동기화)

### Phase 2: 위젯 (예상 1~1.5주) — 🟢 완료
- [x] Widget Extension 뼈대 (Single = AppIntentConfiguration, Tri = StaticConfiguration)
- [x] 소형(활성 운동 1개 / 꾹 눌러 편집으로 운동 변경) / 중형(3개 병렬) 위젯 분리
- [x] App Intents: `IncrementExerciseIntent`(탭=+1) + `NudgeSingleConfigIntent`(위젯 설정 UI) + `ExerciseChoice` AppEnum
- [x] 자정 리셋 예약 (Timeline policy .after(nextMidnight))
- [x] 카운터 변경 시 WidgetCenter.shared.reloadAllTimelines 호출
- [x] 홈 화면 위젯 실기 검증 (탭 후 숫자 반영 확인 — 시뮬레이터)
- [ ] 잠금 화면 위젯 검증 (실기기 필요)

### Phase 3: Apple Watch (예상 1주) — 🟢 구현 완료 / 실기기 검증 대기
- [x] Watch 타겟 pbxproj 복원 (Embed Watch Content + Dependency 재삽입) + Watch entitlements 파일 생성 & 앱 그룹 연결
- [x] 동기화 전략 결정: **WatchConnectivity 단독** (last-writer-wins, `SharedStore.lastModified` 타임스탬프 비교)
- [x] `SharedStore` 확장: `lastModified`, `touch()`, `syncSnapshot(daysBack:)`, `applyRemoteSnapshot(_:)` (최근 60일만 payload)
- [x] `NudgeSync` WC 레이어 (iOS + Watch 동일 코드 복제) — `WCSessionDelegate`, `updateApplicationContext` 기반
- [x] iOS 측 hook: +1 / −1 / 세그먼트 전환 / 앱 foreground 복귀 / 원격 수신 시 UI 갱신
- [x] watchOS 메인 화면 (+1 큰 버튼, 활성 운동 표시는 iPhone 설정값 읽기만)
- [x] **컴플리케이션 Widget Extension 타겟 추가** (`NudgeWatchComplicationExtension`, watchOS app-extension, Bundle ID `site.salarykorea.nudge.watchkitapp.NudgeWatchComplication`, Watch App이 Embed Foundation Extensions + Target Dependency 로 포함, App Group entitlements 연결, `fileSystemSynchronizedGroups` 방식)
- [x] 컴플리케이션 3종 패밀리 구현: `.accessoryCircular`(아이콘+카운트, 탭=+1), `.accessoryInline`(상단 텍스트, 인라인은 Button 래핑 불가로 앱 열림), `.accessoryRectangular`(3종 운동 카드 각각 +1)
- [x] 컴플리케이션 전용 `NudgeComplicationConfigIntent`(운동 선택 Picker) + `AppIntentConfiguration` + 3종 `recommendations()` 프리셋
- [x] 컴플리케이션 탭 처리: `IncrementExerciseIntent` 실행 시 `SharedStore.increment` → `WidgetCenter.reloadAllTimelines` → `NudgeSync.pushAwaitingActivation`(세션 활성화까지 최대 5초 대기) 로 iPhone 으로 WC push
- [ ] 실기기에서 iPhone ↔ Watch 양방향 동기화 검증 (시뮬로는 WC 제한 있음)
- [ ] 실기기에서 컴플리케이션 3종 패밀리 시계 화면 배치 & 탭 동작 확인

### Phase 4: 통계 & 마무리 (예상 1주) — 🟡 통계 화면 구현 완료
- [x] `RootView` TabView (오늘 / 통계)
- [x] `SharedStore`에 history helper 확장 (`recentDays(_:)`, `counts(on:)`)
- [x] 주간(7일) / 월간(4주) / 연간(12개월) 스택 바 차트 (Swift Charts, 운동별 색 매핑)
- [x] 최근 12주 히트맵 (주간 탭 한정, 월요일 시작 7행 × 12열, 5단계 민트)
- [x] 기간 합계 / 운동별 합계 카드
- [x] 빈 상태 메시지 ("기록이 없어요")
- [x] 앱 아이콘 A안(Ripple Tap) 적용 — light/dark/tinted 3종 1024 PNG
- [ ] 햅틱 실기 확인 (실기기 필요)
- [ ] App Store 메타데이터 준비 (설명, 스크린샷, 키워드)
- [ ] TestFlight 배포

---

## ✅ 완료한 작업

| 날짜 | 작업 내용 |
|------|-----------|
| 2026-04-14 | 이름 브레인스토밍 후 "Nudge / 넛지" 확정 (후보: Onely, Tally, Plusone, Notch) |
| 2026-04-14 | APP_PLAN.md 작성 (기획 의도, MVP 기능, UX 원칙, 기술 스택, Phase 계획) |
| 2026-04-14 | PROJECT_CONTEXT.md + PROGRESS.md 작성 |
| 2026-04-14 | 마스터보드 등록 (project-data.js/json, index.html 카드 + 타임라인) |
| 2026-04-14 | devlog 작성 (2026-04-14-nudge.md) |
| 2026-04-14 | DESIGN.md 작성 + 아이콘 컨셉 4종(SVG) + preview.html. Teal 팔레트 확정, A안(Ripple Tap) 가결정 |
| 2026-04-14 | 핵심 4화면 HTML 시안 작성 (`mockups/screens.html`): 메인 카운터·운동 선택·일간 통계·주간 통계 |
| 2026-04-14 | 시안 확정 + 운동 아이콘 emoji→SVG 라인아트로 교체(푸시업·풀업·스쿼트) |
| 2026-04-14 | 수익화 로드맵 `MONETIZATION.md` v1 작성 — v1.0 무광고, v1.1 IAP, v1.2 interstitial (v2에서 기각) |
| 2026-04-15 | `MONETIZATION.md` v2 전면 개정 — 완전 무료 + $0.99 커피값 팁 1종. 본격 수익화는 맥스아웃 구독제로. 광고·구독·기능 잠금 전부 제거 |
| 2026-04-15 | Xcode DerivedData 디스크 풀 이슈 해결 + 시뮬레이터 기본 빌드 확인 |
| 2026-04-15 | Phase 1 핵심 구현: Watch 타겟 iOS 빌드에서 임시 분리, App Group 양쪽 설정, `Exercise` enum + `SharedStore` (UserDefaults 기반 앱↔위젯 공용), 메인 `ContentView` (Picker + 카운터 + 큰 +1 / -1 취소), 위젯 `StaticConfiguration` + 소형/중형 레이아웃 + `IncrementExerciseIntent` 로 탭=+1 구현 |
| 2026-04-15 | 위젯 설정 UI 추가: `ExerciseChoice: AppEnum` + `NudgeSingleConfigIntent: WidgetConfigurationIntent`. 소형 위젯 = `AppIntentConfiguration`(꾹 눌러 편집으로 운동 선택), 중형 위젯 = `StaticConfiguration` 유지, Bundle에 둘 다 등록 |
| 2026-04-15 | 앱 아이콘 A안(Ripple Tap) 1024 PNG 3종(light/dark/tinted) 생성 + `AppIcon.appiconset/Contents.json` 파일명 연결. 알파 제거 후 RGB 저장 |
| 2026-04-15 | Phase 4 통계 화면 구현: `SharedStore`에 `recentDays(_:)` / `counts(on:)` / `recordedDateRange()` 추가. `StatsView` (주/월/연 스택 바 차트 + 최근 12주 히트맵 + 합계/운동별 카드). `RootView` TabView로 오늘/통계 분리 |
| 2026-04-15 | Phase 3 시작 — Watch 타겟 복원(Embed Watch Content + Dependency 재삽입), `NudgeWatch.entitlements` 생성 & 앱 그룹 연결, `SharedStore` 에 `lastModified` + `syncSnapshot/applyRemoteSnapshot` 추가, `NudgeSync` WC 레이어 (iOS + Watch 동일 코드), Watch 메인 앱 재작성(+1 큰 버튼, iPhone 활성 운동 읽기). 컴플리케이션은 Widget Extension 타겟 신규 추가 필요로 다음 세션 |
| 2026-04-15 | 같은 날 연장 세션에서 **컴플리케이션 Widget Extension 타겟(`NudgeWatchComplicationExtension`) 실제 추가**: watchOS app-extension, Bundle ID `site.salarykorea.nudge.watchkitapp.NudgeWatchComplication`, Watch App 에 Embed + Dependency, App Group entitlements, `fileSystemSynchronizedGroups` 방식. 3종 패밀리(Circular/Inline/Rectangular) 구현, `NudgeComplicationConfigIntent`(운동 선택) + 3종 `recommendations()`, 탭 시 `IncrementExerciseIntent` → `reloadAllTimelines` → `NudgeSync.pushAwaitingActivation`(5초 활성화 대기) 로 iPhone 으로 WC push |
| 2026-04-17 | 문서 정합화 — 이전 세션에서 이미 끝난 컴플리케이션 작업이 PROGRESS/masterboard/devlog 에 반영되지 않은 상태를 발견, Phase 3 상태를 🟡→🟢 로 갱신하고 체크박스 정리. 코드 수정 없음 |
| 2026-04-17 | **NudgeSync 3-copy 드리프트 정합화 + 실기기 진단용 로그 보강** — Watch App `NudgeSync.swift` 가 가장 오래된 버전(5698b, iOS 쪽 `iPhone:recv` appendDebugLog 3줄 누락)이었음. iPhone↔Watch 양방향 동기화 버그 진단을 위해 Watch 쪽 recv 핸들러 3종에 `Watch:recv applicationContext/message/userInfo` appendDebugLog 추가. 추가로 iOS·Watch 양쪽의 `pushLocalChange` 에 `iPhone:push start/OK/FAIL` · `Watch:push start/OK/FAIL` 로그 추가해 outbound 방향도 🐜/🐞 뷰어에서 추적 가능하게 함. 세 파일의 헤더 코멘트를 "3개 타겟" 안내문으로 통일. 컴플리케이션 타겟 `NudgeSync.swift` 는 건드리지 않음(이미 pushAwaitingActivation 전용 로그 보유) |
| 2026-04-17 | **handleRemote WidgetCenter 가드 버그 수정** — 정합화 중 발견한 잠재 버그. iOS/Watch App `NudgeSync.handleRemote` 의 `WidgetCenter.shared.reloadAllTimelines()` 가 `#if os(iOS)` 가드 안에 갇혀 있어 watchOS 에서는 호출 안 됨. 즉 iPhone→Watch 경로에서 Watch App 이 applicationContext 수신해도 컴플리케이션 타임라인이 리프레시 안 되는 구조. 가드 제거 + `import WidgetKit` 을 플랫폼 가드 밖으로 이동(iOS 14+/watchOS 9+ 양쪽 제공) + `handleRemote:reloadAllTimelines changed=true` appendDebugLog 추가해 호출 자체도 관찰 가능하게 함. iPhone→Watch 방향 반영 불능의 유력 원인 중 하나를 선제 제거 |
| 2026-04-22 | **Complication NudgeSync 3-copy 정합화 마무리** — 04-17 커밋 `9528a87` 이 "complication copy has no handleRemote so untouched" 라는 잘못된 전제로 컴플리케이션 타깃을 건드리지 않았음. 실제로는 `NudgeWatchComplication/NudgeSync.swift:180-196` 에 `handleRemote` 가 존재. 이 세션에서 확인 → iOS/Watch 와 동일하게 맞춤: (1) `import WidgetKit` 을 `#if os(iOS)` 가드 밖으로 이동, (2) `handleRemote` 내 `#if os(iOS)` 가드 제거 + `handleRemote:reloadAllTimelines changed=true` appendDebugLog 추가, (3) `didReceiveUserInfo(_:)` 델리게이트 신규 추가(iOS/Watch 와 대칭), (4) `pushLocalChange`·recv 3종에 `Comp:` 접두사 appendDebugLog 심어 디버그 뷰에서 컴플리케이션 경로도 관찰 가능. 3-copy 핵심 로직 `diff` 결과 플랫폼 접두사(`iPhone:`·`Watch:`·`Comp:`)와 의도적 분기만 차이 나고 구조 동일 |
| 2026-04-22 | **Watch ContentView 에 `WKApplication.didBecomeActiveNotification` 훅 추가** — iOS `ContentView` 는 `UIApplication.didBecomeActiveNotification` 으로 포그라운드 복귀 시마다 `refresh()` + `NudgeSync.pushLocalChange()` 호출하지만, Watch `ContentView` 는 대응 훅이 없었음. 컴플리케이션 탭 후 Watch App 포그라운드 복귀 시 iPhone 으로 push 가 누락될 수 있는 경로. watchOS 26.4 대응 `WKApplication.didBecomeActiveNotification` 기반 `onReceive` 추가 — 포그라운드 복귀 = 최신값 반영 + iPhone 푸시. iOS 와 동작 대칭. 양방향 동기화 2차 용의자 제거 |

---

## 💡 아이디어 & 메모

### MVP 이후 고려
- **Live Activity / Dynamic Island**: 운동 세션 중 실시간 표시 (탭 → +1)
- **HealthKit 연동**: 기록을 Apple 건강 앱으로 전달
- **운동 추가 옵션**: 버피, 런지, 플랭크(시간 기반은 별도) — 단 "3개 고정 노출" 원칙 유지
- **맥스아웃 연동**: Nudge로 습관 잡힌 사용자 → 맥스아웃 추천 (크로스 프로모션)
- **월간 "베스트 일" 축하 화면**: 미세한 성취 피드백 (스팸 알림이 아니라 앱 재방문 시 한 번만)

### 디자인 방향 (초안)
- 전체 톤: 부드럽고 여백 많은, 과하지 않은 UI
- 컬러: 맥스아웃(주황 #7c2d12 계열, 강렬)과 대비되게 **민트/세이지 그린** 계열 (차분, 저부담)
- 아이콘: 손가락이 "탁" 치는 제스처 추상화 or 숫자 "+1" 단순 심볼

---

## 🐛 알려진 이슈 & 해결 필요 사항

- [ ] **🔴 최우선 / 실기기 페어에서 iPhone ↔ Watch 스마트스택 컴플리케이션 양방향 동기화 불능** — 증상: 컴플리케이션 탭 → iPhone 에 반영 안 됨, iPhone 에서 +1 → Watch 컴플리케이션/앱에 반영 안 됨. 양방향 다 안 됨. 진단 인프라(🐜 iOS, 🐞 Watch DebugLogView + 2026-04-17 드리프트 정합화로 Watch:recv/push 로그 추가)는 완비. 다음 세션에서 실기기 재현 → 양쪽 로그 캡처 → 실패 스테이지 식별 → 패치 순서로 진행. 용의자: (a) Widget Extension 프로세스 수명이 WCSession 활성화보다 짧아 pushAwaitingActivation 의 5초 대기가 timeout 가능성, (b) iPhone 이 백그라운드 상태에서 delivery 지연·드롭, (c) `applyRemoteSnapshot` 의 `lastModified` 비교에서 equal-or-older 스냅샷이 버려져 UI 새로고침 트리거 미발생.
- [ ] **운동 아이콘 교체 (낮은 우선순위, 추후)** — 현재 SF Symbols(`figure.strengthtraining.traditional`·`figure.pilates`·`figure.cross.training`) 톤이 마음에 안 듦. `Exercise.symbolName` 한 곳 수정 = 앱·위젯·통계 전부 동시 반영. 커스텀 SVG → SF Symbols import(.sfsymbols) 또는 다른 SF Symbol 탐색.

---

## 📌 기술 리스크 체크리스트 (개발 시작 전 검증 필요)

- [x] iOS 17 Interactive Widget이 홈 화면에서 탭 인터랙션 지원하는지 (시뮬에서 확인)
- [ ] 잠금 화면 위젯 탭 동작 (실기기 필요)
- [x] App Group + UserDefaults JSON 공유 정상 동작 (Phase 1 검증 완료)
- [x] 동기화 전략 결정: **WatchConnectivity 단독 (CloudKit 배제)** — last-writer-wins
- [ ] 실기기에서 iPhone ↔ Watch 양방향 WC 동기화 실측 (시뮬에서는 WC 전송 제약 있음)

---

## 🔗 관련 파일

| 항목 | 경로 |
|-----|------|
| GitHub 저장소 | https://github.com/Hyunnn135/nudge.git |
| 마스터 규칙 | `~/Desktop/Projects/WORKFLOW_RULES.md` |
| 앱 기획안 | `~/Desktop/Projects/nudge/APP_PLAN.md` |
| 컨텍스트 (Claude용) | `~/Desktop/Projects/nudge/PROJECT_CONTEXT.md` |
| 진행 상황 (이 파일) | `~/Desktop/Projects/nudge/PROGRESS.md` |
| 디자인 시스템 | `~/Desktop/Projects/nudge/DESIGN.md` |
| 아이콘 컨셉 SVG | `~/Desktop/Projects/nudge/icon-concepts/` (A~D + preview.html) |
| 화면 시안 | `~/Desktop/Projects/nudge/mockups/screens.html` (4화면) |
| 수익화 로드맵 | `~/Desktop/Projects/nudge/MONETIZATION.md` (v1.0~v1.2 3단계) |
| 마스터보드 데이터 | `~/Desktop/Projects/masterboard/project-data.json` |
| devlog | `~/Desktop/Projects/masterboard/devlog/YYYY-MM-DD-nudge.md` |
