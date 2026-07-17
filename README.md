# Color Rush (컬러 러시)

스트룹 효과 기반의 중독성 반응속도 게임. Flutter로 제작된 Android/iOS 앱 + 마케팅 웹사이트 + 배포 자동화가 한 저장소에 들어 있습니다.

> **게임 규칙**: 화면에 색깔 단어(예: "파랑")가 나타납니다. 단어의 **뜻**과 **글자 색**이 같으면 ✓, 다르면 ✗. 점수가 오를수록 빨라집니다 (2.0초 → 0.85초).

## 수익 모델

| 수단 | 위치 | 정책 |
|---|---|---|
| 배너 광고 | 홈 화면 하단 | 광고 제거 구매 시 숨김 |
| 전면 광고 | 게임 오버 → 나가기/다시하기 | 3회당 1회, 60초 쿨다운 |
| 보상형 광고 | "광고 보고 이어하기" | 판당 1회, 사용자 선택 |
| 인앱결제 | 광고 제거 (`remove_ads`, 비소모성) | 구매 복원 지원 |

GDPR(UMP 동의) + iOS ATT + 광고 개인정보 설정 진입점까지 구현되어 있습니다.

## 폴더 구조

```
app/       Flutter 앱 (게임 + 광고 + 인앱결제)
website/   마케팅 웹사이트 (랜딩 + 개인정보처리방침 + 약관 + 지원)
docs/      ★ 출시 매뉴얼 (여기부터 읽으세요)
scripts/   자동화 스크립트 (Android SDK 설치, 아이콘 생성)
.github/   CI/CD 워크플로 (테스트, Android 릴리즈 빌드, 웹 배포)
```

## 시작하기

**[PLAN.md](PLAN.md)** 가 출시까지의 전체 실행 체크리스트입니다. 상세 절차는 **[docs/00-시작하기.md](docs/00-시작하기.md)** 부터 순서대로 따라가세요.

| # | 문서 | 내용 |
|---|---|---|
| 00 | [시작하기](docs/00-시작하기.md) | 전체 로드맵, 계정 준비 체크리스트 |
| 01 | [개발환경 설정](docs/01-개발환경-설정.md) | Android SDK 자동 설치, 기기 연결 |
| 02 | [앱 실행 및 테스트](docs/02-앱-실행-및-테스트.md) | 로컬 실행, 자동 테스트, APK 빌드 |
| 03 | [앱 커스터마이징](docs/03-앱-커스터마이징.md) | 난이도/색상/문구/아이콘 수정 |
| 04 | [AdMob 설정](docs/04-AdMob-설정.md) | 광고 계정/ID 발급 및 교체 |
| 05 | [인앱결제 설정](docs/05-인앱결제-설정.md) | remove_ads 상품 등록 |
| 06 | [안드로이드 출시](docs/06-안드로이드-출시.md) | 서명 키, Play Console 제출 |
| 07 | [iOS 출시](docs/07-iOS-출시.md) | App Store 제출 (Mac 없이 가능한 경로 포함) |
| 08 | [웹사이트 배포](docs/08-웹사이트-배포.md) | GitHub Pages 자동 배포 |
| 09 | [CI/CD 자동화](docs/09-CI-CD-자동화.md) | 태그 한 번으로 릴리즈 빌드 |
| 10 | [마케팅 자동화](docs/10-마케팅-자동화.md) | ASO, 스토어 자산, app-ads.txt |
| 11 | [문제해결 FAQ](docs/11-문제해결-FAQ.md) | 자주 겪는 오류 모음 |

## 빠른 명령어

```powershell
# 개발환경 준비 (JDK + Android SDK 자동 설치)
powershell -ExecutionPolicy Bypass -File scripts\setup-android.ps1

# 앱 실행 (기기 연결 시)
cd app; flutter run

# 검증 (정적분석 + 테스트)
cd app; flutter analyze; flutter test

# 릴리즈 AAB 빌드 (스토어 업로드용)
cd app; flutter build appbundle --release
```

## 출시 전 반드시 교체할 것 (현재는 전부 테스트 값)

1. **AdMob 광고 단위 ID 6개** → `app/lib/monetization/ad_config.dart`
2. **AdMob 앱 ID 2개** → `app/android/app/src/main/AndroidManifest.xml`, `app/ios/Runner/Info.plist`
3. **웹사이트 TODO** (이메일/개발자명/스토어 링크) → `website/` 내 `<!-- TODO -->` 검색
4. **서명 키 생성** → `docs/06-안드로이드-출시.md` 1장

자세한 방법은 각 매뉴얼에 있습니다.
