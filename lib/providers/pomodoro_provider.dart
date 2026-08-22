import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_mode.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';

final storageServiceProvider = Provider<StorageService>((_) {
  throw UnimplementedError('storageServiceProvider debe sobreescribirse');
});

final notificationServiceProvider = Provider<PomodoroNotifications>((_) {
  throw UnimplementedError('notificationServiceProvider debe sobreescribirse');
});

final timerServiceProvider = Provider<TimerDriver>((ref) {
  final service = TimerService();
  ref.onDispose(service.dispose);
  return service;
});

final audioServiceProvider = Provider<PomodoroAudio>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>(
  (ref) {
    return PomodoroNotifier(
      ref.read(timerServiceProvider),
      ref.read(audioServiceProvider),
      ref.read(notificationServiceProvider),
      ref.read(storageServiceProvider),
    );
  },
);

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
  final bool notificationsEnabled;
  final bool hapticsEnabled;
  final String currentTask;
  final int completionId;
  final TimerMode? lastCompletedMode;
  final int dataVersion;

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
    this.notificationsEnabled = true,
    this.hapticsEnabled = true,
    this.currentTask = '',
    this.completionId = 0,
    this.lastCompletedMode,
    this.dataVersion = 0,
  });

  int get currentModeDuration => switch (mode) {
    TimerMode.pomodoro => pomodoroDuration * 60,
    TimerMode.shortBreak => shortBreakDuration * 60,
    TimerMode.longBreak => longBreakDuration * 60,
  };

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
    bool? notificationsEnabled,
    bool? hapticsEnabled,
    String? currentTask,
    int? completionId,
    TimerMode? lastCompletedMode,
    int? dataVersion,
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
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      currentTask: currentTask ?? this.currentTask,
      completionId: completionId ?? this.completionId,
      lastCompletedMode: lastCompletedMode ?? this.lastCompletedMode,
      dataVersion: dataVersion ?? this.dataVersion,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  final TimerDriver _timer;
  final PomodoroAudio _audio;
  final PomodoroNotifications _notifications;
  final StorageService _storage;
  late final AppLifecycleListener _lifecycleListener;
  bool _isCompleting = false;
  bool _permissionRequested = false;

  PomodoroNotifier(this._timer, this._audio, this._notifications, this._storage)
    : super(
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
          notificationsEnabled: _storage.notificationsEnabled,
          hapticsEnabled: _storage.hapticsEnabled,
        ),
      ) {
    HapticService.enabled = _storage.hapticsEnabled;
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResume);
    unawaited(_restoreTimerIfNeeded());
  }

  Future<void> _restoreTimerIfNeeded() async {
    final snapshot = _storage.savedTimerSnapshot;
    if (snapshot == null) return;

    state = state.copyWith(
      mode: snapshot.mode,
      currentTask: snapshot.task,
      timeLeft: snapshot.remainingSeconds ?? _durationFor(snapshot.mode),
    );
    if (snapshot.isPaused) return;
    final endTime = snapshot.endTime;
    if (endTime == null) {
      await _storage.clearTimerSnapshot();
      return;
    }
    final remaining = endTime.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      await _completeSession();
      return;
    }

    state = state.copyWith(
      isRunning: true,
      timeLeft: _displaySeconds(remaining),
    );
    _timer.startFromEndTime(
      endTime: endTime,
      onTick: _updateRemaining,
      onFinish: () => unawaited(_completeSession()),
    );
  }

  Future<void> _onAppResume() async {
    await _syncDay();
    if (!state.isRunning) return;
    final endTime = _timer.endTime;
    if (endTime != null && endTime.isBefore(DateTime.now())) {
      await _completeSession();
      return;
    }
    if (_timer.isActive) _updateRemaining(_timer.remaining);
  }

  Future<void> _syncDay() async {
    final changed = await _storage.rolloverIfNeeded();
    if (changed || _storage.completedSessions != state.completedSessions) {
      state = state.copyWith(
        completedSessions: _storage.completedSessions,
        dataVersion: state.dataVersion + 1,
      );
    }
  }

  Future<void> start({bool userInitiated = true}) async {
    if (state.isRunning) return;
    await _syncDay();
    if (state.hapticsEnabled && userInitiated) HapticService.buttonPress();

    state = state.copyWith(isRunning: true);
    if (_timer.isPaused) {
      _timer.resume();
    } else {
      _timer.start(
        duration: Duration(seconds: state.timeLeft),
        onTick: _updateRemaining,
        onFinish: () => unawaited(_completeSession()),
      );
    }

    final endTime = _timer.endTime;
    if (endTime == null) return;
    await _storage.saveTimerSnapshot(
      endTime: endTime,
      mode: state.mode,
      task: state.currentTask,
    );

    if (state.notificationsEnabled) {
      if (userInitiated && !_permissionRequested) {
        _permissionRequested = true;
        await _notifications.requestPermissions();
      }
      await _scheduleNotification(endTime);
    }
  }

  Future<void> _scheduleNotification(DateTime endTime) async {
    try {
      await _notifications.scheduleTimerEnd(
        endTime: endTime,
        mode: state.mode,
        completedSessions: state.completedSessions,
      );
    } on Object catch (error) {
      debugPrint('Could not schedule the notification: $error');
    }
  }

  void _updateRemaining(Duration remaining) {
    state = state.copyWith(timeLeft: _displaySeconds(remaining));
  }

  int _displaySeconds(Duration duration) =>
      (duration.inMilliseconds / Duration.millisecondsPerSecond).ceil();

  Future<void> pause() async {
    if (state.hapticsEnabled) HapticService.buttonPress();
    _timer.pause();
    state = state.copyWith(isRunning: false);
    await Future.wait([
      _storage.saveTimerSnapshot(
        mode: state.mode,
        task: state.currentTask,
        isPaused: true,
        remainingSeconds: state.timeLeft,
      ),
      _notifications.cancelTimerEnd(),
    ]);
  }

  Future<void> reset() async {
    if (state.hapticsEnabled) HapticService.buttonPress();
    _timer.stop();
    state = state.copyWith(
      timeLeft: state.currentModeDuration,
      isRunning: false,
    );
    await Future.wait([
      _storage.clearTimerSnapshot(),
      _notifications.cancelTimerEnd(),
    ]);
  }

  Future<void> skip() async {
    if (state.hapticsEnabled) HapticService.buttonPress();
    _timer.stop();
    final nextMode = _nextMode(state.mode, state.completedSessions);
    state = state.copyWith(
      mode: nextMode,
      timeLeft: _durationFor(nextMode),
      isRunning: false,
      currentTask: nextMode == TimerMode.pomodoro ? '' : state.currentTask,
    );
    await Future.wait([
      _storage.clearTimerSnapshot(),
      _notifications.cancelTimerEnd(),
    ]);
  }

  Future<void> changeMode(TimerMode mode) async {
    if (mode == state.mode) return;
    if (state.hapticsEnabled) HapticService.modeChange();
    _timer.stop();
    state = state.copyWith(
      mode: mode,
      timeLeft: _durationFor(mode),
      isRunning: false,
      currentTask: mode == TimerMode.pomodoro ? state.currentTask : '',
    );
    await Future.wait([
      _storage.clearTimerSnapshot(),
      _notifications.cancelTimerEnd(),
    ]);
  }

  void setCurrentTask(String task) {
    if (state.isRunning) return;
    state = state.copyWith(currentTask: task.trim());
  }

  Future<void> extendFocus([int minutes = 5]) async {
    _timer.stop();
    await _notifications.cancelTimerEnd();
    state = state.copyWith(
      mode: TimerMode.pomodoro,
      timeLeft: minutes * 60,
      isRunning: false,
    );
    await start();
  }

  Future<void> _completeSession() async {
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      _timer.stop();
      await _storage.clearTimerSnapshot();

      final completedMode = state.mode;
      final wasPomodoro = completedMode == TimerMode.pomodoro;
      if (wasPomodoro) {
        await _storage.recordCompletedSession(
          pomodoroMinutes: state.pomodoroDuration,
          task: state.currentTask,
        );
      }
      final sessions = _storage.completedSessions;

      if (state.soundEnabled) {
        await (wasPomodoro
            ? _audio.playSessionComplete()
            : _audio.playBreakComplete());
      }
      if (state.hapticsEnabled) {
        if (wasPomodoro && sessions >= state.dailyGoal) {
          HapticService.goalReached();
        } else {
          HapticService.sessionComplete();
        }
      }

      final nextMode = _nextMode(completedMode, sessions);
      final shouldAutoStart = nextMode.isBreak
          ? state.autoStartBreaks
          : state.autoStartPomodoros;
      state = state.copyWith(
        completedSessions: sessions,
        mode: nextMode,
        timeLeft: _durationFor(nextMode),
        isRunning: false,
        currentTask: nextMode == TimerMode.pomodoro ? '' : state.currentTask,
        completionId: state.completionId + 1,
        lastCompletedMode: completedMode,
        dataVersion: state.dataVersion + 1,
      );
      if (shouldAutoStart) await start(userInitiated: false);
    } finally {
      _isCompleting = false;
    }
  }

  TimerMode _nextMode(TimerMode current, int completedSessions) {
    if (current == TimerMode.pomodoro) {
      return completedSessions > 0 && completedSessions % 4 == 0
          ? TimerMode.longBreak
          : TimerMode.shortBreak;
    }
    return TimerMode.pomodoro;
  }

  int _durationFor(TimerMode mode) => switch (mode) {
    TimerMode.pomodoro => state.pomodoroDuration * 60,
    TimerMode.shortBreak => state.shortBreakDuration * 60,
    TimerMode.longBreak => state.longBreakDuration * 60,
  };

  Future<void> updateSettings({
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? dailyGoal,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? hapticsEnabled,
  }) async {
    final newPomodoro = pomodoroDuration ?? state.pomodoroDuration;
    final newShort = shortBreakDuration ?? state.shortBreakDuration;
    final newLong = longBreakDuration ?? state.longBreakDuration;
    final newTimeLeft = state.isRunning
        ? state.timeLeft
        : switch (state.mode) {
            TimerMode.pomodoro => newPomodoro * 60,
            TimerMode.shortBreak => newShort * 60,
            TimerMode.longBreak => newLong * 60,
          };

    state = state.copyWith(
      pomodoroDuration: pomodoroDuration,
      shortBreakDuration: shortBreakDuration,
      longBreakDuration: longBreakDuration,
      dailyGoal: dailyGoal,
      autoStartBreaks: autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros,
      soundEnabled: soundEnabled,
      notificationsEnabled: notificationsEnabled,
      hapticsEnabled: hapticsEnabled,
      timeLeft: newTimeLeft,
    );
    if (hapticsEnabled != null) HapticService.enabled = hapticsEnabled;
    await _storage.saveSettings(
      pomodoroDuration: pomodoroDuration,
      shortBreakDuration: shortBreakDuration,
      longBreakDuration: longBreakDuration,
      dailyGoal: dailyGoal,
      autoStartBreaks: autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros,
      soundEnabled: soundEnabled,
      notificationsEnabled: notificationsEnabled,
      hapticsEnabled: hapticsEnabled,
    );

    if (notificationsEnabled == false) {
      await _notifications.cancelTimerEnd();
    } else if (notificationsEnabled == true && state.isRunning) {
      final endTime = _timer.endTime;
      if (endTime != null) await _scheduleNotification(endTime);
    }
  }

  Future<void> renameFocusSession(String id, String task) async {
    await _storage.renameFocusSession(id, task);
    state = state.copyWith(dataVersion: state.dataVersion + 1);
  }

  Future<void> deleteFocusSession(String id) async {
    if (!await _storage.deleteFocusSession(id)) return;
    state = state.copyWith(
      completedSessions: _storage.completedSessions,
      dataVersion: state.dataVersion + 1,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }
}
