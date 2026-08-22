import 'timer_mode.dart';

class TimerSnapshot {
  final DateTime? endTime;
  final TimerMode mode;
  final String task;
  final bool isPaused;
  final int? remainingSeconds;

  const TimerSnapshot({
    required this.endTime,
    required this.mode,
    required this.task,
    this.isPaused = false,
    this.remainingSeconds,
  });

  Map<String, dynamic> toJson() => {
    'endTime': endTime?.toIso8601String(),
    'mode': mode.name,
    'task': task,
    'isPaused': isPaused,
    'remainingSeconds': remainingSeconds,
  };

  factory TimerSnapshot.fromJson(Map<String, dynamic> json) {
    return TimerSnapshot(
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      mode: TimerMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => TimerMode.pomodoro,
      ),
      task: json['task'] as String? ?? '',
      isPaused: json['isPaused'] as bool? ?? false,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
    );
  }
}
