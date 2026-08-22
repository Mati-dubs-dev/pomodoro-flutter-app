/// Statistics for a specific day.
class DailyStat {
  final DateTime date;
  final int sessions;
  final int focusMinutes;

  const DailyStat({
    required this.date,
    required this.sessions,
    required this.focusMinutes,
  });

  /// Short weekday label.
  String get weekdayLabel {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
