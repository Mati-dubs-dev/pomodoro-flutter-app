import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// Controles del temporizador: reiniciar, iniciar/pausar, saltar.
class TimerControls extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStartPause;
  final VoidCallback onReset;
  final VoidCallback onSkip;
  final Color color;

  const TimerControls({
    super.key,
    required this.isRunning,
    required this.onStartPause,
    required this.onReset,
    required this.onSkip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          size: 60,
          onTap: () {
            HapticService.buttonPress();
            onReset();
          },
          backgroundColor: Colors.white.withOpacity(0.08),
          tooltip: 'Reiniciar',
          child: const Icon(Icons.refresh_rounded, color: Colors.white60),
        ),
        const SizedBox(width: 24),
        _CircleButton(
          size: 84,
          onTap: onStartPause,
          backgroundColor: color,
          tooltip: isRunning ? 'Pausar' : 'Iniciar',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(isRunning),
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 24),
        _CircleButton(
          size: 60,
          onTap: () {
            HapticService.buttonPress();
            onSkip();
          },
          backgroundColor: Colors.white.withOpacity(0.08),
          tooltip: 'Saltar',
          child: const Icon(Icons.skip_next_rounded, color: Colors.white60),
        ),
      ],
    );
  }
}

class _CircleButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Widget child;
  final String tooltip;

  const _CircleButton({
    required this.size,
    required this.onTap,
    required this.backgroundColor,
    required this.child,
    required this.tooltip,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}