import 'package:flutter/material.dart';
import '../models/timer_mode.dart';

/// Mode selector (Pomodoro / Short break / Long break).
/// The active label uses the current mode color; inactive labels are muted.
class ModeSelector extends StatelessWidget {
  final TimerMode currentMode;
  final ValueChanged<TimerMode> onModeChanged;
  final Color color;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: TimerMode.values.map((mode) {
          final isSelected = currentMode == mode;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (mode != currentMode) {
                  onModeChanged(mode);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  mode.shortLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? color : Colors.white38,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
