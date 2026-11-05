import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/haptics.dart';
import '../core/prefs.dart';
import '../core/strings.dart';
import '../game/game_screen.dart';
import '../monetization/ad_config.dart';
import '../monetization/ads_manager.dart';
import '../monetization/iap_manager.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<IapMessage>? _iapSub;

  @override
  void initState() {
    super.initState();
    _iapSub = IapManager.instance.messages.listen(_onIapMessage);
  }

  void _onIapMessage(IapMessage message) {
    if (!mounted) return;
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (message) {
        IapMessage.purchased => s.purchaseThanks,
        IapMessage.failed => s.purchaseFailed,
      }),
    ));
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  void _play() {
    hapticTap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  void _showHowToPlay() {
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(s.howToPlay),
        content: Text(s.howToPlayBody, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(
              [AdsManager.instance, IapManager.instance]),
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // GDPR: EEA 사용자에게는 동의 재설정 진입점 노출이 필수
                    if (AdsManager.instance.privacyOptionsRequired)
                      IconButton(
                        tooltip: s.privacySettings,
                        onPressed: AdsManager.instance.showPrivacyOptionsForm,
                        icon: const Icon(Icons.privacy_tip_outlined,
                            color: AppColors.textDim),
                      ),
                    IconButton(
                      tooltip: s.haptics,
                      onPressed: () =>
                          setState(() => Prefs.hapticsOn = !Prefs.hapticsOn),
                      icon: Icon(
                        Prefs.hapticsOn
                            ? Icons.vibration
                            : Icons.smartphone_outlined,
                        color: AppColors.textDim,
                      ),
                    ),
                    IconButton(
                      tooltip: s.howToPlay,
                      onPressed: _showHowToPlay,
                      icon: const Icon(Icons.help_outline,
                          color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const _Wordmark(),
              const SizedBox(height: 12),
              Text(
                s.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 14),
              ),
              const SizedBox(height: 40),
              _BestScoreChip(label: s.best, score: Prefs.highScore),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: _play,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.background,
                      textStyle: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(s.play),
                  ),
                ),
              ),
              if (AdConfig.adsEnabled) ...[
                const SizedBox(height: 20),
                _PurchaseRow(s: s),
              ],
              const Spacer(),
              if (AdConfig.adsEnabled) const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const letters = 'COLOR RUSH';
    var colorIndex = 0;
    return Text.rich(
      TextSpan(
        children: [
          for (final ch in letters.split(''))
            TextSpan(
              text: ch,
              style: TextStyle(
                color: ch == ' '
                    ? null
                    : AppColors
                        .wordmark[colorIndex++ % AppColors.wordmark.length],
              ),
            ),
        ],
      ),
      style: const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        height: 1,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _BestScoreChip extends StatelessWidget {
  const _BestScoreChip({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: AppColors.yellow, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label  $score',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.s});

  final S s;

  @override
  Widget build(BuildContext context) {
    final iap = IapManager.instance;
    if (Prefs.adsRemoved) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 16),
          const SizedBox(width: 6),
          Text(s.adsRemoved,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
        ],
      );
    }
    if (!iap.canBuy) return const SizedBox(height: 20);
    final price = iap.priceLabel;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: iap.purchasePending ? null : iap.buyRemoveAds,
          icon: const Icon(Icons.block, size: 16),
          label: Text(
            price == null ? s.removeAds : '${s.removeAds} · $price',
            style: const TextStyle(fontSize: 13),
          ),
          style: TextButton.styleFrom(foregroundColor: AppColors.textDim),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: iap.restorePurchases,
          style: TextButton.styleFrom(foregroundColor: AppColors.textDim),
          child: Text(s.restorePurchase, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
