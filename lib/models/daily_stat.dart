/// Estadísticas de un día específico.
class DailyStat {
  final DateTime date;
  final int sessions;
  final int focusMinutes;

  const DailyStat({
    required this.date,
    required this.sessions,
    required this.focusMinutes,
  });

  /// Nombre corto del día de la semana en español.
  String get weekdayLabel {
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return labels[date.weekday - 1];
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  String toString() =>
      'DailyStat(date: $date, sessions: $sessions, focusMinutes: $focusMinutes)';
}