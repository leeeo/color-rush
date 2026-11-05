import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/strings.dart';
import '../monetization/ad_config.dart';

/// Dimmed panel shown over the game when a run ends.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.best,
    required this.isNewBest,
    required this.canContinue,
    required this.onContinue,
    required this.onRetry,
    required this.onHome,
  });

  final int score;
  final int best;
  final bool isNewBest;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isNewBest ? s.newBest : s.gameOver,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isNewBest ? AppColors.yellow : AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${s.best}  $best',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textDim, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (AdConfig.adsEnabled && canContinue) ...[
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(s.continueWithAd),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.tonal(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(s.retry),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onHome,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.textDim),
                child: Text(s.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
