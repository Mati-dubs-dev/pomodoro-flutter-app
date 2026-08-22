import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class PomodoroAudio {
  Future<void> playSessionComplete();
  Future<void> playBreakComplete();
  Future<void> dispose();
}

class AudioService implements PomodoroAudio {
  @override
  Future<void> playSessionComplete() => _play(SystemSoundType.alert);

  @override
  Future<void> playBreakComplete() => _play(SystemSoundType.click);

  Future<void> _play(SystemSoundType type) async {
    try {
      await SystemSound.play(type);
    } on Object catch (error) {
      debugPrint('Could not play the timer sound: $error');
    }
  }

  @override
  Future<void> dispose() async {}
}
