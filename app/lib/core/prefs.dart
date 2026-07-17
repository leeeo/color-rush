import 'package:shared_preferences/shared_preferences.dart';

/// Thin static wrapper over SharedPreferences.
/// Initialized once in main() before runApp.
abstract final class Prefs {
  static const _kHighScore = 'high_score';
  static const _kHaptics = 'haptics_on';
  static const _kAdsRemoved = 'ads_removed';
  static const _kGameOverCount = 'game_over_count';
  static const _kLastInterstitialMs = 'last_interstitial_ms';

  static late SharedPreferences _sp;

  static Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
  }

  static int get highScore => _sp.getInt(_kHighScore) ?? 0;
  static set highScore(int v) => _sp.setInt(_kHighScore, v);

  static bool get hapticsOn => _sp.getBool(_kHaptics) ?? true;
  static set hapticsOn(bool v) => _sp.setBool(_kHaptics, v);

  static bool get adsRemoved => _sp.getBool(_kAdsRemoved) ?? false;
  static set adsRemoved(bool v) => _sp.setBool(_kAdsRemoved, v);

  static int get gameOverCount => _sp.getInt(_kGameOverCount) ?? 0;
  static set gameOverCount(int v) => _sp.setInt(_kGameOverCount, v);

  static int get lastInterstitialMs => _sp.getInt(_kLastInterstitialMs) ?? 0;
  static set lastInterstitialMs(int v) => _sp.setInt(_kLastInterstitialMs, v);
}
