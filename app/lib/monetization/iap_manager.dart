import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/prefs.dart';
import 'ad_config.dart';
import 'ads_manager.dart';

enum IapMessage { purchased, failed }

/// Handles the single "remove_ads" non-consumable product.
///
/// 스토어 상품 등록 방법 → docs/05-인앱결제-설정.md
/// 상품 ID는 Google Play / App Store Connect 양쪽 모두 `remove_ads` 로
/// 동일하게 등록해야 합니다.
class IapManager extends ChangeNotifier {
  IapManager._();

  static final IapManager instance = IapManager._();

  static const String removeAdsId = 'remove_ads';

  final StreamController<IapMessage> _messages =
      StreamController<IapMessage>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;
  ProductDetails? _product;
  bool _pending = false;

  /// User-facing purchase events (for SnackBars).
  Stream<IapMessage> get messages => _messages.stream;

  bool get storeAvailable => _available;

  bool get purchasePending => _pending;

  /// Localized price straight from the store, e.g. "₩2,500".
  String? get priceLabel => _product?.price;

  bool get canBuy =>
      AdConfig.adsEnabled && _available && _product != null && !Prefs.adsRemoved;

  bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Call once after the first frame. Never throws.
  Future<void> init() async {
    if (!AdConfig.adsEnabled || !_platformSupported) return;
    try {
      _available = await InAppPurchase.instance.isAvailable();
      if (!_available) {
        notifyListeners();
        return;
      }
      // Subscribe BEFORE querying, so pending purchases are never missed.
      _sub = InAppPurchase.instance.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object e) {
          debugPrint('purchaseStream error: $e');
          _pending = false;
          notifyListeners();
        },
      );
      final resp =
          await InAppPurchase.instance.queryProductDetails({removeAdsId});
      if (resp.productDetails.isNotEmpty) {
        _product = resp.productDetails.first;
      } else {
        debugPrint('IAP product not found: ${resp.notFoundIDs} '
            '(스토어 콘솔에 remove_ads 상품을 등록했는지 확인하세요)');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('IapManager.init failed: $e');
    }
  }

  Future<void> buyRemoveAds() async {
    final product = _product;
    if (!canBuy || product == null || _pending) return;
    _pending = true;
    notifyListeners();
    try {
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      debugPrint('buyNonConsumable failed: $e');
      _pending = false;
      _messages.add(IapMessage.failed);
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!AdConfig.adsEnabled || !_available) return;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _messages.close();
    super.dispose();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _pending = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == removeAdsId && !Prefs.adsRemoved) {
            Prefs.adsRemoved = true;
            AdsManager.instance.onAdsRemoved();
            if (p.status == PurchaseStatus.purchased) {
              _messages.add(IapMessage.purchased);
            }
          }
          _pending = false;
        case PurchaseStatus.error:
          debugPrint('purchase error: ${p.error}');
          _pending = false;
          _messages.add(IapMessage.failed);
        case PurchaseStatus.canceled:
          _pending = false;
      }
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
    notifyListeners();
  }
}
