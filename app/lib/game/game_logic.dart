import 'dart:math';

/// The six colors used in the game. Pure enum - no Flutter dependency,
/// so game logic stays unit-testable on the Dart VM.
enum GameColor { red, blue, green, yellow, purple, orange }

/// One round: a color WORD (meaning) rendered in an INK color.
/// The player must answer whether meaning == ink.
class StroopRound {
  const StroopRound({required this.word, required this.ink});

  /// The meaning of the displayed word.
  final GameColor word;

  /// The color the word is painted in.
  final GameColor ink;

  bool get isMatch => word == ink;
}

/// Pure game rules: round generation, difficulty curve, answer checking.
class GameLogic {
  GameLogic({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Time allowed for the first round (score 0).
  static const int baseTimeMs = 2000;

  /// Hard floor - the game never gets faster than this.
  static const int minTimeMs = 850;

  /// How much faster each point makes the game.
  static const int stepMs = 30;

  /// Time limit shrinks linearly with score, clamped to [minTimeMs].
  int timeLimitMsForScore(int score) {
    assert(score >= 0);
    return max(minTimeMs, baseTimeMs - score * stepMs);
  }

  /// Generates the next round. Roughly 50% match / 50% mismatch.
  /// A mismatch round is guaranteed to have ink != word.
  StroopRound nextRound() {
    final word = GameColor.values[_random.nextInt(GameColor.values.length)];
    if (_random.nextBool()) {
      return StroopRound(word: word, ink: word);
    }
    final others = GameColor.values.where((c) => c != word).toList();
    final ink = others[_random.nextInt(others.length)];
    return StroopRound(word: word, ink: ink);
  }

  /// [answeredMatch] is true when the player pressed the check (match) button.
  bool isAnswerCorrect(StroopRound round, {required bool answeredMatch}) {
    return round.isMatch == answeredMatch;
  }
}
