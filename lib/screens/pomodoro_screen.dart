import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pomodoro_provider.dart';
import '../models/timer_mode.dart';
import '../widgets/mode_selector.dart';
import '../widgets/progress_ring_painter.dart';
import '../widgets/timer_controls.dart';
import '../widgets/session_dots.dart';
import '../utils/time_formatter.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  static const _modeColors = {
    TimerMode.pomodoro: Color(0xFFFF6B6B),
    TimerMode.shortBreak: Color(0xFF4ECDC4),
    TimerMode.longBreak: Color(0xFF45B7D1),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final color = _modeColors[state.mode]!;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              color.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Barra superior ───────────────────────────────────────
              _TopBar(state: state, color: color),

              const SizedBox(height: 8),

              // ── Selector de modo ─────────────────────────────────────
              ModeSelector(
                currentMode: state.mode,
                onModeChanged: notifier.changeMode,
                color: color,
              ),

              const Spacer(),

              // ── Anillo temporizador ──────────────────────────────────
              _TimerRing(state: state, color: color),

              const Spacer(),

              // ── Controles ────────────────────────────────────────────
              TimerControls(
                isRunning: state.isRunning,
                onStartPause:
                    state.isRunning ? notifier.pause : notifier.start,
                onReset: notifier.reset,
                onSkip: notifier.skip,
                color: color,
              ),

              const SizedBox(height: 40),

              // ── Puntos de sesiones ───────────────────────────────────
              SessionDots(
                completedSessions: state.completedSessions,
                dailyGoal: state.dailyGoal,
                color: color,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets privados ──────────────────────────────────────────────────────

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
          // Badge objetivo diario
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.dailyGoalReached
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.dailyGoalReached
                      ? Icons.emoji_events_rounded
                      : Icons.local_fire_department_rounded,
                  color:
                      state.dailyGoalReached ? color : Colors.white38,
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

          // Acciones
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.bar_chart_rounded, color: Colors.white54),
                tooltip: 'Estadísticas',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white54),
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

  const _TimerRing({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: state.isRunning ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: ProgressRingPainter(
                progress: state.progress,
                color: color,
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatTime(state.timeLeft),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 13,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.8,
                ),
                child: Text(state.mode.label.toUpperCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}