import 'package:flutter/material.dart';

/// Muestra el progreso del objetivo diario como una fila de puntos animados.
/// Los puntos completados se iluminan con [color]; los pendientes quedan apagados.
class SessionDots extends StatelessWidget {
  final int completedSessions;
  final int dailyGoal;
  final Color color;

  const SessionDots({
    super.key,
    required this.completedSessions,
    required this.dailyGoal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Máximo 12 puntos para no desbordarse en pantallas pequeñas
    final clampedGoal = dailyGoal.clamp(1, 12);

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(clampedGoal, (i) {
            final isCompleted = i < completedSessions;
            final isNext = i == completedSessions;

            return TweenAnimationBuilder<double>(
              // ── BUG 5 FIX: key dinámica — fuerza reconstruir el tween
              // cuando el dot cambia de estado (completado ↔ pendiente).
              // Sin esto, Flutter reutiliza el widget y el tween no se
              // re-evalúa al cambiar completedSessions.
              key: ValueKey('dot_${i}_$isCompleted'),
              tween: Tween(begin: 0.0, end: isCompleted ? 1.0 : 0.0),
              duration: Duration(milliseconds: 300 + i * 40),
              curve: Curves.elasticOut,
              builder: (_, value, __) {
                return Transform.scale(
                  scale: isCompleted ? (0.9 + 0.1 * value) : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? color
                          : isNext
                              ? color.withOpacity(0.25)
                              : Colors.white.withOpacity(0.1),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              },
            );
          }),
        ),
        if (dailyGoal > 12) ...[
          const SizedBox(height: 6),
          Text(
            '$completedSessions / $dailyGoal sesiones',
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}