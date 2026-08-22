import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_stat.dart';
import '../models/focus_session.dart';
import '../models/timer_mode.dart';
import '../models/timer_snapshot.dart';

typedef Clock = DateTime Function();

class StorageService {
  static const _kSessions = 'completed_sessions';
  static const _kLastDate = 'last_date';
  static const _kFocusMinutes = 'focus_minutes_today';
  static const _kDailyStats = 'weekly_stats';
  static const _kFocusSessions = 'focus_sessions_v1';

  static const _kPomodoroDuration = 'pomodoro_duration';
  static const _kShortBreakDuration = 'short_break_duration';
  static const _kLongBreakDuration = 'long_break_duration';
  static const _kDailyGoal = 'daily_goal';
  static const _kAutoStartBreaks = 'auto_start_breaks';
  static const _kAutoStartPomodoros = 'auto_start_pomodoros';
  static const _kSoundEnabled = 'sound_enabled';
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kHapticsEnabled = 'haptics_enabled';

  static const _kTimerSnapshot = 'timer_snapshot_v1';
  static const _kLegacyTimerEndTime = 'timer_end_time';

  final SharedPreferences _prefs;
  final Clock _now;

  late int _pomodoroDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  late int _dailyGoal;
  late bool _autoStartBreaks;
  late bool _autoStartPomodoros;
  late bool _soundEnabled;
  late bool _notificationsEnabled;
  late bool _hapticsEnabled;

  late int _completedSessions;
  late int _focusMinutesToday;
  late String? _lastDate;
  final Map<String, dynamic> _dailyStats = {};
  final List<FocusSession> _focusSessions = [];

  StorageService._(this._prefs, this._now);

  static Future<StorageService> create({Clock? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService._(prefs, now ?? DateTime.now);
    service._loadCache();
    await service.rolloverIfNeeded();
    return service;
  }

  void _loadCache() {
    _pomodoroDuration = _prefs.getInt(_kPomodoroDuration) ?? 25;
    _shortBreakDuration = _prefs.getInt(_kShortBreakDuration) ?? 5;
    _longBreakDuration = _prefs.getInt(_kLongBreakDuration) ?? 15;
    _dailyGoal = _prefs.getInt(_kDailyGoal) ?? 8;
    _autoStartBreaks = _prefs.getBool(_kAutoStartBreaks) ?? false;
    _autoStartPomodoros = _prefs.getBool(_kAutoStartPomodoros) ?? false;
    _soundEnabled = _prefs.getBool(_kSoundEnabled) ?? true;
    _notificationsEnabled = _prefs.getBool(_kNotificationsEnabled) ?? true;
    _hapticsEnabled = _prefs.getBool(_kHapticsEnabled) ?? true;

    _lastDate = _prefs.getString(_kLastDate);
    _completedSessions = _prefs.getInt(_kSessions) ?? 0;
    _focusMinutesToday = _prefs.getInt(_kFocusMinutes) ?? 0;

    final rawStats = _prefs.getString(_kDailyStats);
    if (rawStats != null) {
      try {
        _dailyStats.addAll(Map<String, dynamic>.from(jsonDecode(rawStats)));
      } on Object {
        _dailyStats.clear();
      }
    }

    final rawSessions = _prefs.getString(_kFocusSessions);
    if (rawSessions != null) {
      try {
        final decoded = jsonDecode(rawSessions) as List<dynamic>;
        _focusSessions.addAll(
          decoded.map(
            (item) =>
                FocusSession.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      } on Object {
        _focusSessions.clear();
      }
    }
  }

  String get _todayKey => _dateKey(_now());
  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<bool> rolloverIfNeeded() async {
    final today = _todayKey;
    if (_lastDate == today) return false;

    final previousDate = _lastDate;
    if (previousDate != null) {
      _dailyStats[previousDate] = {
        'sessions': _completedSessions,
        'minutes': _focusMinutesToday,
      };
    }

    _lastDate = today;
    _completedSessions = 0;
    _focusMinutesToday = 0;

    await Future.wait([
      _prefs.setString(_kLastDate, today),
      _prefs.setInt(_kSessions, 0),
      _prefs.setInt(_kFocusMinutes, 0),
      _saveDailyStats(),
    ]);
    return true;
  }

  int get completedSessions => _completedSessions;
  int get focusMinutesToday => _focusMinutesToday;
  List<FocusSession> get focusSessions => List.unmodifiable(_focusSessions);

  Future<FocusSession> recordCompletedSession({
    required int pomodoroMinutes,
    required String task,
  }) async {
    await rolloverIfNeeded();
    final completedAt = _now();
    _completedSessions += 1;
    _focusMinutesToday += pomodoroMinutes;

    final session = FocusSession(
      id: '${completedAt.microsecondsSinceEpoch}-${_focusSessions.length}',
      completedAt: completedAt,
      focusMinutes: pomodoroMinutes,
      task: task.trim(),
    );
    _focusSessions.insert(0, session);
    if (_focusSessions.length > 300) {
      _focusSessions.removeRange(300, _focusSessions.length);
    }

    _dailyStats[_todayKey] = {
      'sessions': _completedSessions,
      'minutes': _focusMinutesToday,
    };

    await Future.wait([
      _prefs.setInt(_kSessions, _completedSessions),
      _prefs.setInt(_kFocusMinutes, _focusMinutesToday),
      _prefs.setString(_kLastDate, _todayKey),
      _saveDailyStats(),
      _saveFocusSessions(),
    ]);
    return session;
  }

  List<DailyStat> getDailyStats({int days = 7, int offsetDays = 0}) {
    final today = _now();
    return List.generate(days, (index) {
      final daysAgo = offsetDays + (days - 1 - index);
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: daysAgo));
      final key = _dateKey(date);
      final data = _dailyStats[key] as Map<String, dynamic>?;
      return DailyStat(
        date: date,
        sessions: key == _todayKey
            ? _completedSessions
            : (data?['sessions'] as num?)?.toInt() ?? 0,
        focusMinutes: key == _todayKey
            ? _focusMinutesToday
            : (data?['minutes'] as num?)?.toInt() ?? 0,
      );
    });
  }

  List<DailyStat> getWeeklyStats() => getDailyStats();

  Future<void> renameFocusSession(String id, String task) async {
    final index = _focusSessions.indexWhere((session) => session.id == id);
    if (index == -1) return;
    _focusSessions[index] = _focusSessions[index].copyWith(task: task.trim());
    await _saveFocusSessions();
  }

  Future<bool> deleteFocusSession(String id) async {
    final index = _focusSessions.indexWhere((session) => session.id == id);
    if (index == -1) return false;
    final removed = _focusSessions.removeAt(index);
    final key = _dateKey(removed.completedAt);
    final existing = _dailyStats[key] as Map<String, dynamic>?;
    final sessions = ((existing?['sessions'] as num?)?.toInt() ?? 0) - 1;
    final minutes =
        ((existing?['minutes'] as num?)?.toInt() ?? 0) - removed.focusMinutes;
    final safeSessions = sessions.clamp(0, 1 << 30);
    final safeMinutes = minutes.clamp(0, 1 << 30);
    _dailyStats[key] = {'sessions': safeSessions, 'minutes': safeMinutes};

    final writes = <Future<bool>>[];
    if (key == _todayKey) {
      _completedSessions = safeSessions;
      _focusMinutesToday = safeMinutes;
      writes.add(_prefs.setInt(_kSessions, _completedSessions));
      writes.add(_prefs.setInt(_kFocusMinutes, _focusMinutesToday));
    }
    await Future.wait([...writes, _saveDailyStats(), _saveFocusSessions()]);
    return true;
  }

  Future<bool> _saveDailyStats() async {
    final keys = _dailyStats.keys.toList()..sort();
    if (keys.length > 90) {
      for (final key in keys.take(keys.length - 90)) {
        _dailyStats.remove(key);
      }
    }
    return _prefs.setString(_kDailyStats, jsonEncode(_dailyStats));
  }

  Future<bool> _saveFocusSessions() => _prefs.setString(
    _kFocusSessions,
    jsonEncode(_focusSessions.map((session) => session.toJson()).toList()),
  );

  Future<void> saveTimerSnapshot({
    DateTime? endTime,
    required TimerMode mode,
    required String task,
    bool isPaused = false,
    int? remainingSeconds,
  }) async {
    final snapshot = TimerSnapshot(
      endTime: endTime,
      mode: mode,
      task: task,
      isPaused: isPaused,
      remainingSeconds: remainingSeconds,
    );
    await _prefs.setString(_kTimerSnapshot, jsonEncode(snapshot.toJson()));
    await _prefs.remove(_kLegacyTimerEndTime);
  }

  Future<void> clearTimerSnapshot() async {
    await Future.wait([
      _prefs.remove(_kTimerSnapshot),
      _prefs.remove(_kLegacyTimerEndTime),
    ]);
  }

  TimerSnapshot? get savedTimerSnapshot {
    final raw = _prefs.getString(_kTimerSnapshot);
    if (raw != null) {
      try {
        return TimerSnapshot.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } on Object {
        return null;
      }
    }

    final legacy = _prefs.getString(_kLegacyTimerEndTime);
    final endTime = legacy == null ? null : DateTime.tryParse(legacy);
    if (endTime == null) return null;
    return TimerSnapshot(endTime: endTime, mode: TimerMode.pomodoro, task: '');
  }

  int get pomodoroDuration => _pomodoroDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get dailyGoal => _dailyGoal;
  bool get autoStartBreaks => _autoStartBreaks;
  bool get autoStartPomodoros => _autoStartPomodoros;
  bool get soundEnabled => _soundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> saveSettings({
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? dailyGoal,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? hapticsEnabled,
  }) async {
    final writes = <Future<bool>>[];
    if (pomodoroDuration != null) {
      _pomodoroDuration = pomodoroDuration;
      writes.add(_prefs.setInt(_kPomodoroDuration, pomodoroDuration));
    }
    if (shortBreakDuration != null) {
      _shortBreakDuration = shortBreakDuration;
      writes.add(_prefs.setInt(_kShortBreakDuration, shortBreakDuration));
    }
    if (longBreakDuration != null) {
      _longBreakDuration = longBreakDuration;
      writes.add(_prefs.setInt(_kLongBreakDuration, longBreakDuration));
    }
    if (dailyGoal != null) {
      _dailyGoal = dailyGoal;
      writes.add(_prefs.setInt(_kDailyGoal, dailyGoal));
    }
    if (autoStartBreaks != null) {
      _autoStartBreaks = autoStartBreaks;
      writes.add(_prefs.setBool(_kAutoStartBreaks, autoStartBreaks));
    }
    if (autoStartPomodoros != null) {
      _autoStartPomodoros = autoStartPomodoros;
      writes.add(_prefs.setBool(_kAutoStartPomodoros, autoStartPomodoros));
    }
    if (soundEnabled != null) {
      _soundEnabled = soundEnabled;
      writes.add(_prefs.setBool(_kSoundEnabled, soundEnabled));
    }
    if (notificationsEnabled != null) {
      _notificationsEnabled = notificationsEnabled;
      writes.add(_prefs.setBool(_kNotificationsEnabled, notificationsEnabled));
    }
    if (hapticsEnabled != null) {
      _hapticsEnabled = hapticsEnabled;
      writes.add(_prefs.setBool(_kHapticsEnabled, hapticsEnabled));
    }
    await Future.wait(writes);
  }
}
