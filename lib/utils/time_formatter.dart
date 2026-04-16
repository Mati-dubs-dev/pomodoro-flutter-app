/// Formatea [seconds] en el formato "MM:SS".
String formatTime(int seconds) {
  final mins = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$mins:$secs';
}

/// Devuelve una descripción legible de una cantidad de minutos.
/// Ej.: 90 → "1h 30m", 25 → "25m".
String formatMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}