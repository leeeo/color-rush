import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/prefs.dart';
import 'ad_config.dart';

/// Singleton owning the whole ads lifecycle:
/// UMP (GDPR) consent -> ATT (iOS) -> SDK init -> interstitial/rewarded cache.
///
/// Policy (see docs/04-AdMob-설정.md):
/// - Banner: home screen only, hidden after "remove ads" purchase.
/// - Interstitial: on leaving the game-over screen, every 3rd game over,
///   at most once per 60s. Removed by purchase.
/// - Rewarded ("continue"): always available, user-initiated - NOT removed
///   by the purchase since it grants gameplay value.
class AdsManager extends ChangeNotifier {
  AdsManager._();

  static final AdsManager instance = AdsManager._();

  bool _initialized = false;
  bool _initStarted = false;
  bool _privacyOptionsRequired = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  Timer? _interstitialRetry;
  Timer? _rewardedRetry;

  /// Mobile-only: google_mobile_ads has no web/desktop implementation.
  bool get adsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get initialized => _initialized;

  bool get showBanner => _initialized && !Prefs.adsRemoved;

  bool get isRewardedReady => _initialized && _rewarded != null;

  /// GDPR: whether we must expose a "privacy options" entry point (EEA users
  /// who saw the consent form can change their choice at any time).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Call once after the first frame. Never throws.
  Future<void> init() async {
    if (!adsSupported || _initStarted) return;
    _initStarted = true;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Let the first frame land before showing the ATT system prompt.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
      await _gatherUmpConsent();
      _privacyOptionsRequired =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
      // Per Google guidance: only start requesting ads when consent allows it.
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _initialized = true;
        _loadInterstitial();
        _loadRewarded();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AdsManager.init failed: $e');
    }
  }

  /// Opens the UMP privacy options form (GDPR re-consent).
  void showPrivacyOptionsForm() {
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('Privacy options error: ${error.errorCode} ${error.message}');
      }
    });
  }

  /// GDPR/EEA consent via Google UMP. Outside the EEA this is a no-op that
  /// completes immediately. Errors never block the game.
  Future<void> _gatherUmpConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) {
            debugPrint('UMP form error: ${error.errorCode} ${error.message}');
          }
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) {
        debugPrint('UMP update error: ${error.errorCode} ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
  }

  /// Called by IapManager when "remove ads" is purchased/restored.
  void onAdsRemoved() {
    _interstitial?.dispose();
    _interstitial = null;
    notifyListeners();
  }

  // ── Interstitial ─────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (!_initialized || Prefs.adsRemoved) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _interstitialRetry?.cancel();
          _interstitialRetry =
              Timer(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Shows an interstitial when leaving game over, if policy allows.
  /// Completes after the ad is dismissed (or immediately when skipped).
  Future<void> maybeShowInterstitialOnGameExit() async {
    if (!_initialized || Prefs.adsRemoved) return;
    if (Prefs.gameOverCount % AdConfig.interstitialEveryNGameOvers != 0) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - Prefs.lastInterstitialMs <
        AdConfig.interstitialCooldown.inMilliseconds) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        Prefs.lastInterstitialMs = DateTime.now().millisecondsSinceEpoch;
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }

  // ── Rewarded (continue) ──────────────────────────────────────────────

  void _loadRewarded() {
    if (!_initialized) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          _rewardedRetry?.cancel();
          _rewardedRetry = Timer(const Duration(seconds: 30), _loadRewarded);
          notifyListeners();
        },
      ),
    );
  }

  /// Shows the rewarded ad. Returns true if the user earned the reward.
  /// [onReward] runs AFTER the ad is fully dismissed, so the game never
  /// resumes underneath a fullscreen ad.
  Future<bool> showRewarded({required VoidCallback onReward}) async {
    final ad = _rewarded;
    if (!_initialized || ad == null) return false;
    _rewarded = null;
    notifyListeners();
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show(
      onUserEarnedReward: (adWithoutView, reward) => earned = true,
    );
    await done.future;
    if (earned) onReward();
    return earned;
  }
}
