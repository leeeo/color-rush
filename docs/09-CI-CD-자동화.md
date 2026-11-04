# 09. CI/CD 자동화

**문서 목적**: GitHub Actions 워크플로 3개를 이해하고, 시크릿을 등록해서 태그 하나로 서명된 릴리즈 빌드가 자동 생성되도록 설정합니다.

✅ **선행 조건**
- [ ] [08-웹사이트-배포.md](08-웹사이트-배포.md) 완료 (GitHub 저장소 push까지 되어 있음)
- [ ] Android 서명 키(업로드 키스토어)가 준비되어 있음 (06번 문서에서 생성)

⏱ **예상 소요 시간**: 20~30분

---

## 1. 준비된 워크플로 3개

`.github\workflows\` 폴더에 아래 3개 파일이 이미 준비되어 있습니다.

| 파일 | 트리거 | 하는 일 |
|---|---|---|
| `ci.yml` | `main` 브랜치 push 또는 PR (단, `app/**` 변경 시에만) | `flutter analyze` + `flutter test` 자동 실행. 코드 품질 게이트 역할 |
| `android-release.yml` | `v` 로 시작하는 태그 push (예: `v1.0.1`), 또는 수동 실행 | 서명된 AAB(스토어 업로드용) + APK(테스트 설치용) 빌드 후 Actions 아티팩트로 업로드 |
| `website-deploy.yml` | `website/**` 변경 시 `main` push | GitHub Pages로 웹사이트 자동 배포 (08번 문서에서 이미 다룸) |

`ci.yml`은 별도 설정 없이 이미 동작합니다. `android-release.yml`을 쓰려면 아래 시크릿 등록이 필요합니다.

## 2. GitHub Secrets 등록하기

Android 릴리즈 빌드는 서명 키 정보를 GitHub Secrets에서 읽어옵니다. 저장소의 **Settings > Secrets and variables > Actions > New repository secret** 에서 아래 4개를 하나씩 등록합니다.

| 시크릿 이름 | 값 |
|---|---|
| `KEYSTORE_BASE64` | 업로드 키스토어(`upload-keystore.jks`) 파일을 base64로 인코딩한 문자열 |
| `STORE_PASSWORD` | 키스토어 비밀번호 |
| `KEY_PASSWORD` | 키 비밀번호 |
| `KEY_ALIAS` | 키 별칭 (보통 `upload`) |

`KEYSTORE_BASE64` 값은 PowerShell로 다음과 같이 만들어서 클립보드에 바로 복사할 수 있습니다.

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("D:\Projects\leeeo-colorrush\app\android\upload-keystore.jks")) | Set-Clipboard
```

이후 GitHub Secrets 입력창에 `Ctrl+V`로 붙여넣으면 됩니다. (키스토어 파일이 아직 없다면 06번 문서에서 먼저 생성하세요.)

> 시크릿 값은 등록 후에는 다시 조회할 수 없습니다(값을 수정하거나 새로 등록만 가능). 키스토어 파일과 비밀번호는 별도로 안전한 곳(비밀번호 관리자 등)에 백업해두세요.

## 3. 릴리즈 절차 (버전 올리고 태그 푸시)

1. **버전 번호를 올립니다.** `app\pubspec.yaml`의 `version:` 줄을 확인합니다.

```yaml
version: 1.0.0+1
```

`+` 뒤의 숫자가 빌드 번호(Android의 versionCode)입니다. **스토어에 업로드할 때마다 이 숫자를 반드시 1씩 증가시켜야 합니다.** 같은 빌드 번호로는 재업로드가 거부됩니다. 예: `1.0.0+1` → `1.0.1+2`.

2. 변경사항을 커밋합니다.

```powershell
cd D:\Projects\leeeo-colorrush
git add app\pubspec.yaml
git commit -m "chore: bump version to 1.0.1+2"
```

3. 버전에 맞는 태그를 만들고 push합니다.

```powershell
git tag v1.0.1
git push origin v1.0.1
```

4. GitHub 저장소의 **Actions** 탭에서 "Android Release" 워크플로가 자동으로 시작됩니다. 완료되면 해당 실행 결과 페이지 하단의 **Artifacts** 영역에서 `colorrush-aab`, `colorrush-apk` 를 다운로드할 수 있습니다.
5. 다운로드한 AAB 파일을 Play Console에 업로드합니다 (자세한 업로드 절차는 06번 문서 참고).

## 4. 첫 출시 이후: Play 스토어 자동 업로드 활성화 (선택)

첫 출시를 **수동으로** 완료한 뒤에는, 태그를 push하는 순간 Play Console 내부 테스트 트랙까지 자동으로 업로드되게 만들 수 있습니다.

1. Google Cloud Console에서 서비스 계정을 만들고, Play Console의 **설정 > API 액세스**에서 이 서비스 계정에 릴리즈 권한을 연결합니다. (Google Play Console 공식 문서: https://support.google.com/googleplay/android-developer/answer/9859152 . 절차는 정책에 따라 바뀔 수 있으니 최신 안내를 확인하세요.)
2. 발급받은 서비스 계정 JSON 키 내용을 `PLAY_SERVICE_ACCOUNT_JSON` 이름으로 GitHub Secrets에 등록합니다.
3. `android-release.yml` 파일 맨 아래에 주석 처리된 "Play 스토어 내부 테스트 트랙 업로드" 단계의 주석(`#`)을 제거합니다.
4. 이후부터는 태그를 push하면 AAB 빌드 + Play 내부 테스트 트랙 업로드까지 자동으로 진행됩니다.

## 5. iOS CI에 대한 참고

iOS 빌드는 macOS 러너에서만 가능합니다. GitHub Actions에서 `runs-on: macos-latest` 로 iOS 빌드 워크플로를 추가할 수는 있지만, **macOS 러너는 Linux 러너보다 분당 비용이 훨씬 비쌉니다.** 무료 티어의 분당 소진 속도도 macOS는 더 빠릅니다(과금 정책은 GitHub 공식 문서 확인: https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners).

비용이 부담된다면 **Codemagic** 을 대안으로 고려하세요. Flutter 전용 CI 서비스로, 개인 계정 기준 매달 macOS 빌드 500분을 무료로 제공합니다. 개인 프로젝트 수준에서는 이 무료 한도로 충분한 경우가 많습니다. (https://codemagic.io)

---

**다음 단계 →** [10-마케팅-자동화.md](10-마케팅-자동화.md)
