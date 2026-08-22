import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/weekly_bar_chart.dart';

const _accent = Color(0xFFFF6B6B);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final weeklySessions = ref.watch(weeklyTotalSessionsProvider);
    final weeklyMinutes = ref.watch(weeklyTotalMinutesProvider);
    final previousMinutes = ref.watch(previousWeekMinutesProvider);
    final bestDay = ref.watch(bestDayProvider);
    final streak = ref.watch(focusStreakProvider);
    final tasks = ref.watch(taskSummaryProvider);
    final history = ref.watch(focusHistoryProvider);
    final difference = weeklyMinutes - previousMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionTitle('HOY'),
          _TodayCard(
            sessions: state.completedSessions,
            dailyGoal: state.dailyGoal,
            color: _accent,
          ),
          const SizedBox(height: 24),
          const _SectionTitle('ÚLTIMOS 7 DÍAS'),
          _Surface(
            child: WeeklyBarChart(stats: weeklyStats, color: _accent),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 520
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(
                    width: width,
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Sesiones',
                    value: '$weeklySessions',
                    color: _accent,
                  ),
                  _Metric(
                    width: width,
                    icon: Icons.timer_outlined,
                    label: 'Foco',
                    value: formatMinutes(weeklyMinutes),
                    color: const Color(0xFF4ECDC4),
                  ),
                  _Metric(
                    width: width,
                    icon: Icons.local_fire_department_outlined,
                    label: 'Racha',
                    value: '$streak d',
                    color: const Color(0xFFFFC107),
                  ),
                  _Metric(
                    width: width,
                    icon: difference >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    label: 'vs. anterior',
                    value:
                        '${difference >= 0 ? '+' : ''}${formatMinutes(difference.abs())}',
                    color: difference >= 0
                        ? const Color(0xFF4ECDC4)
                        : Colors.orangeAccent,
                  ),
                ],
              );
            },
          ),
          if (bestDay != null) ...[
            const SizedBox(height: 12),
            Text(
              'Tu mejor día fue ${bestDay.weekdayLabel}: '
              '${bestDay.sessions} ${bestDay.sessions == 1 ? 'sesión' : 'sesiones'}.',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionTitle('FOCO POR TAREA'),
            _Surface(
              child: Column(
                children: tasks.take(5).map((task) {
                  final maxMinutes = tasks.first.minutes;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.task,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${formatMinutes(task.minutes)} · ${task.sessions}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: task.minutes / maxMinutes,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.07,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('HISTORIAL RECIENTE'),
              if (history.isNotEmpty)
                Text(
                  '${history.length} guardadas',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
          if (history.isEmpty)
            const _EmptyHistory()
          else
            _Surface(
              padding: EdgeInsets.zero,
              child: Column(
                children: history.take(12).map((session) {
                  return _HistoryTile(
                    session: session,
                    onEdit: () => _renameSession(context, ref, session),
                    onDelete: () => _deleteSession(context, ref, session),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _renameSession(
    BuildContext context,
    WidgetRef ref,
    FocusSession session,
  ) async {
    final controller = TextEditingController(text: session.task);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar tarea'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(hintText: 'Nombre de la tarea'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await ref
          .read(pomodoroProvider.notifier)
          .renameFocusSession(session.id, value);
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    FocusSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar sesión'),
        content: const Text(
          'También se descontará de las estadísticas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(pomodoroProvider.notifier).deleteFocusSession(session.id);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Surface({
    this.padding = const EdgeInsets.all(16),
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _TodayCard extends StatelessWidget {
  final int sessions;
  final int dailyGoal;
  final Color color;

  const _TodayCard({
    required this.sessions,
    required this.dailyGoal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (sessions / dailyGoal).clamp(0.0, 1.0);
    return _Surface(
      child: Semantics(
        label: '$sessions de $dailyGoal sesiones completadas hoy',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$sessions de $dailyGoal sesiones',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (sessions >= dailyGoal)
                  const Icon(Icons.check_circle_rounded, color: _accent),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  final FocusSession session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.session,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = session.completedAt;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final dateText = isToday
        ? 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0x22FF6B6B),
        child: Icon(Icons.check_rounded, color: _accent, size: 20),
      ),
      title: Text(
        session.displayTask,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$dateText · ${formatMinutes(session.focusMinutes)}'),
      trailing: PopupMenuButton<String>(
        tooltip: 'Acciones de la sesión',
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar tarea')),
          PopupMenuItem(value: 'delete', child: Text('Eliminar sesión')),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const _Surface(
    child: Column(
      children: [
        Icon(Icons.insights_rounded, color: Colors.white38, size: 32),
        SizedBox(height: 10),
        Text(
          'Completá tu primer Pomodoro para ver el historial.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60),
        ),
      ],
    ),
  );
}
