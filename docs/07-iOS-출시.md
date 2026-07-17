# 07. iOS 출시

> 문서 목적: Apple Developer Program 가입부터 App Store Connect 심사 제출까지, Mac이 있든 없든 Color Rush를 iOS에 출시하는 방법을 안내합니다.

## ✅ 선행 조건

- [ ] **[04-AdMob-설정.md](./04-AdMob-설정.md)**: iOS 앱 ID, 광고 단위 3개(배너/전면/보상형) 교체 완료
- [ ] **[05-인앱결제-설정.md](./05-인앱결제-설정.md)**: App Store Connect `remove_ads` 앱 내 추가 항목 등록, 유료 앱 계약 동의 완료
- [ ] **08번 문서(웹사이트 배포)**: 개인정보처리방침 URL(`privacy.html`)과 지원 URL(`support.html`)이 실제로 열려야 합니다. 이 문서 곳곳에서 이 URL을 요구합니다.
- [ ] Apple ID (신용카드로 $99/년 결제 가능해야 함)
- [ ] ⚠️ **iOS 빌드/업로드는 macOS + Xcode가 필수**입니다. Mac이 없다면 아래 2장의 대안 경로(Codemagic 등)를 사용하세요.

## ⏱ 예상 소요 시간

- 실작업: 2~4시간 (계정 가입, 번들 ID/앱 생성, 빌드, 메타데이터 입력)
- 대기 시간(별도): Apple Developer Program 가입 승인 즉시~48시간, TestFlight 빌드 처리 수십 분~수 시간, 심사 평균 24~48시간(최대 며칠)

---

## 1. Apple Developer Program 가입

1. https://developer.apple.com/programs 에서 **가입(Enroll)** 을 진행합니다.
2. 개인(Individual) 자격으로 가입하면 됩니다. **D-U-N-S 번호는 조직(Organization) 계정에만 필요하며, 개인 가입에는 필요하지 않습니다.**
3. 연회비 **$99**를 결제합니다. 매년 갱신해야 앱이 스토어에 계속 노출됩니다.
4. 신원 확인 절차 후 계정이 활성화되면 App Store Connect(https://appstoreconnect.apple.com)에 접근할 수 있습니다.

---

## 2. 빌드 방법 3가지 중 선택

### (a) Mac을 소유한 경우: 로컬 빌드

1. Mac App Store에서 **Xcode**를 설치합니다 (최신 안정 버전 권장).
2. 프로젝트를 Mac으로 옮기거나 clone한 뒤, 터미널에서:
   ```bash
   cd app
   flutter build ipa
   ```
3. 빌드가 끝나면 `app/build/ios/ipa/` 아래 결과물이 생성됩니다.
4. **서명(코드 사이닝)**: `app/ios/Runner.xcworkspace`를 Xcode로 엽니다(`.xcodeproj`가 아니라 반드시 `.xcworkspace`). 좌측 프로젝트 네비게이터에서 `Runner` 타겟 선택 > **Signing & Capabilities** 탭에서 **Team**을 본인 Apple Developer 계정으로 선택하면 Xcode가 자동으로 인증서/프로비저닝 프로파일을 관리합니다(Automatically manage signing 체크).
5. 업로드는 **Xcode > Product > Archive** 후 Organizer 창에서 **Distribute App**을 선택하거나, 별도 프로그램인 **Transporter**(Mac App Store 무료 앱)로 `.ipa` 파일을 업로드해도 됩니다.

### (b) Mac 없이: Codemagic (Flutter 특화 CI, macOS 월 500분 무료)

[Codemagic](https://codemagic.io)은 Flutter를 위한 CI/CD 서비스로, macOS 빌드 환경을 클라우드로 무료 제공(월 500분)합니다.

1. codemagic.io에 GitHub 계정으로 가입하고, 이 저장소를 연결합니다.
2. **App Store Connect API 키 등록**:
   - App Store Connect > **사용자 및 액세스 > 통합(Integrations) > App Store Connect API** 메뉴에서 팀 키를 생성합니다(이름: 예 `Codemagic`, 액세스: **App Manager**).
   - `.p8` 키 파일은 **생성 직후 딱 한 번만 다운로드**할 수 있습니다. 반드시 그 자리에서 저장하세요. 창을 닫으면 다시 받을 수 없고, 키를 삭제 후 재생성해야 합니다.
   - Issuer ID, Key ID, `.p8` 파일 세 가지를 Codemagic의 **Team settings > Team integrations > Developer Portal > Manage keys** 화면에 등록합니다.
3. Codemagic 워크플로 설정에서:
   - **iOS code signing**: Automatic, 방금 등록한 API 키 선택, Provisioning profile type은 **App Store**, Bundle identifier는 `com.leeeo.colorrush` 입력.
   - **Publishing > App Store Connect**: "Enable App Store Connect publishing" 체크, 같은 API 키 선택, "Submit to TestFlight beta review" 체크(TestFlight로 먼저 검증 권장).
4. GitHub에 push하면 자동으로 macOS 빌드가 실행되고, 성공 시 App Store Connect에 빌드가 자동 업로드됩니다.
5. ⚠️ Watched branch patterns(빌드 트리거 브랜치)를 `*`(모든 브랜치)로 두면 무료 빌드 시간이 빠르게 소진됩니다. `main` 등 특정 브랜치로 좁혀 설정하세요.

### (c) GitHub Actions macOS 러너 (과금 주의)

GitHub Actions도 `runs-on: macos-latest`로 macOS 빌드가 가능하지만, macOS 러너는 **Linux 러너 대비 과금 배율이 훨씬 높습니다** (2026년 기준 약 10배 수준, [GitHub 공식 요금 문서](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions)에서 최신 배율 확인 필요). Private 저장소라면 무료 분수를 순식간에 소진할 수 있으니, 이 프로젝트처럼 Android CI(`android-release.yml`)는 이미 Linux 러너로 구성되어 있고 iOS는 (b) Codemagic처럼 iOS 전용 무료 티어가 있는 서비스를 우선 고려하는 것을 권장합니다. 그래도 GitHub Actions로 직접 구성하고 싶다면, `flutter build ipa` + `xcodebuild -exportArchive` 조합으로 워크플로를 작성하고 서명은 App Store Connect API 키 기반 fastlane match 등을 활용하는 방식이 일반적입니다.

---

## 3. App Store Connect에서 앱 생성

### 3-1. 번들 ID 등록 (먼저 해야 함)

App Store Connect에서 앱을 만들기 전에, **developer.apple.com > Certificates, Identifiers & Profiles > Identifiers**에서 번들 ID를 먼저 등록해야 합니다.

1. **Identifiers > +** 버튼 클릭 > **App IDs** 선택 > **App** 선택
2. Description: `Color Rush` (자유 입력)
3. Bundle ID: **Explicit** 선택 후 `com.leeeo.colorrush` 정확히 입력 (Flutter 프로젝트의 실제 번들 ID와 일치해야 함)
4. Capabilities에서 **In-App Purchase**가 체크되어 있는지 확인합니다 (기본으로 켜져 있는 경우가 많지만 확인 필수).
5. 저장합니다.

### 3-2. App Store Connect에서 앱 생성

**App Store Connect > 나의 앱 > +** 버튼 > **새로운 앱**

1. 플랫폼: iOS
2. 이름: `Color Rush` (App Store에 표시될 이름, 30자 이내)
3. 기본 언어: 한국어
4. 번들 ID: 3-1에서 등록한 `com.leeeo.colorrush` 선택
5. SKU: 임의의 고유 문자열(예: `colorrush001`, 사용자에게 노출되지 않음)

### 3-3. 앱 정보 입력

- **개인정보처리방침 URL**(필수): 08번 문서에서 배포한 `privacy.html` URL
- **지원 URL**: `support.html` URL (예: `https://아이디.github.io/저장소명/support.html`)
- **마케팅 URL**(선택, app-ads.txt 크롤링을 위해 04번 문서에서 설명한 웹사이트 도메인을 넣어도 됩니다)

---

## 4. 앱 개인정보 보호(App Privacy) 설문

**App Store Connect > 앱 선택 > 앱 개인정보 보호(App Privacy)** 메뉴에서 데이터 수집 항목을 신고합니다. Color Rush는 AdMob(광고), ATT(추적 동의)를 사용하므로 다음과 같이 답하는 것이 실제 동작과 일치합니다.

| 데이터 유형 | 수집 여부 | 세부 답변 |
| --- | --- | --- |
| 식별자 > 기기 ID(광고 ID) | 수집함 | **추적 목적으로 사용됨**: 예 (앱에 ATT 프롬프트가 이미 구현되어 있고, `NSUserTrackingUsageDescription`이 Info.plist에 설정되어 있습니다). 사용자가 추적을 거부하면 ATT 정책에 따라 실제로 추적하지 않아야 합니다. |
| 위치 > 대략적 위치 | 수집함(간접) | AdMob이 IP 기반으로 대략적인 위치를 광고 타겟팅에 활용할 수 있습니다. "광고 또는 마케팅" 목적으로 표시하세요. |
| 사용 데이터 > 제품 상호작용 | 상황에 따라 | 앱이 자체적으로 분석 SDK를 추가하지 않았다면 이 항목은 정직하게 "수집 안 함" 또는 AdMob 관련 진단 데이터만 있다고 표시하세요. |

> ⚠️ App Privacy 라벨은 앱의 실제 동작과 반드시 일치해야 합니다(가이드라인 5.1.2 관련 리젝 사유의 대부분이 라벨-실제 동작 불일치입니다). AdMob SDK가 실제로 수집하는 데이터 항목은 [Google의 App Store 개인정보 데이터 매핑 가이드](https://support.google.com/admob/answer/11322747)를 참고해 빠짐없이 반영하세요.

---

## 5. 스크린샷 규격 (2026년 기준)

Apple은 표시 클래스별로 스크린샷을 요구하며, 큰 사이즈를 제출하면 작은 기기용은 자동으로 축소 적용됩니다.

- **iPhone 6.9인치 (필수)**: 1320×2868px, 1290×2796px, 1260×2736px 중 하나 (세로 기준)
- **iPad 13인치** (iPad 지원 시 필수): 2064×2752px 또는 2048×2732px
- 형식: PNG/JPG, 알파 채널(투명도) 없이, 최대 10장까지 등록 가능

⚠️ 이 수치는 Apple이 매년 기기 라인업에 맞춰 조정하므로, 실제 업로드 전 [App Store Connect 공식 스크린샷 규격 문서](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)에서 최신 값을 다시 확인하세요.

---

## 6. 심사 제출 체크리스트

- [ ] **첫 IAP 동반 제출**: `remove_ads` 항목이 이번 앱 버전과 함께 "심사 대기" 상태로 올라가 있는지 확인 (05번 문서 참고)
- [ ] **심사 메모(App Review Information > Notes)** 에 광고가 어디서 노출되는지 간단히 적어두는 것을 권장합니다. 예: `게임오버 화면에서 전면 광고가 노출되며, 하단에 배너 광고가 상시 표시됩니다. 보상형 광고는 사용자가 버튼을 눌렀을 때만 재생됩니다.` 이렇게 적어두면 심사관이 광고 동작을 오해해서 리젝하는 상황을 줄일 수 있습니다.
- [ ] **데모 계정**: 로그인 기능이 없는 앱이므로 데모 계정 입력란은 비워두거나 "로그인 없이 모든 기능 이용 가능"이라고 메모합니다.
- [ ] **TestFlight 내부 테스트**: 프로덕션 제출 전에 TestFlight로 최소 한 번 실기기 테스트를 권장합니다. App Store Connect > TestFlight 탭에서 내부 테스터(계정 소유자 및 팀원, 최대 100명)를 추가하고 빌드를 배포한 뒤 광고/IAP/게임 플레이를 직접 확인하세요.

---

## 7. 심사 기간과 자주 리젝되는 사유

평균 심사 기간은 **24~48시간**이지만, 첫 제출이거나 특이 사항이 있으면 최대 며칠~1개월까지 걸릴 수 있습니다.

| 가이드라인 | 사유 | Color Rush 기준 대응법 |
| --- | --- | --- |
| **4.3 (스팸/반복)** | 이미 스토어에 있는 앱과 지나치게 유사 | 스트룹 게임류가 다수 존재하므로, 스토어 설명/스크린샷에서 이 앱만의 특징(로컬라이즈, UI, 사운드 등)을 명확히 드러내세요. |
| **2.1 (완성도/성능)** | 크래시, 빈 화면, 미완성 기능 | 제출 전 실기기(가능하면 여러 화면 크기)에서 전체 플레이 흐름 + 광고 노출 + 구매 플로우까지 직접 확인. Placeholder 텍스트나 미완성 화면이 남아있지 않은지 확인. |
| **5.1.2 (데이터 수집/개인정보)** | App Privacy 라벨과 실제 동작 불일치, purpose string 모호 | 4장의 App Privacy 답변을 실제 SDK 동작과 일치시키고, `NSUserTrackingUsageDescription` 문구가 목적을 구체적으로 설명하는지 확인(이미 설정되어 있으나 필요 시 더 구체화). |

리젝을 받으면 **Resolution Center**(App Store Connect 내 메시지함)에서 정확한 사유를 확인하고, 메타데이터 수정만으로 해결되는지 먼저 판단한 뒤 재제출하세요.

---

## 8. 수출 규정 (암호화 신고)

`app\ios\Runner\Info.plist`에 이미 다음이 설정되어 있습니다.

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

이 값은 앱이 표준 암호화(HTTPS 등)만 사용하고 별도의 커스텀 강력 암호화를 구현하지 않았다는 뜻이며, 이미 설정되어 있으므로 **심사 제출 시 관련 질문에 별도 서류 없이 자동으로 통과**됩니다. 앱에 새로운 암호화 기능을 직접 추가하지 않는 한 이 설정을 건드릴 필요는 없습니다.

---

## 다음 단계

이 문서로 04~07번 문서를 모두 마쳤습니다. Color Rush가 두 스토어 모두에 출시 준비가 끝났는지 최종 점검하려면 다른 담당 문서(08 웹사이트 배포, 09 CI/CD 자동화)와 함께 전체 체크리스트를 다시 한번 확인하세요.
