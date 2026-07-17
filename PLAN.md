# Color Rush 출시 실행 플랜

개발은 완료된 상태입니다. 이 문서는 **지금부터 스토어 출시와 운영까지** 남은 일을 순서대로 추적하는 체크리스트입니다. 각 단계의 상세 절차는 연결된 매뉴얼(docs/)에 있습니다.

> 사용법: 한 단계씩 진행하며 `[ ]`를 `[x]`로 바꿔 기록하세요. 위에서 아래 순서가 의존성 순서입니다.

---

## 현재 상태 요약

| 영역 | 상태 |
|---|---|
| 게임/광고/IAP 코드 | ✅ 완료 (analyze 0건, 테스트 9/9) |
| Android 빌드 파이프라인 | ✅ 검증됨 (릴리즈 APK 45.9MB / AAB 43.6MB 실빌드 성공) |
| iOS 설정 | ✅ 파일 준비 완료 (빌드는 macOS/CI 필요) |
| 웹사이트 | ✅ 제작 완료 (배포 전, TODO 교체 필요) |
| CI/CD 워크플로 | ✅ 작성 완료 (GitHub push 후 활성화) |
| 실기기 플레이 확인 | ⬜ 미완 (Phase 1) |
| 계정/실제 ID/스토어 등록 | ⬜ 미완 (Phase 2~7) |

---

## Phase 1 — 로컬 검증 (오늘, 약 30분) → [docs/01](docs/01-개발환경-설정.md), [docs/02](docs/02-앱-실행-및-테스트.md)

- [ ] Android 폰 USB 연결 + 개발자 옵션/USB 디버깅 켜기
- [ ] `cd app` → `flutter run` 으로 기기에서 실행
- [ ] 플레이 QA 체크: 게임 루프(시작→정답/오답→게임오버), 점점 빨라지는지, 진동 토글, 한/영 표시
- [ ] 수익화 QA 체크: 홈 하단 **테스트 배너** 노출, 게임오버 3회당 전면 광고, "광고 보고 이어하기" 동작 (전부 "Test Ad" 라벨이어야 정상)
- [ ] `flutter build apk --release` 후 APK 직접 설치 확인 (선택)

## Phase 2 — 계정 준비 (1~2일, 승인 대기 포함) → [docs/00](docs/00-시작하기.md) 4장

- [ ] GitHub 계정 (무료)
- [ ] Google Play Console 개발자 등록 ($25, 1회) + 신원 확인
- [ ] AdMob 계정 생성 (무료)
- [ ] (iOS 출시 시) Apple Developer Program ($99/년)

## Phase 3 — GitHub 업로드 + 웹사이트 배포 (약 30분) → [docs/08](docs/08-웹사이트-배포.md)

⚠️ **스토어 제출보다 먼저** 해야 합니다. 개인정보처리방침 URL이 심사 제출 필수값입니다.

- [ ] `website/` 안의 `<!-- TODO -->` 전부 교체 (이메일, 개발자명, 날짜)
- [ ] GitHub 저장소 생성 → `git add . && git commit && git push`
- [ ] 저장소 Settings > Pages > Source = **GitHub Actions** 설정
- [ ] 배포 확인: `https://<아이디>.github.io/<저장소>/privacy.html` 열림
- [ ] 이 URL을 메모 (Phase 6/7에서 사용)

## Phase 4 — AdMob 실제 ID 발급/교체 (약 1시간 + 승인 대기) → [docs/04](docs/04-AdMob-설정.md)

- [ ] AdMob에 앱 2개(Android/iOS) 등록, 광고 단위 6개 생성 (배너/전면/보상형 × 2)
- [ ] 앱 ID(~) 교체: `app/android/.../AndroidManifest.xml`, `app/ios/Runner/Info.plist`
- [ ] 광고 단위 ID(/) 6개 교체: `app/lib/monetization/ad_config.dart`
- [ ] AdMob 콘솔 > 개인정보보호 및 메시지에서 **GDPR 메시지 게시**
- [ ] `website/app-ads.txt` 생성 + 재배포, 스토어 등록정보에 웹사이트 도메인 입력
- [ ] ⚠️ 절대 자기 광고 클릭 금지 (계정 정지)

## Phase 5 — 인앱결제 상품 등록 (약 1시간) → [docs/05](docs/05-인앱결제-설정.md)

- [ ] Play Console: 판매자 계정 설정 → 인앱 상품 `remove_ads` 생성/활성화 (ID 변경 불가 주의)
- [ ] App Store Connect: 앱 내 추가 항목 `remove_ads` 생성 (첫 심사와 함께 제출)
- [ ] 테스트는 내부 테스트 트랙 업로드 + 라이선스 테스터 등록 후에만 가능함을 인지

## Phase 6 — Android 출시 (반나절 + 심사 수일) → [docs/06](docs/06-안드로이드-출시.md)

- [ ] keytool로 업로드 키스토어 생성 + **안전한 곳에 백업** (분실 = 업데이트 불가)
- [ ] `app/android/key.properties.example` → `key.properties` 복사 후 값 입력
- [ ] `flutter build appbundle --release` → AAB 생성 확인
- [ ] Play Console 앱 생성 → 설정 마법사(광고 있음, 콘텐츠 등급, 타겟 13세+, 데이터 보안 양식)
- [ ] 개인정보처리방침 URL 입력 (Phase 3의 URL)
- [ ] 스토어 등록정보(설명/아이콘 512px/그래픽 1024x500/스크린샷 2장+)
- [ ] 내부 테스트 트랙 업로드 → 직접 설치 확인 → IAP 실테스트
- [ ] ⚠️ 신규 개인 계정 비공개 테스트 요건(테스터/기간) 해당 여부 확인
- [ ] 프로덕션 제출 → 심사 통과

## Phase 7 — iOS 출시 (반나절 + 심사 1~2일) → [docs/07](docs/07-iOS-출시.md)

- [ ] 경로 선택: Mac 보유(로컬 Xcode) / **Mac 없음 → Codemagic 권장** (월 500분 무료)
- [ ] 번들 ID `com.leeeo.colorrush` 등록 → App Store Connect 앱 생성
- [ ] App Privacy 설문 (광고 ID 수집=예, 추적=예 — ATT 구현됨)
- [ ] 스크린샷 준비 → TestFlight 내부 테스트 → IAP 동반 제출 → 심사

## Phase 8 — 릴리즈 자동화 활성화 (약 1시간) → [docs/09](docs/09-CI-CD-자동화.md)

- [ ] GitHub Secrets 4개 등록: `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
- [ ] 테스트: `git tag v1.0.1 && git push origin v1.0.1` → Actions에서 AAB 아티팩트 다운로드 확인
- [ ] (선택, 첫 수동 출시 후) `android-release.yml` 주석 해제 + `PLAY_SERVICE_ACCOUNT_JSON` 등록 → Play 자동 업로드

## Phase 9 — 출시 후 운영 → [docs/10](docs/10-마케팅-자동화.md)

- [ ] ASO 키워드 반영, 커뮤니티 공유 (문서 내 템플릿)
- [ ] AdMob 수익/eCPM 모니터링, 지급 정보(기준 $100) 설정
- [ ] 업데이트 절차 습관화: `pubspec.yaml` version의 `+빌드번호` 올리기 → 태그 push → AAB 업로드
- [ ] 리뷰 대응, (선택) Firebase Analytics 추가 검토

---

## 절대 잊으면 안 되는 것 3가지

1. **키스토어(.jks)와 비밀번호 백업** — 분실하면 앱 업데이트가 막힙니다.
2. **광고 ID 교체 없이 출시하면 수익이 0원** — 안전장치가 테스트 광고로 폴백시킵니다 (`ad_config.dart`).
3. **자기 광고 클릭 금지** — AdMob 계정 영구 정지 사유입니다.

문제 발생 시 → [docs/11-문제해결-FAQ.md](docs/11-문제해결-FAQ.md)
