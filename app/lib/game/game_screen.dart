import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/haptics.dart';
import '../core/prefs.dart';
import '../core/strings.dart';
import '../monetization/ads_manager.dart';
import 'game_logic.dart';
import 'game_over_overlay.dart';

enum _Phase { ready, playing, dead }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GameLogic _logic = GameLogic();

  late final AnimationController _timer;

  _Phase _phase = _Phase.ready;
  StroopRound _round =
      const StroopRound(word: GameColor.red, ink: GameColor.red);
  int _score = 0;
  int _roundCount = 0;
  bool _continueUsed = false;
  bool _isNewBest = false;
  bool _adInProgress = false;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: GameLogic.baseTimeMs),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onTimeout();
      });
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _start() {
    if (_phase == _Phase.playing) return;
    hapticTap();
    setState(() {
      _phase = _Phase.playing;
      _score = 0;
      _continueUsed = false;
      _isNewBest = false;
    });
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      _round = _logic.nextRound();
      _roundCount++;
    });
    _timer.duration =
        Duration(milliseconds: _logic.timeLimitMsForScore(_score));
    _timer.forward(from: 0);
  }

  void _answer({required bool answeredMatch}) {
    if (_phase != _Phase.playing) return;
    _timer.stop();
    if (_logic.isAnswerCorrect(_round, answeredMatch: answeredMatch)) {
      hapticTap();
      setState(() => _score++);
      _nextRound();
    } else {
      _die();
    }
  }

  void _onTimeout() {
    if (_phase == _Phase.playing) _die();
  }

  void _die() {
    _timer.stop();
    hapticFail();
    final wasBest = _score > 0 && _score > Prefs.highScore;
    if (wasBest) Prefs.highScore = _score;
    Prefs.gameOverCount = Prefs.gameOverCount + 1;
    setState(() {
      _isNewBest = wasBest;
      _phase = _Phase.dead;
    });
  }

  Future<void> _continueWithAd() async {
    if (_adInProgress) return;
    _adInProgress = true;
    final earned = await AdsManager.instance.showRewarded(
      onReward: () {
        if (!mounted) return;
        setState(() {
          _continueUsed = true;
          _phase = _Phase.playing;
        });
        _nextRound();
      },
    );
    _adInProgress = false;
    if (!earned && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).adNotReady)));
    }
  }

  Future<void> _exit({required bool retry}) async {
    if (_adInProgress) return;
    _adInProgress = true;
    await AdsManager.instance.maybeShowInterstitialOnGameExit();
    _adInProgress = false;
    if (!mounted) return;
    if (retry) {
      setState(() => _phase = _Phase.ready);
      _start();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                _Header(score: _score, best: Prefs.highScore, s: s),
                _TimerBar(timer: _timer, active: _phase == _Phase.playing),
                Expanded(
                  child: _phase == _Phase.ready
                      ? _ReadyView(label: s.tapToStart, onTap: _start)
                      : _WordView(round: _round, roundKey: _roundCount, s: s),
                ),
                _AnswerButtons(
                  enabled: _phase == _Phase.playing,
                  matchLabel: s.match,
                  noMatchLabel: s.noMatch,
                  onAnswer: (m) => _answer(answeredMatch: m),
                ),
              ],
            ),
            if (_phase == _Phase.dead)
              ListenableBuilder(
                listenable: AdsManager.instance,
                builder: (context, _) => GameOverOverlay(
                  score: _score,
                  best: Prefs.highScore,
                  isNewBest: _isNewBest,
                  canContinue:
                      !_continueUsed && AdsManager.instance.isRewardedReady,
                  onContinue: _continueWithAd,
                  onRetry: () => _exit(retry: true),
                  onHome: () => _exit(retry: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.score, required this.best, required this.s});

  final int score;
  final int best;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${s.best} $best',
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.timer, required this.active});

  final AnimationController timer;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 8,
          child: AnimatedBuilder(
            animation: timer,
            builder: (context, _) {
              final remaining = active ? (1 - timer.value) : 1.0;
              return Stack(
                children: [
                  Container(color: AppColors.surface),
                  FractionallySizedBox(
                    widthFactor: remaining,
                    heightFactor: 1,
                    child: ColoredBox(
                      color: Color.lerp(
                          AppColors.wrong, AppColors.green, remaining)!,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _WordView extends StatelessWidget {
  const _WordView({required this.round, required this.roundKey, required this.s});

  final StroopRound round;
  final int roundKey;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(roundKey),
        tween: Tween(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Text(
          s.colorName(round.word),
          style: TextStyle(
            color: AppColors.of(round.ink),
            fontSize: 68,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _AnswerButtons extends StatelessWidget {
  const _AnswerButtons({
    required this.enabled,
    required this.matchLabel,
    required this.noMatchLabel,
    required this.onAnswer,
  });

  final bool enabled;
  final String matchLabel;
  final String noMatchLabel;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _AnswerButton(
              icon: Icons.close_rounded,
              label: noMatchLabel,
              color: AppColors.wrong,
              onTap: enabled ? () => onAnswer(false) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnswerButton(
              icon: Icons.check_rounded,
              label: matchLabel,
              color: AppColors.green,
              onTap: enabled ? () => onAnswer(true) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 44),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
