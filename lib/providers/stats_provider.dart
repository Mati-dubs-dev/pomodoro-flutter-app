import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_stat.dart';
import 'pomodoro_provider.dart';

/// Provee las estadísticas de los últimos 7 días.
/// Se recalcula automáticamente cuando cambia el conteo de sesiones del día.
final weeklyStatsProvider = Provider<List<DailyStat>>((ref) {
  // Observar cambios en sesiones completadas para refrescar las stats
  ref.watch(pomodoroProvider.select((s) => s.completedSessions));
  final storage = ref.read(storageServiceProvider);
  return storage.getWeeklyStats();
});

/// Total de sesiones completadas esta semana.
final weeklyTotalSessionsProvider = Provider<int>((ref) {
  return ref.watch(weeklyStatsProvider).fold(0, (sum, s) => sum + s.sessions);
});

/// Total de minutos de foco esta semana.
final weeklyTotalMinutesProvider = Provider<int>((ref) {
  return ref
      .watch(weeklyStatsProvider)
      .fold(0, (sum, s) => sum + s.focusMinutes);
});

/// Mejor día de la semana (con más sesiones completadas).
final bestDayProvider = Provider<DailyStat?>((ref) {
  final stats = ref.watch(weeklyStatsProvider);
  if (stats.every((s) => s.sessions == 0)) return null;
  return stats.reduce((a, b) => a.sessions >= b.sessions ? a : b);
});