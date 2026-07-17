import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../monetization/ad_config.dart';
import '../monetization/ads_manager.dart';

/// Anchored adaptive banner. Owns its own [BannerAd] lifecycle and reserves
/// its final height as soon as the size is known to avoid layout shift.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _loadRequested = false;

  @override
  void initState() {
    super.initState();
    AdsManager.instance.addListener(_onAdsStateChanged);
  }

  /// 광고 제거 구매 직후 배너 리소스를 즉시 해제한다.
  /// (숨김은 build의 showBanner 체크가 처리하고, 여기선 메모리 정리만)
  void _onAdsStateChanged() {
    if (!AdsManager.instance.showBanner && _ad != null) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (_loadRequested || !AdsManager.instance.showBanner) return;
    _loadRequested = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    setState(() => _size = size);
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    AdsManager.instance.removeListener(_onAdsStateChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdsManager.instance,
      builder: (context, _) {
        if (!AdsManager.instance.showBanner) return const SizedBox.shrink();
        _maybeLoad();
        final size = _size;
        final ad = _ad;
        if (size == null) return const SizedBox.shrink();
        return SizedBox(
          width: size.width.toDouble(),
          height: size.height.toDouble(),
          child: (_loaded && ad != null) ? AdWidget(ad: ad) : null,
        );
      },
    );
  }
}
