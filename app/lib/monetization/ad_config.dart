import 'package:flutter/foundation.dart';

/// Central place for every AdMob ad-unit ID.
///
/// ══════════════════════════════════════════════════════════════════════
///  ★ 출시 전 반드시 교체하세요! → docs/04-AdMob-설정.md 참고 ★
///
///  AdMob 콘솔에서 발급받은 "실제" 광고 단위 ID로 아래 `_real...` 6개를
///  교체해야 실제 수익이 발생합니다. (형식: ca-app-pub-숫자16자리/숫자10자리)
///
///  안전장치:
///  - 디버그 빌드는 항상 Google 공식 테스트 광고를 사용합니다.
///  - `_real...` 값이 아직 placeholder(X 포함)면 릴리즈에서도 테스트 광고로
///    폴백하여 계정 정지(자기 클릭/무효 트래픽) 위험을 차단합니다.
///
///  ※ AdMob "앱 ID"(~ 물결표 형식)는 이 파일이 아니라
///    android/app/src/main/AndroidManifest.xml 과 ios/Runner/Info.plist 에
///    있습니다. 그것도 함께 교체해야 합니다.
/// ══════════════════════════════════════════════════════════════════════
abstract final class AdConfig {
  // ── 실제 ID (TODO: 교체) ──────────────────────────────────────────────
  static const String _realBannerAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realBannerIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realInterstitialAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realInterstitialIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realRewardedAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realRewardedIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // ── Google 공식 테스트 ID (수정 금지) ────────────────────────────────
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2435281174';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  static String _pick({required String real, required String test}) {
    final notConfigured = real.contains('XXXX');
    return (kDebugMode || notConfigured) ? test : real;
  }

  static String get bannerUnitId => _isAndroid
      ? _pick(real: _realBannerAndroid, test: _testBannerAndroid)
      : _pick(real: _realBannerIos, test: _testBannerIos);

  static String get interstitialUnitId => _isAndroid
      ? _pick(real: _realInterstitialAndroid, test: _testInterstitialAndroid)
      : _pick(real: _realInterstitialIos, test: _testInterstitialIos);

  static String get rewardedUnitId => _isAndroid
      ? _pick(real: _realRewardedAndroid, test: _testRewardedAndroid)
      : _pick(real: _realRewardedIos, test: _testRewardedIos);

  /// Interstitial shown at most once per this interval.
  static const Duration interstitialCooldown = Duration(seconds: 60);

  /// Interstitial shown only every Nth game over.
  static const int interstitialEveryNGameOvers = 3;
}
