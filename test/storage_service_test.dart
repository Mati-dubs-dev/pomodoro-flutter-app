import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_pro/models/timer_mode.dart';
import 'package:pomodoro_pro/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'archives the previous day and resets counters after date rollover',
    () async {
      final now = DateTime(2026, 8, 21, 8);
      SharedPreferences.setMockInitialValues({
        'last_date': '2026-08-20',
        'completed_sessions': 3,
        'focus_minutes_today': 75,
        'weekly_stats': jsonEncode({
          '2026-08-20': {'sessions': 3, 'minutes': 75},
        }),
      });

      final storage = await StorageService.create(now: () => now);

      expect(storage.completedSessions, 0);
      expect(storage.focusMinutesToday, 0);
      final yesterday = storage.getDailyStats(days: 2).first;
      expect(yesterday.sessions, 3);
      expect(yesterday.focusMinutes, 75);
    },
  );

  test('the first session of a new day starts at one', () async {
    final now = DateTime(2026, 8, 21, 9);
    SharedPreferences.setMockInitialValues({
      'last_date': '2026-08-20',
      'completed_sessions': 8,
      'focus_minutes_today': 200,
    });
    final storage = await StorageService.create(now: () => now);

    final session = await storage.recordCompletedSession(
      pomodoroMinutes: 25,
      task: 'Informe semanal',
    );

    expect(storage.completedSessions, 1);
    expect(storage.focusMinutesToday, 25);
    expect(session.displayTask, 'Informe semanal');
    expect(storage.focusSessions, hasLength(1));
  });

  test('keeps expired snapshots for reconciliation at startup', () async {
    final now = DateTime(2026, 8, 21, 12);
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create(now: () => now);
    await storage.saveTimerSnapshot(
      endTime: now.subtract(const Duration(minutes: 2)),
      mode: TimerMode.pomodoro,
      task: 'Preparar demo',
    );

    final snapshot = storage.savedTimerSnapshot;

    expect(snapshot, isNotNull);
    expect(snapshot!.task, 'Preparar demo');
    expect(snapshot.endTime!.isBefore(now), isTrue);
  });

  test('deleting a session subtracts its count and minutes', () async {
    final now = DateTime(2026, 8, 21, 12);
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create(now: () => now);
    final session = await storage.recordCompletedSession(
      pomodoroMinutes: 25,
      task: 'Coding',
    );

    await storage.deleteFocusSession(session.id);

    expect(storage.completedSessions, 0);
    expect(storage.focusMinutesToday, 0);
    expect(storage.focusSessions, isEmpty);
  });
}
