import 'package:colorrush/core/prefs.dart';
import 'package:colorrush/core/strings.dart';
import 'package:colorrush/game/game_over_overlay.dart';
import 'package:colorrush/main.dart';
import 'package:colorrush/monetization/ad_config.dart';
import 'package:colorrush/monetization/ads_manager.dart';
import 'package:colorrush/monetization/iap_manager.dart';
import 'package:colorrush/widgets/banner_ad_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store extends InAppPurchasePlatform {
  final calls = <String>[];

  @override
  Future<bool> isAvailable() async {
    calls.add('available');
    return true;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    calls.add('query');
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: IapManager.removeAdsId,
          title: 'Remove ads',
          description: '',
          price: 'KRW 2,500',
          rawPrice: 2500,
          currencyCode: 'KRW',
        ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    calls.add('buy');
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    calls.add('restore');
  }
}

void main() {
  testWidgets('compile-time flag gates SDK entry points and monetization UI',
      (tester) async {
    expect(AdConfig.adsEnabled,
        const bool.fromEnvironment('ADS_ENABLED', defaultValue: true));
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    final store = _Store();
    // Construct the facade without registering a native store implementation.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchase.instance;
    InAppPurchasePlatform.instance = store;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final sdkCalls = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    const umpChannel = 'plugins.flutter.io/google_mobile_ads/ump';
    const adsChannel = 'plugins.flutter.io/google_mobile_ads';
    const codec = StandardMethodCodec();
    messenger.setMockMessageHandler(umpChannel, (data) async {
      // Only inspect the method name; consent arguments use the SDK's codec.
      final method =
          const StandardMessageCodec().readValue(ReadBuffer(data!)) as String;
      sdkCalls.add(method);
      return codec.encodeSuccessEnvelope(switch (method) {
        'ConsentInformation#getPrivacyOptionsRequirementStatus' => 1,
        'ConsentInformation#canRequestAds' => true,
        _ => null,
      });
    });
    messenger.setMockMethodCallHandler(const MethodChannel(adsChannel),
        (call) async {
      sdkCalls.add(call.method);
      if (call.method == 'MobileAds#initialize') {
        // Stop at the native boundary without contacting an advertising service.
        throw PlatformException(code: 'test-sdk-unavailable');
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMessageHandler(umpChannel, null);
      messenger.setMockMethodCallHandler(const MethodChannel(adsChannel), null);
    });

    await AdsManager.instance.init();
    await IapManager.instance.init();
    expect(IapManager.instance.canBuy, AdConfig.adsEnabled);
    expect(AdsManager.instance.privacyOptionsRequired, AdConfig.adsEnabled);
    if (AdConfig.adsEnabled) {
      expect(sdkCalls, containsAllInOrder([
        'ConsentInformation#requestConsentInfoUpdate',
        'UserMessagingPlatform#loadAndShowConsentFormIfRequired',
        'ConsentInformation#getPrivacyOptionsRequirementStatus',
        'ConsentInformation#canRequestAds',
        'MobileAds#initialize',
      ]));
      expect(store.calls, ['available', 'query']);
    } else {
      expect(sdkCalls, isEmpty);
      expect(store.calls, isEmpty);
    }

    await tester.pumpWidget(const ColorRushApp());
    await tester.pumpAndSettle();
    final s = S.of(tester.element(find.text('PLAY')));
    expect(find.byTooltip(s.privacySettings),
        AdConfig.adsEnabled ? findsOneWidget : findsNothing);
    expect(find.textContaining(s.removeAds),
        AdConfig.adsEnabled ? findsOneWidget : findsNothing);
    expect(find.text(s.restorePurchase),
        AdConfig.adsEnabled ? findsOneWidget : findsNothing);
    expect(find.byType(BannerAdWidget),
        AdConfig.adsEnabled ? findsOneWidget : findsNothing);

    // Direct calls must also be harmless in disabled builds.
    AdsManager.instance.showPrivacyOptionsForm();
    await IapManager.instance.buyRemoveAds();
    await IapManager.instance.restorePurchases();
    await AdsManager.instance.maybeShowInterstitialOnGameExit();
    var rewarded = false;
    expect(
      await AdsManager.instance.showRewarded(onReward: () => rewarded = true),
      isFalse,
    );
    expect(rewarded, isFalse);
    if (AdConfig.adsEnabled) {
      expect(store.calls, ['available', 'query', 'buy', 'restore']);
      expect(sdkCalls, contains('UserMessagingPlatform#showPrivacyOptionsForm'));
    } else {
      expect(sdkCalls, isEmpty);
      expect(store.calls, isEmpty);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final attCalls = <MethodCall>[];
      const att = MethodChannel('flutter_app_tracking_transparency');
      messenger.setMockMethodCallHandler(att, (call) async {
        attCalls.add(call);
        return 0;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(att, null));
      await AdsManager.instance.init();
      expect(attCalls, isEmpty);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    }

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BannerAdWidget()),
    ));
    await tester.pump();
    expect(tester.getSize(find.byType(BannerAdWidget)), Size.zero);
    expect(tester.takeException(), isNull);
    // Flutter checks foundation globals before addTearDown callbacks run.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('disabled builds never offer an ad-based continuation',
      (tester) async {
    var continued = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GameOverOverlay(
          score: 1,
          best: 1,
          isNewBest: false,
          canContinue: true,
          onContinue: () => continued = true,
          onRetry: () {},
          onHome: () {},
        ),
      ),
    ));
    final s = S.of(tester.element(find.byType(GameOverOverlay)));
    expect(find.text(s.continueWithAd),
        AdConfig.adsEnabled ? findsOneWidget : findsNothing);
    if (AdConfig.adsEnabled) {
      await tester.tap(find.text(s.continueWithAd));
    }
    expect(continued, AdConfig.adsEnabled);
    expect(tester.takeException(), isNull);
  });
}
