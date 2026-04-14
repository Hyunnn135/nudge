# 💰 Nudge — 수익화 로드맵

> 작성일: 2026-04-14 · Phase 0 부록
> 목적: 무료 배포를 전제로 한 Nudge의 광고·IAP 전략을 문서화. 미니멀 정체성을 훼손하지 않으면서 수익화 경로를 확보하는 단계적 계획.

---

## 1. Nudge가 수익화에서 까다로운 이유 (제약 조건)

### 1.1 Apple 정책 — 위젯 내부 광고 금지
- iOS 정책상 WidgetKit 위젯에는 광고를 넣을 수 없다. Apple Review에서 바로 리젝.
- Nudge는 **위젯이 메인 UI**라는 구조 특성상, 광고는 앱 본체로만 한정된다.
- 문제: 사용자가 앱 본체를 거의 안 여는 구조 → banner impression이 일반 앱 대비 1/3~1/5 수준.

### 1.2 짧은 세션 길이
- 들어와서 +1 한 번 누르고 나가는 사용 패턴. 평균 세션 길이 5~10초 예상.
- Interstitial(전면 광고)을 띄울 자연스러운 전환점이 거의 없음. 메인 화면 진입 시 띄우면 "탭 한 번 하려는데 광고" → 별점 1점 테러의 지름길.

### 1.3 미니멀 정체성과의 구조적 충돌
- Nudge의 철학: 계획·목표·알림 다 없애는 앱.
- 하단 배너 하나만 있어도 스토어 스크린샷·첫 인상에서 "그런 앱이구나"의 체감이 확 달라짐.
- 초기 입소문(= "깔끔하다"는 리뷰)이 주 유입 채널이 될 가능성이 높아서, 이 서사를 깨는 결정은 초기일수록 치명적.

### 1.4 iOS ATT(App Tracking Transparency)
- iOS 14.5+부터 추적 거부가 기본값에 가까워, iOS 광고 eCPM이 Android 대비 낮음(특히 소규모 앱).
- Meta Audience Network는 iOS에서 수익 반토막 → 사실상 Google AdMob이 유일한 현실적 선택.

---

## 2. 권장 전략 — Freemium 하이브리드 (단계적 도입)

전체 방침 한 줄: **광고는 최소·최후에, IAP(광고 제거)가 실질 수익원**.

### 2.1 광고 배치 원칙
| 화면 / 컴포넌트 | 광고 허용 여부 | 이유 |
|-----------------|----------------|------|
| 홈스크린 위젯 | ❌ (Apple 금지) | 정책 |
| 잠금화면 위젯 | ❌ (Apple 금지) | 정책 |
| 메인 카운터 화면 | ❌ 금지 | Nudge 정체성의 심장 |
| 운동 선택 화면 | ❌ 금지 | 첫 인상·핵심 UX |
| **통계 화면 진입 시점** | ✅ 허용 (interstitial 1회) | 자연스러운 전환점, 사용 빈도 낮음 |
| 설정 / About | ⚠️ 선택 (배너 가능) | 노출 빈도 낮아 수익 기여도 미미 |

### 2.2 광고 포맷 선택
- **Interstitial (전면)** ✅ 채택 — 통계 화면 진입 시점에 세션당 최대 1회. 빈도 캡 필수.
- **Banner (하단 고정)** ❌ 기각 — 지속 노출로 정체성 훼손 최대.
- **Rewarded Video** ❌ 기각 — "보상 없이 그냥 한다"가 철학. 광고 보면 뱃지/해제 같은 구조 자체가 페르소나 충돌.
- **Native** ❌ 기각 — 메인 UX 영역에 숨기는 방식이라 가장 교활하게 정체성 훼손.

### 2.3 IAP(광고 제거)
- **상품명**: "광고 제거" 또는 "개발자 응원하기"
- **유형**: **일회성 구매 (Non-Consumable)**. 구독은 미니멀 앱과 부정합.
- **가격**: **$2.99 (₩4,400 정도)** — 심리적 저항선 $3.00 바로 아래. 너무 비싸면 구매 전환 하락, 너무 싸면 "이 금액 받자고 광고 넣었나" 느낌.
- **혜택**: 앱 내 모든 광고 영구 제거. 결제 후 `@AppStorage("adsRemoved")`에 true 저장.
- **예상 전환율**: 다운로드 대비 2~3% (미니멀 앱 사용자 특성상 비교적 높을 수 있음).

---

## 3. 3단계 도입 로드맵

### Phase A — v1.0 출시 (광고/IAP 모두 없음)
- 완전 무료, 광고 없음.
- **목표**: 초기 리뷰·별점 확보. "깔끔하다"는 입소문 유도.
- **근거**: 다운로드 0 → 광고 설치해도 수익 거의 0. 대신 광고 없음 = 별점 4.5+ 유지 유리 = 앱 스토어 차트 노출 유리. 장기 ROI가 훨씬 크다.
- **소요**: 추가 개발 0. Phase 1~4 작업만 완주.

### Phase B — v1.1 IAP 먼저 도입 (DAU 500~1000 도달 시)
- 광고는 아직 없음. **"개발자 응원하기" 포지셔닝의 IAP만 추가**.
- 설정 화면 상단에 "개발자 응원하기 · $2.99" 카드 1개. 누르면 StoreKit 결제.
- **이유**: 광고 없는 상태에서 IAP만 풀면 "광고 빼주는 구매"가 아닌 "순수 응원 구매"가 되어 심리적 저항이 낮고 브랜드 호감도 상승.
- **예상 수익**: DAU 1000 기준 월 5~15만원 수준 (전환 2%, 평균 $2.99 * 80% Apple 수수료 제외).
- **기술 작업**:
  - StoreKit 2 (iOS 15+) 통합
  - Product ID 설계: `site.salarykorea.nudge.supporter`
  - Receipt validation (Apple 서버 검증)
  - `@AppStorage`로 구매 상태 로컬 캐싱
  - App Store Connect에 In-App Purchase 등록 + 심사

### Phase C — v1.2 광고 추가 (DAU 2000+ 또는 v1.1 출시 후 2~3개월)
- 통계 화면 진입 시 interstitial 1회 도입.
- v1.1에서 IAP 구매한 사용자는 광고 건너뛰기(기존 `adsRemoved` 플래그 재사용).
- **이유**: 구매 동기 부여 가능. "응원해주시는 분은 광고도 없이"의 서사가 성립.
- **광고 빈도 캡**: 
  - 하루 최대 1회
  - 앱 설치 후 3일은 광고 없음 (onboarding 보호)
  - 통계 화면을 하루에 여러 번 들어가도 광고는 세션당 최대 1회
- **기술 작업**:
  - Google Mobile Ads SDK 통합 (SPM)
  - `GADInterstitialAd` 로드·표시 코드
  - 빈도 캡 로컬 로직
  - App Tracking Transparency 프롬프트 (이미 필수)

---

## 4. 기술 구현 체크리스트 (Phase C에서 참고용)

### 4.1 AdMob 준비
- [ ] Google AdMob 계정 개설 ([admob.google.com](https://admob.google.com))
- [ ] 앱 등록 → App ID 발급 (`ca-app-pub-xxxxx~yyyyy`)
- [ ] Ad Unit ID 발급 (Interstitial용, `ca-app-pub-xxxxx/zzzzz`)
- [ ] 테스트용 Ad Unit ID 확보 (개발 중 실 광고 클릭 금지 — 계정 밴 사유)

### 4.2 Xcode 세팅
- [ ] SPM: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
- [ ] `Info.plist`에 추가:
  ```xml
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-xxxxx~yyyyy</string>
  <key>SKAdNetworkItems</key>
  <array><!-- Apple이 요구하는 SKAdNetwork ID 50개+ --></array>
  <key>NSUserTrackingUsageDescription</key>
  <string>광고 개인화를 위해 기기 식별자를 사용해도 될까요? 거부해도 앱 기능엔 영향 없어요.</string>
  ```
- [ ] SKAdNetworkItems 최신 리스트는 Google AdMob 문서에서 복붙 (50+개)

### 4.3 App Tracking Transparency (iOS 14.5+)
- [ ] `AppTrackingTransparency` 프레임워크 import
- [ ] 첫 실행 시(또는 광고 처음 로드하기 직전) `ATTrackingManager.requestTrackingAuthorization` 호출
- [ ] 거부 시에도 앱 기능 100% 동작해야 함(Apple 리젝 사유)

### 4.4 SwiftUI 통합 패턴
```swift
// GoogleMobileAds는 UIKit 기반 → UIViewControllerRepresentable로 래핑
final class InterstitialAdManager: NSObject, ObservableObject {
    private var interstitial: GADInterstitialAd?
    
    func load() { /* GADInterstitialAd.load(...) */ }
    func present(from root: UIViewController) { /* interstitial?.present(...) */ }
}

struct StatsView: View {
    @StateObject private var adManager = InterstitialAdManager()
    @AppStorage("adsRemoved") var adsRemoved = false
    
    var body: some View {
        // ... 통계 UI ...
        .onAppear {
            if !adsRemoved { adManager.present(from: UIApplication.shared.rootVC) }
        }
    }
}
```

### 4.5 StoreKit 2 IAP 구현 포인트 (Phase B)
- `Product.products(for:)` → 상품 정보 로드
- `product.purchase()` → 구매 요청
- `Transaction.updates` 리스너로 업데이트 수신
- `Transaction.currentEntitlements` 로 구매 이력 확인 (재설치 시 복원)

---

## 5. 수익 기대치 (현실 체크)

| 단계 | 다운로드 | DAU | 월 예상 수익 | 비고 |
|------|---------|-----|--------------|------|
| Phase A (광고·IAP 없음) | 0~1,000 | 0~200 | 0원 | 리뷰 축적 단계 |
| Phase B (IAP만) | 1,000~5,000 | 200~1,000 | 3~15만원 | 구매 전환율 2% 가정 |
| Phase C (IAP+광고) | 5,000~20,000 | 1,000~3,000 | 10~40만원 | iOS eCPM 낮은 점 반영 |
| 그 이상 | 20,000+ | 3,000+ | 40만원 이상 | 추가 iOS 앱 포트폴리오 필요 |

**냉정한 판단**: Nudge만으로 생활비는 안 나온다. Nudge의 본질적 가치는 **맥스아웃과의 포트폴리오 조합** + **"앱 개발자 현태"의 서사 강화**에 있다. 수익화는 부차 목표로 두고, 정체성 보호를 최우선으로.

---

## 6. 최종 결정 (2026-04-14)

- **Phase A(v1.0 출시)까지 광고·IAP 모두 없음**으로 확정.
- IAP는 v1.1에서 "개발자 응원하기" 방식으로 먼저, 광고는 v1.2에서 통계 화면 interstitial로 최소 도입.
- 위젯/메인 카운터/운동 선택 화면엔 영구히 광고 금지.
- 본 문서를 기준 삼아 Phase 1 Xcode 진행 시 광고 관련 분기 처리는 **설계하되 구현은 미루는** 방식으로 코드를 준비(예: `@AppStorage("adsRemoved")` 플래그는 v1.0에서도 심어두고 항상 true로 고정해두면 v1.2 배포 시 플래그 값만 열면 됨).

---

## 7. 관련 자료

- [Google AdMob iOS SDK 문서](https://developers.google.com/admob/ios/quick-start)
- [Apple StoreKit 2 WWDC 2021](https://developer.apple.com/videos/play/wwdc2021/10114/)
- [App Tracking Transparency 가이드](https://developer.apple.com/documentation/apptrackingtransparency)
- 비교 참고: 맥스아웃은 동일 개발자 앱이지만 수익화 전략 별도 수립 필요 (푸시 알림·과부하 기록 기능 때문에 광고 배치 지점이 Nudge와 다름).
