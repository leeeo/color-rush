import 'dart:math';

import 'package:colorrush/game/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameLogic.nextRound', () {
    test('mismatch rounds always have ink != word (1000 seeded rounds)', () {
      final logic = GameLogic(random: Random(42));
      for (var i = 0; i < 1000; i++) {
        final r = logic.nextRound();
        if (!r.isMatch) {
          expect(r.ink, isNot(equals(r.word)),
              reason: 'mismatch round must never paint the word in its own color');
        }
      }
    });

    test('produces both match and mismatch rounds in a healthy ratio', () {
      final logic = GameLogic(random: Random(7));
      var matches = 0;
      const n = 2000;
      for (var i = 0; i < n; i++) {
        if (logic.nextRound().isMatch) matches++;
      }
      final ratio = matches / n;
      expect(ratio, greaterThan(0.40));
      expect(ratio, lessThan(0.60));
    });

    test('all six colors appear as words over many rounds', () {
      final logic = GameLogic(random: Random(3));
      final seen = <GameColor>{};
      for (var i = 0; i < 500; i++) {
        seen.add(logic.nextRound().word);
      }
      expect(seen, containsAll(GameColor.values));
    });
  });

  group('GameLogic.timeLimitMsForScore', () {
    final logic = GameLogic(random: Random(1));

    test('starts at base time for score 0', () {
      expect(logic.timeLimitMsForScore(0), GameLogic.baseTimeMs);
    });

    test('is monotonically non-increasing', () {
      for (var s = 0; s < 100; s++) {
        expect(
          logic.timeLimitMsForScore(s + 1),
          lessThanOrEqualTo(logic.timeLimitMsForScore(s)),
        );
      }
    });

    test('never goes below the floor', () {
      expect(logic.timeLimitMsForScore(1000), GameLogic.minTimeMs);
      expect(logic.timeLimitMsForScore(38), greaterThanOrEqualTo(GameLogic.minTimeMs));
    });
  });

  group('GameLogic.isAnswerCorrect', () {
    final logic = GameLogic(random: Random(1));
    const match = StroopRound(word: GameColor.red, ink: GameColor.red);
    const mismatch = StroopRound(word: GameColor.red, ink: GameColor.blue);

    test('truth table', () {
      expect(logic.isAnswerCorrect(match, answeredMatch: true), isTrue);
      expect(logic.isAnswerCorrect(match, answeredMatch: false), isFalse);
      expect(logic.isAnswerCorrect(mismatch, answeredMatch: false), isTrue);
      expect(logic.isAnswerCorrect(mismatch, answeredMatch: true), isFalse);
    });
  });
}
