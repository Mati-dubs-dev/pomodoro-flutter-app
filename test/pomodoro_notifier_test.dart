import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_pro/models/timer_mode.dart';
import 'package:pomodoro_pro/providers/pomodoro_provider.dart';
import 'package:pomodoro_pro/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('programa un aviso y registra tarea al completar una sesión', () async {
    SharedPreferences.setMockInitialValues({'haptics_enabled': false});
    final storage = await StorageService.create();
    final timer = FakeTimerDriver();
    final audio = FakeAudio();
    final notifications = FakeNotifications();
    final notifier = PomodoroNotifier(timer, audio, notifications, storage);

    notifier.setCurrentTask('Corregir navegación');
    await notifier.start();
    timer.finish();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduled, 1);
    expect(notifier.state.completedSessions, 1);
    expect(notifier.state.mode, TimerMode.shortBreak);
    expect(storage.focusSessions.single.task, 'Corregir navegación');
    expect(audio.focusSounds, 1);
    notifier.dispose();
  });

  test('reconcilia una sesión que venció con la app cerrada', () async {
    final expired = DateTime.now().subtract(const Duration(minutes: 1));
    SharedPreferences.setMockInitialValues({
      'last_date': _dateKey(DateTime.now()),
      'haptics_enabled': false,
      'timer_snapshot_v1': jsonEncode({
        'endTime': expired.toIso8601String(),
        'mode': 'pomodoro',
        'task': 'Trabajo sin conexión',
      }),
    });
    final storage = await StorageService.create();
    final notifier = PomodoroNotifier(
      FakeTimerDriver(),
      FakeAudio(),
      FakeNotifications(),
      storage,
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(notifier.state.completedSessions, 1);
    expect(storage.focusSessions.single.task, 'Trabajo sin conexión');
    expect(storage.savedTimerSnapshot, isNull);
    notifier.dispose();
  });

  test('restaura una sesión pausada sin iniciarla automáticamente', () async {
    SharedPreferences.setMockInitialValues({'haptics_enabled': false});
    final storage = await StorageService.create();
    final timer = FakeTimerDriver();
    final notifier = PomodoroNotifier(
      timer,
      FakeAudio(),
      FakeNotifications(),
      storage,
    );
    notifier.setCurrentTask('Revisar accesibilidad');
    await notifier.start();
    timer.tick(const Duration(minutes: 12));
    await notifier.pause();
    notifier.dispose();

    final restored = PomodoroNotifier(
      FakeTimerDriver(),
      FakeAudio(),
      FakeNotifications(),
      storage,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restored.state.isRunning, isFalse);
    expect(restored.state.timeLeft, 12 * 60);
    expect(restored.state.currentTask, 'Revisar accesibilidad');
    restored.dispose();
  });

  test('desactivar sonido no desactiva la notificación', () async {
    SharedPreferences.setMockInitialValues({
      'sound_enabled': false,
      'notifications_enabled': true,
      'haptics_enabled': false,
    });
    final storage = await StorageService.create();
    final timer = FakeTimerDriver();
    final audio = FakeAudio();
    final notifications = FakeNotifications();
    final notifier = PomodoroNotifier(timer, audio, notifications, storage);

    await notifier.start();
    timer.finish();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifications.scheduled, 1);
    expect(audio.focusSounds, 0);
    notifier.dispose();
  });
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
