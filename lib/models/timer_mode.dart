enum TimerMode {
  pomodoro,
  shortBreak,
  longBreak,
}

extension TimerModeExtension on TimerMode {
  /// Duración por defecto en segundos (se puede sobreescribir en configuración).
  int get defaultDuration {
    switch (this) {
      case TimerMode.pomodoro:
        return 25 * 60;
      case TimerMode.shortBreak:
        return 5 * 60;
      case TimerMode.longBreak:
        return 15 * 60;
    }
  }

  /// Etiqueta en español para mostrar en la UI.
  String get label {
    switch (this) {
      case TimerMode.pomodoro:
        return 'Pomodoro';
      case TimerMode.shortBreak:
        return 'Descanso corto';
      case TimerMode.longBreak:
        return 'Descanso largo';
    }
  }

  /// Etiqueta abreviada para espacios reducidos.
  String get shortLabel {
    switch (this) {
      case TimerMode.pomodoro:
        return 'Foco';
      case TimerMode.shortBreak:
        return 'Descanso';
      case TimerMode.longBreak:
        return 'Pausa larga';
    }
  }

  /// Mensaje que se muestra al completar el modo.
  String get completionMessage {
    switch (this) {
      case TimerMode.pomodoro:
        return '¡Sesión completada! Tómate un descanso.';
      case TimerMode.shortBreak:
        return '¡Descanso terminado! A trabajar.';
      case TimerMode.longBreak:
        return '¡Pausa larga terminada! ¡Sos una máquina!';
    }
  }

  bool get isBreak =>
      this == TimerMode.shortBreak || this == TimerMode.longBreak;
}