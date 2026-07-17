# 11. 문제해결 FAQ

**문서 목적**: 개발 환경 설정부터 배포까지 진행하면서 자주 마주치는 문제와 해결법을 모아둡니다.

✅ **선행 조건**
- [ ] 없음 (문제가 생겼을 때 아무 때나 이 문서로 돌아와도 됩니다)

⏱ **예상 소요 시간**: 필요한 항목만 찾아서 읽으면 5분 이내

---

### Q1. `flutter doctor`에서 "Unable to locate Android SDK" 라고 나와요.

Android SDK가 설치되지 않았거나 Flutter가 SDK 경로를 못 찾는 상태입니다. 프로젝트 루트에서 설치 스크립트를 다시 실행하세요.

```powershell
cd D:\Projects\leeeo-fable
powershell -ExecutionPolicy Bypass -File scripts\setup-android.ps1
```

그래도 안 잡히면 `ANDROID_HOME` 환경 변수가 실제로 설정되었는지 새 PowerShell 창에서 확인하세요.

```powershell
echo $env:ANDROID_HOME
```

값이 비어 있다면 환경 변수가 적용되지 않은 것이니 PowerShell을 완전히 새로 열거나 재부팅 후 다시 확인하세요.

### Q2. `flutter doctor`에서 "Android licenses not accepted" 라고 나와요.

SDK 라이선스에 아직 동의하지 않은 상태입니다. 다음 명령을 실행하고 각 질문에 `y`를 입력하세요.

```powershell
flutter doctor --android-licenses
```

### Q3. 처음 빌드할 때 Gradle이 정말 오래 걸려요. 멈춘 건가요?

**정상입니다.** 첫 빌드는 Gradle 관련 파일과 의존성 수백MB를 새로 내려받기 때문에 인터넷 속도에 따라 5~20분 이상 걸릴 수 있습니다. PowerShell 창에 진행 상황(다운로드 퍼센트 등)이 계속 출력되고 있다면 기다리면 됩니다. 두 번째 빌드부터는 캐시 덕분에 훨씬 빨라집니다.

### Q3-1. 빌드 중에 "Could not close incremental caches" / "this and base files have different roots" 라는 긴 오류 스택이 잔뜩 나와요.

**무시해도 됩니다.** 마지막 줄에 `√ Built build\app\outputs\...` 가 나왔다면 빌드는 성공한 것입니다. 이 경고는 프로젝트가 `D:` 드라이브에 있고 Flutter 패키지 캐시가 `C:` 드라이브에 있을 때 Kotlin 증분 컴파일 캐시가 드라이브 경계를 넘지 못해 생기는 알려진 현상으로, Kotlin이 자동으로 전체 컴파일로 전환해서 빌드 자체는 정상 완료됩니다. 실제로 이 프로젝트의 첫 릴리즈 빌드에서도 같은 경고와 함께 APK/AAB가 정상 생성되었습니다.

### Q3-2. minSdk 값을 낮췄더니 빌드가 실패해요.

`google_mobile_ads`(AdMob) 9.x는 **최소 Android 7.0(API 24)** 을 요구합니다. `app\android\app\build.gradle.kts`의 `minSdk`를 24 미만으로 내리면 manifest merger 오류로 빌드가 실패합니다. 기본값(`flutter.minSdkVersion` = 24)으로 되돌리세요. API 24 미만 기기는 2026년 기준 전 세계 점유율이 극히 낮아 실익도 없습니다.

### Q4. 빌드 중 알 수 없는 오류가 나요.

캐시가 꼬였을 가능성이 높습니다. 다음 순서로 시도하세요.

```powershell
cd D:\Projects\leeeo-fable\app
flutter clean
flutter pub get
flutter run
```

`flutter clean`은 이전 빌드 산출물을 전부 지우고 처음부터 다시 빌드하게 만듭니다. 시간은 더 걸리지만 대부분의 이상한 오류를 해결해줍니다.

### Q5. 광고(테스트 광고)가 안 나와요.

디버그 빌드에서는 항상 Google 공식 테스트 광고가 나와야 정상입니다. 안 나온다면:

- 기기의 인터넷 연결 상태를 확인하세요.
- 새로 만든 AdMob 계정이라면 광고 시스템에 등록/승인되는 데 몇 시간에서 하루 정도 지연이 있는 것이 정상입니다. 시간을 두고 다시 시도하세요.
- 콘솔에 `debugPrint` 로그가 있다면 어떤 에러가 나는지 확인하세요.

### Q6. 실제 광고 ID로 교체했는데 광고가 안 나와요.

- 스토어에 처음 등록한 직후에는 광고가 바로 안 나오는 것이 정상입니다(광고 네트워크 쪽 심사/매칭에 시간이 걸립니다).
- `website\app-ads.txt` 파일이 올바르게 배포되어 있는지, 그리고 스토어 등록정보의 "웹사이트" 항목에 해당 도메인이 입력되어 있는지 확인하세요.
- AdMob 콘솔에서 계정과 앱이 "승인됨" 상태인지 확인하세요. 정책 검토 중이면 광고가 제한적으로만 노출됩니다.

### Q7. 인앱 결제(광고 제거) 상품이 스토어에서 안 보여요.

- 먼저 스토어 콘솔에 `remove_ads` 라는 상품 ID로 상품을 등록하고 **활성화** 상태인지 확인하세요.
- Android는 특히 까다롭습니다. **AAB를 내부 테스트 트랙(또는 그 이상)에 업로드하고, 라이선스 테스터로 본인 계정을 등록한 뒤에만** 실제로 구매 테스트가 가능합니다. 로컬에서 디버그 빌드로 바로 테스트되지 않습니다.
- 앱이 아직 스토어 심사 중이라면 상품 조회 결과가 `null`이거나 목록이 비어 있는 것이 정상입니다. 심사가 끝나고 앱이 게시된 뒤에 다시 확인하세요.

### Q8. Android 업로드 키스토어(.jks)를 잃어버렸어요.

당황하지 않아도 됩니다. Google Play는 **Play App Signing**을 사용하기 때문에, 실제로 앱을 서명하는 최종 서명 키는 Google이 안전하게 보관하고 있습니다. 개발자가 잃어버린 것은 "업로드 키"뿐이라서, Play Console에서 **업로드 키 재설정**을 요청할 수 있습니다(본인 확인 절차가 필요하며 처리에 며칠 걸릴 수 있습니다). 자세한 절차는 Play Console 공식 도움말을 확인하세요: https://support.google.com/googleplay/android-developer/answer/9842756

앞으로를 위해 키스토어 파일과 비밀번호는 비밀번호 관리자나 외장 백업 등 안전한 곳에 반드시 별도 보관하세요.

### Q9. `git push`할 때 인증(로그인) 문제가 계속 생겨요.

GitHub CLI로 인증하는 것이 가장 간단합니다.

```powershell
winget install --id GitHub.cli
gh auth login
```

안내에 따라 브라우저에서 로그인하면 이후 `git push`, `git pull` 등이 별도 비밀번호 입력 없이 동작합니다.

### Q10. GitHub Pages 사이트가 404 Not Found 예요.

**Settings > Pages > Source**가 **"GitHub Actions"**로 설정되어 있는지 확인하세요. 브랜치 직접 선택 방식(예: "Deploy from a branch")으로 되어 있으면 `website-deploy.yml` 워크플로가 배포한 결과와 연결되지 않습니다. 또한 저장소의 **Actions** 탭에서 "Deploy Website" 워크플로가 실제로 성공(초록 체크)했는지도 확인하세요.

### Q11. 앱에서 한국어가 안 나오고 영어로만 보여요.

앱은 기기의 시스템 언어 설정을 따라갑니다. 기기의 **설정 > 일반 > 언어**(또는 이와 유사한 메뉴)에서 한국어가 우선순위 1번으로 설정되어 있는지 확인하세요. 에뮬레이터나 특정 테스트 환경은 기본 로케일이 영어(`en`)로 고정되어 있는 경우가 있습니다(예: 자동 테스트 환경이 그렇습니다. 이는 의도된 정상 동작입니다).

### Q12. `flutter test`가 실패해요. 코드를 안 건드렸는데도요.

- `flutter clean && flutter pub get` 후 다시 실행해보세요. 의존성 캐시 문제일 수 있습니다.
- Flutter 버전이 `3.41.6`과 다르면(특히 더 낮은 버전) 테스트 API 차이로 실패할 수 있습니다. `flutter --version`으로 확인하고, 필요하면 `flutter upgrade` 또는 scoop으로 버전을 맞추세요.
- 특정 테스트 하나만 실패한다면 어떤 단언(assert)이 실패했는지 오류 메시지를 자세히 읽어보세요. 대부분 화면 문구를 03번 문서에서 수정한 뒤 테스트 코드의 기대값을 함께 안 고쳐서 발생합니다.

---

**다음 단계 →** 여기까지 왔다면 문서 세트를 모두 확인한 것입니다. 막히는 부분이 다시 생기면 이 문서로 돌아오거나 [00-시작하기.md](00-시작하기.md)의 로드맵을 다시 확인하세요.
