import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales para alertar al usuario
/// cuando finaliza una sesión o un descanso.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'pomodoro_timer';
  static const _channelName = 'Temporizador Pomodoro';
  static const _channelDesc = 'Avisos de sesiones y descansos completados';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    enableVibration: true,
    playSound: false, // El audio lo maneja AudioService
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    ),
  );

  // ── Inicialización ─────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Solicitar permiso en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Notificaciones ─────────────────────────────────────────────────────────

  /// Notificación cuando finaliza una sesión Pomodoro.
  static Future<void> showSessionComplete(int totalSessions) async {
    final plural = totalSessions == 1 ? 'sesión' : 'sesiones';
    await _plugin.show(
      0,
      '🍅 ¡Sesión completada!',
      'Llevas $totalSessions $plural hoy. ¡Tómate un descanso bien ganado!',
      _notificationDetails,
    );
  }

  /// Notificación cuando finaliza un descanso.
  static Future<void> showBreakComplete() async {
    await _plugin.show(
      1,
      '⏰ ¡Descanso terminado!',
      'Es hora de volver a trabajar. ¡Vamos, vos podés!',
      _notificationDetails,
    );
  }

  /// Cancela todas las notificaciones pendientes.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}