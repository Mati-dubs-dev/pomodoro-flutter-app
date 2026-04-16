import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // ← debugPrint oficial de Flutter

/// Servicio de audio para reproducir sonidos del temporizador.
/// Usa el paquete audioplayers ^6.x.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Sonido al completar una sesión Pomodoro.
  Future<void> playSessionComplete() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/session_complete.mp3'));
    } catch (e) {
      debugPrint('AudioService: error al reproducir session_complete — $e');
    }
  }

  /// Sonido al completar un descanso.
  Future<void> playBreakComplete() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/break_complete.mp3'));
    } catch (e) {
      debugPrint('AudioService: error al reproducir break_complete — $e');
    }
  }

  /// Tick opcional por segundo (puede deshabilitarse para ahorrar batería).
  Future<void> playTick() async {
    try {
      await _player.play(AssetSource('sounds/tick.mp3'));
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}