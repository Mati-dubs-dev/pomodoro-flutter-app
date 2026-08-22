import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/timer_mode.dart';

abstract interface class PomodoroNotifications {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleTimerEnd({
    required DateTime endTime,
    required TimerMode mode,
    required int completedSessions,
  });
  Future<void> cancelTimerEnd();
}

class NotificationService implements PomodoroNotifications {
  static const timerNotificationId = 100;
  static const _channelId = 'pomodoro_timer';
  static const _channelName = 'Temporizador Pomodoro';
  static const _channelDesc = 'Avisos de sesiones y descansos completados';

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    ),
  );

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    if (!_isSupported) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final notificationsGranted =
            await android?.requestNotificationsPermission() ?? false;
        await android?.requestExactAlarmsPermission();
        return notificationsGranted;
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: false, sound: false) ??
            false;
      case TargetPlatform.macOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: false, sound: false) ??
            false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  Future<void> scheduleTimerEnd({
    required DateTime endTime,
    required TimerMode mode,
    required int completedSessions,
  }) async {
    if (!_isSupported) return;

    final isFocus = mode == TimerMode.pomodoro;
    final title = isFocus ? '¡Sesión completada!' : '¡Descanso terminado!';
    final body = isFocus
        ? 'Llevas ${completedSessions + 1} sesiones hoy. Es hora de descansar.'
        : 'Tu siguiente bloque de foco está listo.';

    final scheduledTime = tz.TZDateTime.from(endTime, tz.local);
    try {
      await _plugin.zonedSchedule(
        timerNotificationId,
        title,
        body,
        scheduledTime,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: mode.name,
      );
    } on Object {
      await _plugin.zonedSchedule(
        timerNotificationId,
        title,
        body,
        scheduledTime,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: mode.name,
      );
    }
  }

  @override
  Future<void> cancelTimerEnd() async {
    if (_isSupported) await _plugin.cancel(timerNotificationId);
  }
}
