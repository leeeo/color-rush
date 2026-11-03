# store/ — 스토어 제출용 산출물

계정 없이 미리 만들 수 있는 항목만 담았습니다. Phase 6(Android) / Phase 7(iOS) 제출 시 그대로 사용합니다.

| 파일 | 용도 | 상태 |
|---|---|---|
| `play-listing-ko.md` | Play 한국어 등록정보 (제목/짧은·전체 설명/부가 필드) | 완료 |
| `play-listing-en.md` | Play 영어 등록정보 | 완료 |
| `appstore-listing.md` | App Store 이름·부제·키워드·App Privacy 답안 | 완료 |
| `assets/icon-512.png` | Play 앱 아이콘 512x512 PNG(알파 포함) | 완료 |
| `assets/feature-graphic-1024x500.png` | Play 피처 그래픽 1024x500, 알파 없음 | 완료 |
| `assets/screenshots/{en,ko}-*.png` | Play 휴대폰 스크린샷 4컷 × 2언어 (1080x1920) | 완료 |
| `assets/screenshots/ios67-{en,ko}-*.png` | App Store 6.7" 4컷 × 2언어 (1290x2796) | 완료 |

## 스크린샷

`assets/screenshots/`에 ① 홈, ② 게임 진행 중, ③ 게임 오버, ④ 게임 방법이
한국어·영어로 각각 들어 있습니다. 전부 1080x1920(9:16) 24비트 PNG로 Play 규격
(각 변 320~3840px, 최대 8MB) 안에 있습니다.

실기기/에뮬레이터가 없어 `scripts/capture-store-screenshots.py`로 만들었습니다.
이 스크립트는 앱을 임시 폴더에 복사해 웹으로 빌드한 뒤 헤드리스 Chrome을
360x640 뷰포트·배율 3으로 띄우고, 실제로 12라운드 이상을 플레이해서 캡처합니다
(앱 코드·`app/`은 건드리지 않습니다).

    pip install websockets pillow
    python scripts/capture-store-screenshots.py

폰이 준비되면 실기기 캡처로 교체하는 편이 좋습니다(하단 배너 광고와 실제 상태바가
보이는 화면). 실기기 절차는 [docs/10-마케팅-자동화.md](../docs/10-마케팅-자동화.md) 2장을 참고하세요.

App Store는 기기별 해상도를 요구하므로 6.7인치(1290x2796) 세트는 `ios67-` 접두어로
따로 준비해 두었습니다. 다시 만들려면:

    python scripts/capture-store-screenshots.py --viewport 430x932 --prefix ios67-

## 주의

- 등록정보의 글자 수는 작성 시점 기준으로 제한 내 검증을 마쳤습니다. 문안을 고치면 제한을 다시 확인하세요.
- 스토어 링크(`website/index.html`의 TODO 2곳)는 출시 후 실제 URL로 교체합니다.
