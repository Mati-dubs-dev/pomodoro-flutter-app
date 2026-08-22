import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_mode.dart';
import '../providers/pomodoro_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/mode_selector.dart';
import '../widgets/progress_ring_painter.dart';
import '../widgets/session_dots.dart';
import '../widgets/timer_controls.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  static const _modeColors = {
    TimerMode.pomodoro: Color(0xFFFF6B6B),
    TimerMode.shortBreak: Color(0xFF4ECDC4),
    TimerMode.longBreak: Color(0xFF45B7D1),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final color = _modeColors[state.mode]!;

    ref.listen<int>(pomodoroProvider.select((value) => value.completionId), (
      previous,
      next,
    ) {
      if (next > (previous ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCompletionActions();
        });
      }
    });

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1a1a2e), color.withValues(alpha: 0.1)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              final ringSize = compact
                  ? constraints.maxWidth.clamp(190.0, 220.0)
                  : constraints.maxWidth.clamp(220.0, 280.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _TopBar(state: state, color: color),
                      const SizedBox(height: 4),
                      ModeSelector(
                        currentMode: state.mode,
                        onModeChanged: notifier.changeMode,
                        color: color,
                      ),
                      SizedBox(height: compact ? 20 : 36),
                      if (state.mode == TimerMode.pomodoro) ...[
                        _TaskIntent(
                          task: state.currentTask,
                          enabled: !state.isRunning,
                          color: color,
                          onTap: _editTask,
                        ),
                        SizedBox(height: compact ? 16 : 28),
                      ],
                      _TimerRing(state: state, color: color, size: ringSize),
                      SizedBox(height: compact ? 24 : 40),
                      TimerControls(
                        isRunning: state.isRunning,
                        onStartPause: state.isRunning
                            ? notifier.pause
                            : _startWithTask,
                        onReset: notifier.reset,
                        onSkip: _confirmSkip,
                        color: color,
                      ),
                      const SizedBox(height: 28),
                      SessionDots(
                        completedSessions: state.completedSessions,
                        dailyGoal: state.dailyGoal,
                        color: color,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startWithTask() async {
    final state = ref.read(pomodoroProvider);
    if (state.mode == TimerMode.pomodoro && state.currentTask.isEmpty) {
      await _editTask();
      if (!mounted) return;
    }
    await ref.read(pomodoroProvider.notifier).start();
  }

  Future<void> _editTask() async {
    final notifier = ref.read(pomodoroProvider.notifier);
    final current = ref.read(pomodoroProvider).currentTask;
    final controller = TextEditingController(text: current);
    final task = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿En qué vas a enfocarte?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Ej.: terminar la pantalla de inicio',
            helperText: 'Podés dejarlo vacío y comenzar igual.',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Sin tarea'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (task != null) notifier.setCurrentTask(task);
  }

  Future<void> _confirmSkip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Saltar este bloque?'),
        content: const Text(
          'El bloque actual no se contará como una sesión completada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Saltar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(pomodoroProvider.notifier).skip();
    }
  }

  Future<void> _showCompletionActions() async {
    final state = ref.read(pomodoroProvider);
    if (state.isRunning || state.lastCompletedMode == null) return;
    final completedFocus = state.lastCompletedMode == TimerMode.pomodoro;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                completedFocus ? 'Sesión completada' : 'Descanso terminado',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                completedFocus
                    ? 'Buen trabajo. Elegí cómo querés continuar.'
                    : 'Tu siguiente bloque de foco está listo.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (completedFocus) {
                    ref.read(pomodoroProvider.notifier).start();
                  } else {
                    _startWithTask();
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  completedFocus ? 'Iniciar descanso' : 'Iniciar Pomodoro',
                ),
              ),
              if (completedFocus) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(pomodoroProvider.notifier).extendFocus();
                  },
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text('Extender 5 minutos'),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskIntent extends StatelessWidget {
  final String task;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _TaskIntent({
    required this.task,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      label: task.isEmpty ? 'Definir tarea de enfoque' : 'Tarea actual: $task',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt_rounded, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.isEmpty ? '¿En qué vas a enfocarte?' : task,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: task.isEmpty ? Colors.white54 : Colors.white,
                    ),
                  ),
                ),
                if (enabled)
                  const Icon(
                    Icons.edit_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final PomodoroState state;
  final Color color;

  const _TopBar({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label:
                '${state.completedSessions} de ${state.dailyGoal} sesiones completadas hoy',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.dailyGoalReached
                    ? color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.dailyGoalReached
                        ? Icons.emoji_events_rounded
                        : Icons.local_fire_department_rounded,
                    color: state.dailyGoalReached ? color : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${state.completedSessions}/${state.dailyGoal}',
                    style: TextStyle(
                      color: state.dailyGoalReached ? color : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                color: Colors.white70,
                tooltip: 'Estadísticas',
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: Colors.white70,
                tooltip: 'Configuración',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final PomodoroState state;
  final Color color;
  final double size;

  const _TimerRing({
    required this.state,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '${state.mode.label}, ${formatTime(state.timeLeft)} restantes',
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: state.isRunning ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 400),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: ProgressRingPainter(
                    progress: state.progress,
                    color: color,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatTime(state.timeLeft),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.mode.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
