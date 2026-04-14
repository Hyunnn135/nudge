# 🫱 Nudge (넛지) 앱 프로젝트 마스터보드

> 마지막 업데이트: 2026-04-14

---

## 📊 프로젝트 요약

| 항목 | 내용 |
|------|------|
| 프로젝트명 | Nudge (넛지) — 초미니멀 운동 카운터 |
| 한 줄 요약 | 위젯 탭 1회 = 운동 1회 기록 |
| 운동 종목 | 푸시업, 풀업, 스쿼트 (3개 고정) |
| 기술 스택 | SwiftUI + WidgetKit + App Intents + SwiftData + CloudKit |
| 플랫폼 | iOS 17+ / watchOS |
| 현재 단계 | Phase 0 — 기획 완료, 개발 준비 중 |
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

### Phase 1: 기초 (예상 1주) — ⬜ 대기
- [ ] Xcode 프로젝트 셋업 (iOS 앱 + Widget Extension + watchOS 앱 타겟)
- [ ] App Group 설정 (앱 ↔ 위젯 데이터 공유)
- [ ] SwiftData 모델 정의 (Exercise 열거형 또는 모델, TapRecord)
- [ ] 활성 운동 선택 화면 (iOS)
- [ ] 기본 카운터 화면 (iOS, +1 / -1 취소)

### Phase 2: 위젯 (예상 1~1.5주) — ⬜ 대기
- [ ] Widget Extension 뼈대
- [ ] 소형/중형 위젯 디자인
- [ ] App Intents로 탭 → +1 구현 (Interactive Widget)
- [ ] 위젯 타임라인 갱신 로직 (WidgetCenter.shared.reloadAllTimelines)
- [ ] 잠금 화면 위젯 검증

### Phase 3: Apple Watch (예상 1주) — ⬜ 대기
- [ ] watchOS 앱 기본 화면 (+1 큰 버튼)
- [ ] 컴플리케이션 (워치페이스에 활성 운동 + 오늘 횟수)
- [ ] 워치 ↔ iPhone 동기화 검증 (CloudKit 단독 vs WatchConnectivity 필요성 판단)

### Phase 4: 통계 & 마무리 (예상 1주) — ⬜ 대기
- [ ] 일간 통계 화면
- [ ] 주간 통계 (Swift Charts 스택 바)
- [ ] 월간 통계 (히트맵)
- [ ] 연간 통계 + 평생 누적
- [ ] 폴리싱: 햅틱, 카운트업 애니메이션, 빈 상태 화면
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
| 2026-04-14 | 수익화 로드맵 `MONETIZATION.md` 작성 — v1.0 무광고, v1.1 IAP, v1.2 interstitial |

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

(현재 없음 — 개발 시작 후 업데이트)

---

## 📌 기술 리스크 체크리스트 (개발 시작 전 검증 필요)

- [ ] iOS 17 Interactive Widget이 홈 화면·잠금 화면 모두에서 탭 인터랙션 지원하는지 실기 확인
- [ ] App Group + SwiftData 공유가 문제없이 동작하는지 간단한 프로토타입으로 검증
- [ ] CloudKit만으로 iPhone ↔ Watch 즉시 동기화가 되는지, 지연이 있으면 WatchConnectivity 필요한지 판단
- [ ] 위젯 탭 직후 숫자 업데이트 반영 지연이 얼마나 되는지 (reloadAllTimelines 타이밍)

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
