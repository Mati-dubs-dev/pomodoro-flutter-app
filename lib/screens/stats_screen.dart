import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/weekly_bar_chart.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _accentColor = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final weeklyTotal = ref.watch(weeklyTotalSessionsProvider);
    final weeklyMinutes = ref.watch(weeklyTotalMinutesProvider);
    final bestDay = ref.watch(bestDayProvider);

    final todaySessions = pomodoroState.completedSessions;
    final dailyGoal = pomodoroState.dailyGoal;
    final todayProgress = dailyGoal > 0 ? todaySessions / dailyGoal : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Estadísticas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Progreso de hoy ──────────────────────────────────────────
          _SectionTitle('HOY'),
          _TodayCard(
            sessions: todaySessions,
            dailyGoal: dailyGoal,
            progress: todayProgress.clamp(0.0, 1.0),
            color: _accentColor,
          ),

          const SizedBox(height: 24),

          // ── Gráfico semanal ──────────────────────────────────────────
          _SectionTitle('ÚLTIMOS 7 DÍAS'),
          _CardContainer(
            child: WeeklyBarChart(stats: weeklyStats, color: _accentColor),
          ),

          const SizedBox(height: 24),

          // ── Resumen semanal ──────────────────────────────────────────
          _SectionTitle('RESUMEN DE LA SEMANA'),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.radio_button_checked_rounded,
                  label: 'Sesiones',
                  value: '$weeklyTotal',
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Tiempo de foco',
                  value: formatMinutes(weeklyMinutes),
                  color: const Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),

          if (bestDay != null && bestDay.sessions > 0) ...[
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.emoji_events_rounded,
              label: 'Mejor día',
              value:
                  '${bestDay.weekdayLabel} — ${bestDay.sessions} sesión${bestDay.sessions == 1 ? '' : 'es'}',
              color: const Color(0xFFFFC107),
              wide: true,
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      );
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _TodayCard extends StatelessWidget {
  final int sessions;
  final int dailyGoal;
  final double progress;
  final Color color;

  const _TodayCard({
    required this.sessions,
    required this.dailyGoal,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reached = sessions >= dailyGoal;

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sessions de $dailyGoal sesiones',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (reached)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '¡Objetivo cumplido!',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: wide
          ? Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(label,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}