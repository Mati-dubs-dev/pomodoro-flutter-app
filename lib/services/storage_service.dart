import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_stat.dart';

/// Servicio de persistencia usando SharedPreferences.
/// Los valores de configuración y sesión se cachean en memoria al inicializar,
/// eliminando lecturas síncronas repetidas a SharedPreferences en cada getter.
class StorageService {
  // ── Claves ─────────────────────────────────────────────────────────────────
  static const _kSessions = 'completed_sessions';
  static const _kLastDate = 'last_date';
  static const _kFocusMinutes = 'focus_minutes_today';
  static const _kWeeklyStats = 'weekly_stats';

  static const _kPomodoroDuration = 'pomodoro_duration';
  static const _kShortBreakDuration = 'short_break_duration';
  static const _kLongBreakDuration = 'long_break_duration';
  static const _kDailyGoal = 'daily_goal';
  static const _kAutoStartBreaks = 'auto_start_breaks';
  static const _kAutoStartPomodoros = 'auto_start_pomodoros';
  static const _kSoundEnabled = 'sound_enabled';

  // ── BUG 4 FIX: persistencia del endTime para sobrevivir cierres de app ────
  static const _kTimerEndTime = 'timer_end_time';
  // ─────────────────────────────────────────────────────────────────────────

  final SharedPreferences _prefs;

  // ── BUG 3 FIX: cache en memoria — evita leer SharedPreferences en cada getter
  late int _pomodoroDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  late int _dailyGoal;
  late bool _autoStartBreaks;
  late bool _autoStartPomodoros;
  late bool _soundEnabled;

  // Cache de sesiones del día
  late int _completedSessions;
  late int _focusMinutesToday;
  late String? _lastDate;
  // ─────────────────────────────────────────────────────────────────────────

  StorageService._(this._prefs) {
    _loadCache();
  }

  /// Carga todos los valores en memoria una única vez al construir el servicio.
  void _loadCache() {
    _pomodoroDuration = _prefs.getInt(_kPomodoroDuration) ?? 25;
    _shortBreakDuration = _prefs.getInt(_kShortBreakDuration) ?? 5;
    _longBreakDuration = _prefs.getInt(_kLongBreakDuration) ?? 15;
    _dailyGoal = _prefs.getInt(_kDailyGoal) ?? 8;
    _autoStartBreaks = _prefs.getBool(_kAutoStartBreaks) ?? false;
    _autoStartPomodoros = _prefs.getBool(_kAutoStartPomodoros) ?? false;
    _soundEnabled = _prefs.getBool(_kSoundEnabled) ?? true;

    _lastDate = _prefs.getString(_kLastDate);
    if (_lastDate == _todayKey) {
      _completedSessions = _prefs.getInt(_kSessions) ?? 0;
      _focusMinutesToday = _prefs.getInt(_kFocusMinutes) ?? 0;
    } else {
      _completedSessions = 0;
      _focusMinutesToday = 0;
    }
  }

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  String get _todayKey => _dateKey(DateTime.now());
  String _dateKey(DateTime d) => d.toIso8601String().substring(0, 10);

  // ── Sesiones ───────────────────────────────────────────────────────────────

  /// Sesiones completadas hoy. Devuelve el valor cacheado (0 si cambió el día).
  int get completedSessions => _completedSessions;

  /// Minutos de foco acumulados hoy. Devuelve el valor cacheado.
  int get focusMinutesToday => _focusMinutesToday;

  /// Registra la finalización de una sesión Pomodoro.
  Future<void> recordCompletedSession({
    required int totalSessions,
    required int pomodoroMinutes,
  }) async {
    final today = _todayKey;
    final previousDate = _lastDate;

    // Si cambió el día, archivar datos previos en el historial
    if (previousDate != null && previousDate != today) {
      await _archiveDayStats(previousDate);
    }

    final prevMinutes = (previousDate == today) ? _focusMinutesToday : 0;
    final newMinutes = prevMinutes + pomodoroMinutes;

    await _prefs.setString(_kLastDate, today);
    await _prefs.setInt(_kSessions, totalSessions);
    await _prefs.setInt(_kFocusMinutes, newMinutes);

    // Actualizar cache
    _lastDate = today;
    _completedSessions = totalSessions;
    _focusMinutesToday = newMinutes;

    // Actualizar también el historial semanal con datos de hoy
    await _updateWeeklyStat(today, totalSessions, newMinutes);
  }

  Future<void> _archiveDayStats(String dateKey) async {
    await _updateWeeklyStat(dateKey, _completedSessions, _focusMinutesToday);
  }

  Future<void> _updateWeeklyStat(
      String dateKey, int sessions, int minutes) async {
    final raw = _prefs.getString(_kWeeklyStats);
    final Map<String, dynamic> stats =
        raw != null ? Map.from(jsonDecode(raw)) : {};

    stats[dateKey] = {'sessions': sessions, 'minutes': minutes};

    // Conservar solo los últimos 30 días
    final keys = stats.keys.toList()..sort();
    if (keys.length > 30) {
      for (final k in keys.take(keys.length - 30)) {
        stats.remove(k);
      }
    }

    await _prefs.setString(_kWeeklyStats, jsonEncode(stats));
  }

  /// Devuelve las estadísticas de los últimos 7 días (hoy incluido).
  List<DailyStat> getWeeklyStats() {
    final raw = _prefs.getString(_kWeeklyStats);
    final Map<String, dynamic> stats =
        raw != null ? Map.from(jsonDecode(raw)) : {};

    final today = DateTime.now();
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final key = _dateKey(date);

      if (i == 6) {
        return DailyStat(
          date: date,
          sessions: _completedSessions,
          focusMinutes: _focusMinutesToday,
        );
      }

      final data = stats[key];
      return DailyStat(
        date: date,
        sessions: (data?['sessions'] as int?) ?? 0,
        focusMinutes: (data?['minutes'] as int?) ?? 0,
      );
    });
  }

  // ── BUG 4 FIX: persistencia del endTime ────────────────────────────────────

  /// Guarda el momento exacto en que el timer debe terminar.
  /// Permite reconstruir el tiempo restante si la app se cierra y reabre.
  Future<void> saveTimerEndTime(DateTime endTime) async {
    await _prefs.setString(_kTimerEndTime, endTime.toIso8601String());
  }

  /// Elimina el endTime guardado (al pausar, resetear o completar).
  Future<void> clearTimerEndTime() async {
    await _prefs.remove(_kTimerEndTime);
  }

  /// Devuelve el endTime persistido si aún está en el futuro, o null.
  DateTime? get savedTimerEndTime {
    final raw = _prefs.getString(_kTimerEndTime);
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null || dt.isBefore(DateTime.now())) return null;
    return dt;
  }

  // ─────────────────────────────────────────────────────────────────────────

  // ── Configuración ──────────────────────────────────────────────────────────

  int get pomodoroDuration => _pomodoroDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get dailyGoal => _dailyGoal;
  bool get autoStartBreaks => _autoStartBreaks;
  bool get autoStartPomodoros => _autoStartPomodoros;
  bool get soundEnabled => _soundEnabled;

  Future<void> saveSettings({
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? dailyGoal,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? soundEnabled,
  }) async {
    if (pomodoroDuration != null) {
      await _prefs.setInt(_kPomodoroDuration, pomodoroDuration);
      _pomodoroDuration = pomodoroDuration;
    }
    if (shortBreakDuration != null) {
      await _prefs.setInt(_kShortBreakDuration, shortBreakDuration);
      _shortBreakDuration = shortBreakDuration;
    }
    if (longBreakDuration != null) {
      await _prefs.setInt(_kLongBreakDuration, longBreakDuration);
      _longBreakDuration = longBreakDuration;
    }
    if (dailyGoal != null) {
      await _prefs.setInt(_kDailyGoal, dailyGoal);
      _dailyGoal = dailyGoal;
    }
    if (autoStartBreaks != null) {
      await _prefs.setBool(_kAutoStartBreaks, autoStartBreaks);
      _autoStartBreaks = autoStartBreaks;
    }
    if (autoStartPomodoros != null) {
      await _prefs.setBool(_kAutoStartPomodoros, autoStartPomodoros);
      _autoStartPomodoros = autoStartPomodoros;
    }
    if (soundEnabled != null) {
      await _prefs.setBool(_kSoundEnabled, soundEnabled);
      _soundEnabled = soundEnabled;
    }
  }

  // ── Setters individuales (para compatibilidad con PomodoroNotifier) ────────

  Future<void> setPomodoroDuration(int value) async =>
      saveSettings(pomodoroDuration: value);

  Future<void> setShortBreakDuration(int value) async =>
      saveSettings(shortBreakDuration: value);

  Future<void> setLongBreakDuration(int value) async =>
      saveSettings(longBreakDuration: value);

  Future<void> setDailyGoal(int value) async =>
      saveSettings(dailyGoal: value);

  Future<void> setAutoStartBreaks(bool value) async =>
      saveSettings(autoStartBreaks: value);

  Future<void> setAutoStartPomodoros(bool value) async =>
      saveSettings(autoStartPomodoros: value);

  Future<void> setSoundEnabled(bool value) async =>
      saveSettings(soundEnabled: value);
}