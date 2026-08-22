enum TimerMode { pomodoro, shortBreak, longBreak }

extension TimerModeExtension on TimerMode {
  /// Default duration in seconds (can be overridden in settings).
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

  /// User-facing label.
  String get label {
    switch (this) {
      case TimerMode.pomodoro:
        return 'Pomodoro';
      case TimerMode.shortBreak:
        return 'Short break';
      case TimerMode.longBreak:
        return 'Long break';
    }
  }

  /// Abbreviated label for compact layouts.
  String get shortLabel {
    switch (this) {
      case TimerMode.pomodoro:
        return 'Focus';
      case TimerMode.shortBreak:
        return 'Break';
      case TimerMode.longBreak:
        return 'Long break';
    }
  }

  /// Message shown when this mode completes.
  String get completionMessage {
    switch (this) {
      case TimerMode.pomodoro:
        return 'Session complete! Take a break.';
      case TimerMode.shortBreak:
        return 'Break complete! Time to focus.';
      case TimerMode.longBreak:
        return 'Long break complete! You are doing great!';
    }
  }

  bool get isBreak =>
      this == TimerMode.shortBreak || this == TimerMode.longBreak;
}
