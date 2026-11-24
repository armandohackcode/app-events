// cspell:ignore armandohackcode
import 'dart:async';

import 'package:flutter/services.dart';

/// Device vibration helpers for GDG SPIN wins, with graceful haptic fallback.
class SpinHaptics {
  static const MethodChannel channel = MethodChannel(
    'dev.armandohackcode.app_events/haptics',
  );

  /// Plays a celebratory vibration pattern when the player wins a prize or bonus.
  static Future<void> celebrateWin({required bool isPrize}) async {
    try {
      await channel.invokeMethod<void>(
        isPrize ? 'playWinPattern' : 'playBonusPulse',
      );
    } on MissingPluginException {
      unawaited(HapticFeedback.heavyImpact());
    } on PlatformException {
      unawaited(HapticFeedback.heavyImpact());
    }
  }
}
