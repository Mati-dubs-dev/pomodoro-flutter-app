import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_stat.dart';
import '../models/focus_session.dart';
import 'pomodoro_provider.dart';

class TaskSummary {
  final String task;
  final int sessions;
  final int minutes;

  const TaskSummary({
    required this.task,
    required this.sessions,
    required this.minutes,
  });
}

final weeklyStatsProvider = Provider<List<DailyStat>>((ref) {
  ref.watch(pomodoroProvider.select((state) => state.dataVersion));
  return ref.read(storageServiceProvider).getWeeklyStats();
});

final previousWeekStatsProvider = Provider<List<DailyStat>>((ref) {
  ref.watch(pomodoroProvider.select((state) => state.dataVersion));
  return ref.read(storageServiceProvider).getDailyStats(days: 7, offsetDays: 7);
});

final focusHistoryProvider = Provider<List<FocusSession>>((ref) {
  ref.watch(pomodoroProvider.select((state) => state.dataVersion));
  return ref.read(storageServiceProvider).focusSessions;
});

final weeklyTotalSessionsProvider = Provider<int>(
  (ref) => ref
      .watch(weeklyStatsProvider)
      .fold(0, (sum, stat) => sum + stat.sessions),
);

final weeklyTotalMinutesProvider = Provider<int>(
  (ref) => ref
      .watch(weeklyStatsProvider)
      .fold(0, (sum, stat) => sum + stat.focusMinutes),
);

final previousWeekMinutesProvider = Provider<int>(
  (ref) => ref
      .watch(previousWeekStatsProvider)
      .fold(0, (sum, stat) => sum + stat.focusMinutes),
);

final bestDayProvider = Provider<DailyStat?>((ref) {
  final stats = ref.watch(weeklyStatsProvider);
  if (stats.every((stat) => stat.sessions == 0)) return null;
  return stats.reduce((a, b) => a.sessions >= b.sessions ? a : b);
});

final focusStreakProvider = Provider<int>((ref) {
  ref.watch(pomodoroProvider.select((state) => state.dataVersion));
  final stats = ref.read(storageServiceProvider).getDailyStats(days: 90);
  var streak = 0;
  for (final stat in stats.reversed) {
    if (stat.sessions == 0) {
      if (stat.isToday) continue;
      break;
    }
    streak += 1;
  }
  return streak;
});

final taskSummaryProvider = Provider<List<TaskSummary>>((ref) {
  final history = ref.watch(focusHistoryProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final values = <String, ({int sessions, int minutes})>{};
  for (final session in history.where(
    (session) => session.completedAt.isAfter(cutoff),
  )) {
    final key = session.displayTask;
    final current = values[key] ?? (sessions: 0, minutes: 0);
    values[key] = (
      sessions: current.sessions + 1,
      minutes: current.minutes + session.focusMinutes,
    );
  }
  final result =
      values.entries
          .map(
            (entry) => TaskSummary(
              task: entry.key,
              sessions: entry.value.sessions,
              minutes: entry.value.minutes,
            ),
          )
          .toList()
        ..sort((a, b) => b.minutes.compareTo(a.minutes));
  return result;
});
