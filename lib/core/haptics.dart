import 'package:flutter/services.dart';

/// Centralized haptic feedback for Tracelet interactions.
abstract final class TraceletHaptics {
  static Future<void> buttonPress() => HapticFeedback.lightImpact();

  static Future<void> buttonLongPress() => HapticFeedback.mediumImpact();

  static Future<void> simultaneousPress() => HapticFeedback.heavyImpact();

  static Future<void> traceDraw() => HapticFeedback.selectionClick();

  static Future<void> messagePlayback() => HapticFeedback.vibrate();
}
