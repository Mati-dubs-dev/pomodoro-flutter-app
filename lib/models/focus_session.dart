class FocusSession {
  final String id;
  final DateTime completedAt;
  final int focusMinutes;
  final String task;

  const FocusSession({
    required this.id,
    required this.completedAt,
    required this.focusMinutes,
    required this.task,
  });

  String get displayTask =>
      task.trim().isEmpty ? 'Sesión sin tarea' : task.trim();

  FocusSession copyWith({String? task}) {
    return FocusSession(
      id: id,
      completedAt: completedAt,
      focusMinutes: focusMinutes,
      task: task ?? this.task,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'completedAt': completedAt.toIso8601String(),
    'focusMinutes': focusMinutes,
    'task': task,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      focusMinutes: (json['focusMinutes'] as num).toInt(),
      task: json['task'] as String? ?? '',
    );
  }
}
