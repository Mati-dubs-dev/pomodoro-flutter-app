import 'package:flutter/material.dart';
import '../models/daily_stat.dart';

/// Simple weekly-history bar chart with no external chart package.
class WeeklyBarChart extends StatelessWidget {
  final List<DailyStat> stats;
  final Color color;

  const WeeklyBarChart({super.key, required this.stats, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxSessions = stats.fold(
      0,
      (m, s) => s.sessions > m ? s.sessions : m,
    );

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: stats.asMap().entries.map((entry) {
          final stat = entry.value;
          final fraction = maxSessions == 0 ? 0.0 : stat.sessions / maxSessions;
          final isToday = stat.isToday;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Session count (only when greater than zero).
                  if (stat.sessions > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${stat.sessions}',
                        style: TextStyle(
                          color: isToday ? color : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Animated bar.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80 * value + 4,
                        decoration: BoxDecoration(
                          color: isToday
                              ? color
                              : (stat.sessions > 0
                                    ? color.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.06)),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // Weekday label.
                  Text(
                    stat.weekdayLabel,
                    style: TextStyle(
                      color: isToday ? color : Colors.white38,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
