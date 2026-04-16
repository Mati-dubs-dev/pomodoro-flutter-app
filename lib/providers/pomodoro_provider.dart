import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_mode.dart';
import '../services/timer_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((_) {
  throw UnimplementedError(
    'storageServiceProvider debe ser sobreescrito en main()',
  );
});

// ── BUG 1 FIX: ref.onDispose garantiza que dispose() se llame siempre ────────
final timerServiceProvider = Provider<TimerService>((ref) {
  final service = TimerService();
  ref.onDispose(service.dispose);
  return service;
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
// ─────────────────────────────────────────────────────────────────────────────

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  final timer = ref.read(timerServiceProvider);
  final audio = ref.read(audioServiceProvider);
  final storage = ref.read(storageServiceProvider);
  return PomodoroNotifier(timer, audio, storage);
});

class PomodoroState {
  final TimerMode mode;
  final int timeLeft;
  final bool isRunning;
  final int completedSessions;
  final int dailyGoal;

  final int pomodoroDuration;
  final int shortBreakDuration;
  final int longBreakDuration;

  final bool autoStartBreaks;
  final bool autoStartPomodoros;
  final bool soundEnabled;

  const PomodoroState({
    required this.mode,
    required this.timeLeft,
    required this.isRunning,
    required this.completedSessions,
    required this.dailyGoal,
    this.pomodoroDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.autoStartBreaks = false,
    this.autoStartPomodoros = false,
    this.soundEnabled = true,
  });

  int get currentModeDuration {
    switch (mode) {
      case TimerMode.pomodoro:
        return pomodoroDuration * 60;
      case TimerMode.shortBreak:
        return shortBreakDuration * 60;
      case TimerMode.longBreak:
        return longBreakDuration * 60;
    }
  }

  double get progress {
    final total = currentModeDuration;
    if (total == 0) return 0;
    return (1 - (timeLeft / total)).clamp(0.0, 1.0);
  }

  bool get dailyGoalReached => completedSessions >= dailyGoal;

  PomodoroState copyWith({
    TimerMode? mode,
    int? timeLeft,
    bool? isRunning,
    int? completedSessions,
    int? dailyGoal,
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? soundEnabled,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      timeLeft: timeLeft ?? this.timeLeft,
      isRunning: isRunning ?? this.isRunning,
      completedSessions: completedSessions ?? this.completedSessions,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  final TimerService _timerService;
  final AudioService _audioService;
  final StorageService _storage;

  late final AppLifecycleListener _lifecycleListener;

  PomodoroNotifier(
    this._timerService,
    this._audioService,
    this._storage,
  ) : super(
          PomodoroState(
            mode: TimerMode.pomodoro,
            timeLeft: _storage.pomodoroDuration * 60,
            isRunning: false,
            completedSessions: _storage.completedSessions,
            dailyGoal: _storage.dailyGoal,
            pomodoroDuration: _storage.pomodoroDuration,
            shortBreakDuration: _storage.shortBreakDuration,
            longBreakDuration: _storage.longBreakDuration,
            autoStartBreaks: _storage.autoStartBreaks,
            autoStartPomodoros: _storage.autoStartPomodoros,
            soundEnabled: _storage.soundEnabled,
          ),
        ) {
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResume,
    );
    // ── BUG 4 FIX: restaurar timer si la app fue cerrada con uno activo ───
    _restoreTimerIfNeeded();
    // ─────────────────────────────────────────────────────────────────────
  }

  // ── BUG 4 FIX: restaurar endTime persistido ────────────────────────────────
  void _restoreTimerIfNeeded() {
    final savedEnd = _storage.savedTimerEndTime;
    if (savedEnd == null) return;

    state = state.copyWith(isRunning: true);

    _timerService.startFromEndTime(
      endTime: savedEnd,
      onTick: (remaining) {
        state = state.copyWith(timeLeft: remaining.inSeconds);
      },
      onFinish: _completeSession,
    );
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _onAppResume() {
    _checkDayRollover();

    // Si había un timer corriendo, sincronizar el tiempo restante real
    if (state.isRunning && _timerService.isActive) {
      final remaining = _timerService.remaining;
      if (remaining > Duration.zero) {
        state = state.copyWith(timeLeft: remaining.inSeconds);
      }
    }
  }

  void _checkDayRollover() {
    final storedSessions = _storage.completedSessions;
    if (storedSessions != state.completedSessions) {
      state = state.copyWith(completedSessions: storedSessions);
    }
  }

  void start() {
    if (state.isRunning) return;

    _checkDayRollover();
    HapticService.buttonPress();

    state = state.copyWith(isRunning: true);

    if (_timerService.isPaused) {
      _timerService.resume();
      // Persistir el nuevo endTime tras reanudar
      if (_timerService.endTime != null) {
        _storage.saveTimerEndTime(_timerService.endTime!);
      }
      return;
    }

    _timerService.start(
      duration: Duration(seconds: state.timeLeft),
      onTick: (remaining) {
        state = state.copyWith(timeLeft: remaining.inSeconds);
      },
      onFinish: _completeSession,
    );

    // ── BUG 4 FIX: persistir endTime al iniciar ───────────────────────────
    if (_timerService.endTime != null) {
      _storage.saveTimerEndTime(_timerService.endTime!);
    }
    // ─────────────────────────────────────────────────────────────────────
  }

  void pause() {
    HapticService.buttonPress();
    _timerService.pause();
    state = state.copyWith(isRunning: false);
    // Limpiar endTime persistido: el timer está pausado, no debe restaurarse
    _storage.clearTimerEndTime();
  }

  void reset() {
    HapticService.buttonPress();
    _timerService.stop();
    _storage.clearTimerEndTime();
    state = state.copyWith(
      timeLeft: state.currentModeDuration,
      isRunning: false,
    );
  }

  void skip() {
    HapticService.buttonPress();
    _timerService.stop();
    _storage.clearTimerEndTime();

    final nextMode = _nextMode(state.mode, state.completedSessions);
    state = state.copyWith(
      mode: nextMode,
      timeLeft: _durationFor(nextMode),
      isRunning: false,
    );
  }

  void changeMode(TimerMode mode) {
    if (mode == state.mode) return;
    HapticService.modeChange();
    _timerService.stop();
    _storage.clearTimerEndTime();
    state = state.copyWith(
      mode: mode,
      timeLeft: _durationFor(mode),
      isRunning: false,
    );
  }

  void _completeSession() {
    _timerService.stop();
    _storage.clearTimerEndTime();

    final wasPomodoro = state.mode == TimerMode.pomodoro;
    final sessions =
        wasPomodoro ? state.completedSessions + 1 : state.completedSessions;

    if (state.soundEnabled) {
      if (wasPomodoro) {
        _audioService.playSessionComplete();
        NotificationService.showSessionComplete(sessions);
      } else {
        _audioService.playBreakComplete();
        NotificationService.showBreakComplete();
      }
    }

    if (wasPomodoro) {
      _storage.recordCompletedSession(
        totalSessions: sessions,
        pomodoroMinutes: state.pomodoroDuration,
      );
    }

    final nextMode = _nextMode(state.mode, sessions);
    final shouldAutoStart =
        nextMode.isBreak ? state.autoStartBreaks : state.autoStartPomodoros;

    state = state.copyWith(
      completedSessions: sessions,
      mode: nextMode,
      timeLeft: _durationFor(nextMode),
      isRunning: false,
    );

    if (shouldAutoStart) start();
  }

  TimerMode _nextMode(TimerMode current, int completedSessions) {
    if (current == TimerMode.pomodoro) {
      return completedSessions % 4 == 0
          ? TimerMode.longBreak
          : TimerMode.shortBreak;
    }
    return TimerMode.pomodoro;
  }

  int _durationFor(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return state.pomodoroDuration * 60;
      case TimerMode.shortBreak:
        return state.shortBreakDuration * 60;
      case TimerMode.longBreak:
        return state.longBreakDuration * 60;
    }
  }

  // ── BUG 2 FIX: un único copyWith — elimina el doble rebuild ───────────────
  void updateSettings({
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? dailyGoal,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? soundEnabled,
  }) {
    // Calcular el nuevo timeLeft en una sola pasada para emitir un único estado
    final newPomodoro = pomodoroDuration ?? state.pomodoroDuration;
    final newShort = shortBreakDuration ?? state.shortBreakDuration;
    final newLong = longBreakDuration ?? state.longBreakDuration;

    int? newTimeLeft;
    if (!state.isRunning) {
      newTimeLeft = switch (state.mode) {
        TimerMode.pomodoro => newPomodoro * 60,
        TimerMode.shortBreak => newShort * 60,
        TimerMode.longBreak => newLong * 60,
      };
    }

    state = state.copyWith(
      pomodoroDuration: pomodoroDuration,
      shortBreakDuration: shortBreakDuration,
      longBreakDuration: longBreakDuration,
      dailyGoal: dailyGoal,
      autoStartBreaks: autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros,
      soundEnabled: soundEnabled,
      timeLeft: newTimeLeft,
    );

    // Persistir en storage de forma asíncrona (fire-and-forget)
    if (pomodoroDuration != null) _storage.setPomodoroDuration(pomodoroDuration);
    if (shortBreakDuration != null) _storage.setShortBreakDuration(shortBreakDuration);
    if (longBreakDuration != null) _storage.setLongBreakDuration(longBreakDuration);
    if (dailyGoal != null) _storage.setDailyGoal(dailyGoal);
    if (autoStartBreaks != null) _storage.setAutoStartBreaks(autoStartBreaks);
    if (autoStartPomodoros != null) _storage.setAutoStartPomodoros(autoStartPomodoros);
    if (soundEnabled != null) _storage.setSoundEnabled(soundEnabled);
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _timerService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}