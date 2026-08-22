import 'package:flutter/material.dart';

/// Shows daily-goal progress as a row of animated dots.
/// Completed dots use [color], while pending dots remain muted.
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
    // Limit to 12 dots to prevent overflow on small screens.
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
              // Rebuild the tween when a dot changes between pending and
              // completed; otherwise Flutter may reuse the previous tween.
              key: ValueKey('dot_${i}_$isCompleted'),
              tween: Tween(begin: 0.0, end: isCompleted ? 1.0 : 0.0),
              duration: Duration(milliseconds: 300 + i * 40),
              curve: Curves.elasticOut,
              builder: (_, value, _) {
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
                          ? color.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.1),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
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
            '$completedSessions / $dailyGoal sessions',
            style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ],
    );
  }
}
