import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pomodoro_provider.dart';
import '../services/haptic_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _pomodoro;
  late int _shortBreak;
  late int _longBreak;
  late int _dailyGoal;
  late bool _autoStartBreaks;
  late bool _autoStartPomodoros;
  late bool _soundEnabled;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(pomodoroProvider);
    _pomodoro = s.pomodoroDuration;
    _shortBreak = s.shortBreakDuration;
    _longBreak = s.longBreakDuration;
    _dailyGoal = s.dailyGoal;
    _autoStartBreaks = s.autoStartBreaks;
    _autoStartPomodoros = s.autoStartPomodoros;
    _soundEnabled = s.soundEnabled;
  }

  void _markChanged() => setState(() => _hasChanges = true);

  void _save() {
    HapticService.buttonPress();
    ref.read(pomodoroProvider.notifier).updateSettings(
          pomodoroDuration: _pomodoro,
          shortBreakDuration: _shortBreak,
          longBreakDuration: _longBreak,
          dailyGoal: _dailyGoal,
          autoStartBreaks: _autoStartBreaks,
          autoStartPomodoros: _autoStartPomodoros,
          soundEnabled: _soundEnabled,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          AnimatedOpacity(
            opacity: _hasChanges ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _hasChanges ? _save : null,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Duraciones ──────────────────────────────────────────────
          _SectionTitle('DURACIONES (minutos)'),
          _DurationTile(
            label: 'Pomodoro',
            value: _pomodoro,
            min: 1,
            max: 60,
            onChanged: (v) { setState(() => _pomodoro = v); _markChanged(); },
          ),
          _DurationTile(
            label: 'Descanso corto',
            value: _shortBreak,
            min: 1,
            max: 30,
            onChanged: (v) { setState(() => _shortBreak = v); _markChanged(); },
          ),
          _DurationTile(
            label: 'Descanso largo',
            value: _longBreak,
            min: 1,
            max: 60,
            onChanged: (v) { setState(() => _longBreak = v); _markChanged(); },
          ),

          const SizedBox(height: 20),

          // ── Objetivo diario ──────────────────────────────────────────
          _SectionTitle('OBJETIVO DIARIO'),
          _DurationTile(
            label: 'Sesiones por día',
            value: _dailyGoal,
            min: 1,
            max: 20,
            onChanged: (v) { setState(() => _dailyGoal = v); _markChanged(); },
          ),

          const SizedBox(height: 20),

          // ── Automatización ───────────────────────────────────────────
          _SectionTitle('AUTOMATIZACIÓN'),
          _SwitchTile(
            label: 'Iniciar descansos automáticamente',
            value: _autoStartBreaks,
            onChanged: (v) { setState(() => _autoStartBreaks = v); _markChanged(); },
          ),
          _SwitchTile(
            label: 'Iniciar pomodoros automáticamente',
            value: _autoStartPomodoros,
            onChanged: (v) { setState(() => _autoStartPomodoros = v); _markChanged(); },
          ),

          const SizedBox(height: 20),

          // ── Sonido ───────────────────────────────────────────────────
          _SectionTitle('SONIDO'),
          _SwitchTile(
            label: 'Sonido al completar',
            value: _soundEnabled,
            onChanged: (v) { setState(() => _soundEnabled = v); _markChanged(); },
          ),

          const SizedBox(height: 20),

          // ── Secuencia ───────────────────────────────────────────────
          _SectionTitle('SECUENCIA'),
          _InfoTile(
            icon: Icons.info_outline_rounded,
            text:
                'Cada 4 pomodoros completados se activa un descanso largo en lugar de un descanso corto.',
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares de Settings ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      );
}

class _DurationTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _DurationTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: Colors.white54),
            onPressed: value > min
                ? () {
                    HapticService.adjustment();
                    onChanged(value - 1);
                  }
                : () {
                    HapticService.error();
                  },
            splashRadius: 20,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.white54),
            onPressed: value < max
                ? () {
                    HapticService.adjustment();
                    onChanged(value + 1);
                  }
                : () {
                    HapticService.error();
                  },
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticService.buttonPress();
              onChanged(v);
            },
            activeColor: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}