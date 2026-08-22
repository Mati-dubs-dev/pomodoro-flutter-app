import 'package:flutter/services.dart';

/// Servicio centralizado para feedback háptico.
/// Usa HapticFeedback ligero para interacciones frecuentes
/// y medium/heavy para eventos importantes.
class HapticService {
  static bool enabled = true;

  /// Tick sutil durante el timer (opcional, puede omitirse para ahorrar batería)
  static void lightTick() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Al presionar botones de control (start, pause, reset, skip)
  static void buttonPress() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Al completar una sesión o descanso
  static void sessionComplete() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Al alcanzar el objetivo diario (celebración extra)
  static void goalReached() {
    if (!enabled) return;
    // Doble vibración para celebración
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Al cambiar de modo (Pomodoro ↔ Descanso)
  static void modeChange() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Al ajustar duraciones en settings (increment/decrement)
  static void adjustment() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Error o acción inválida (ej: intentar bajar de mínimo)
  static void error() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }
}
