# App Store Connect 등록정보

App Store Connect > 앱 정보 / 버전 정보에 입력합니다. (이름 30 / 부제 30 / 프로모션 텍스트 170 / 키워드 100 / 설명 4000)

## 한국어

| 항목 | 값 |
|---|---|
| 이름 | 컬러 러시 |
| 부제 (17/30) | 0.8초 반응속도 두뇌 트레이닝 |

프로모션 텍스트 (54/170)

```
단어의 뜻과 색이 같은지 0.8초 안에 판단하세요. 오프라인으로 즐기는 무료 반응속도 두뇌 게임.
```

설명 — `play-listing-ko.md`의 전체 설명을 그대로 사용합니다.

## English

| Field | Value |
|---|---|
| Name | Color Rush |
| Subtitle (28/30) | 0.8-second reflex brain test |

Description — reuse the full description from `play-listing-en.md`.

## 키워드 (79/100, 쉼표 구분·공백 없음)

```
reflex,reaction,brain,stroop,color,tap,focus,training,arcade,casual,quick,speed
```

## App Privacy 설문 요약 (코드 기준)

| 질문 | 답 | 근거 |
|---|---|---|
| 데이터 수집 | 예 | Google AdMob SDK |
| 수집 항목 | 식별자(광고 ID), 사용 데이터(광고 상호작용), 진단 | AdMob 기본 수집 |
| 사용자 추적(ATT) | 예 | ATT 권한 요청 구현됨 (`Info.plist` NSUserTrackingUsageDescription) |
| 데이터와 사용자 연결 | 아니요 | 계정·로그인 없음 |

| 기타 | 값 |
|---|---|
| 번들 ID | com.leeeo.colorrush |
| 연령 등급 | 12+ 예상 (설문에서 확정) |
| 인앱 구매 | `remove_ads` (비소모성) — 첫 심사와 함께 제출 |
| 지원 URL | https://leeeo.github.io/color-rush/support.html |
| 개인정보처리방침 URL | https://leeeo.github.io/color-rush/privacy.html |
