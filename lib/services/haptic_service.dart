import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// Uses light feedback for frequent interactions and stronger feedback for
/// important events.
class HapticService {
  static bool enabled = true;

  /// Subtle timer tick (optional and safe to omit to save battery).
  static void lightTick() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// When pressing timer controls.
  static void buttonPress() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// When a focus session or break completes.
  static void sessionComplete() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// When the daily goal is reached.
  static void goalReached() {
    if (!enabled) return;
    // Double vibration for an extra celebration.
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// When switching between focus and break modes.
  static void modeChange() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// When increasing or decreasing durations in settings.
  static void adjustment() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Error or invalid action, such as going below a minimum.
  static void error() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }
}
