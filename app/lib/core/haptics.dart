import 'package:flutter/services.dart';

import 'prefs.dart';

/// Haptic feedback helpers that respect the user's setting.
void hapticTap() {
  if (Prefs.hapticsOn) HapticFeedback.lightImpact();
}

void hapticFail() {
  if (Prefs.hapticsOn) HapticFeedback.heavyImpact();
}
