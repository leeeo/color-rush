import 'package:flutter/material.dart';

import '../game/game_logic.dart';

/// Brand palette - keep in sync with website/style.css.
abstract final class AppColors {
  static const Color background = Color(0xFF12131A);
  static const Color surface = Color(0xFF1C1E28);
  static const Color text = Color(0xFFF1F2F6);
  static const Color textDim = Color(0xFF8A8F9E);
  static const Color correct = Color(0xFF2ED573);
  static const Color wrong = Color(0xFFFF4757);

  static const Color red = Color(0xFFFF4757);
  static const Color blue = Color(0xFF3D9BFF);
  static const Color green = Color(0xFF2ED573);
  static const Color yellow = Color(0xFFFFC048);
  static const Color purple = Color(0xFFA55EEA);
  static const Color orange = Color(0xFFFF7F50);

  /// Palette used to color the wordmark letters on the home screen.
  static const List<Color> wordmark = [red, orange, yellow, green, blue, purple];

  static Color of(GameColor c) => switch (c) {
        GameColor.red => red,
        GameColor.blue => blue,
        GameColor.green => green,
        GameColor.yellow => yellow,
        GameColor.purple => purple,
        GameColor.orange => orange,
      };
}
