import 'package:flutter/services.dart';

/// Servicio centralizado para feedback háptico.
/// Usa HapticFeedback ligero para interacciones frecuentes
/// y medium/heavy para eventos importantes.
class HapticService {
  /// Tick sutil durante el timer (opcional, puede omitirse para ahorrar batería)
  static void lightTick() {
    HapticFeedback.lightImpact();
  }

  /// Al presionar botones de control (start, pause, reset, skip)
  static void buttonPress() {
    HapticFeedback.mediumImpact();
  }

  /// Al completar una sesión o descanso
  static void sessionComplete() {
    HapticFeedback.heavyImpact();
  }

  /// Al alcanzar el objetivo diario (celebración extra)
  static void goalReached() {
    // Doble vibración para celebración
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Al cambiar de modo (Pomodoro ↔ Descanso)
  static void modeChange() {
    HapticFeedback.selectionClick();
  }

  /// Al ajustar duraciones en settings (increment/decrement)
  static void adjustment() {
    HapticFeedback.selectionClick();
  }

  /// Error o acción inválida (ej: intentar bajar de mínimo)
  static void error() {
    HapticFeedback.vibrate();
  }
}