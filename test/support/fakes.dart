import 'package:pomodoro_pro/models/timer_mode.dart';
import 'package:pomodoro_pro/services/audio_service.dart';
import 'package:pomodoro_pro/services/notification_service.dart';
import 'package:pomodoro_pro/services/timer_service.dart';

class FakeTimerDriver implements TimerDriver {
  void Function(Duration remaining)? _onTick;
  void Function()? _onFinish;
  bool _active = false;
  bool _paused = false;
  Duration _remaining = Duration.zero;
  DateTime? _endTime;

  @override
  bool get isActive => _active;
  @override
  bool get isPaused => _paused;
  @override
  Duration get remaining => _remaining;
  @override
  DateTime? get endTime => _endTime;

  @override
  void start({
    required Duration duration,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  }) {
    _active = true;
    _paused = false;
    _remaining = duration;
    _endTime = DateTime.now().add(duration);
    _onTick = onTick;
    _onFinish = onFinish;
  }

  @override
  void startFromEndTime({
    required DateTime endTime,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  }) {
    _active = true;
    _paused = false;
    _endTime = endTime;
    _remaining = endTime.difference(DateTime.now());
    _onTick = onTick;
    _onFinish = onFinish;
  }

  void tick(Duration remaining) {
    _remaining = remaining;
    _onTick?.call(remaining);
  }

  void finish() {
    _remaining = Duration.zero;
    _active = false;
    _onTick?.call(Duration.zero);
    _onFinish?.call();
  }

  @override
  void pause() {
    _paused = true;
  }

  @override
  void resume() {
    _paused = false;
    _active = true;
    _endTime = DateTime.now().add(_remaining);
  }

  @override
  void stop() {
    _active = false;
    _paused = false;
    _endTime = null;
  }

  @override
  void dispose() => stop();
}

class FakeAudio implements PomodoroAudio {
  int focusSounds = 0;
  int breakSounds = 0;

  @override
  Future<void> playSessionComplete() async => focusSounds += 1;
  @override
  Future<void> playBreakComplete() async => breakSounds += 1;
  @override
  Future<void> dispose() async {}
}

class FakeNotifications implements PomodoroNotifications {
  int scheduled = 0;
  int cancelled = 0;
  int permissionRequests = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    permissionRequests += 1;
    return true;
  }

  @override
  Future<void> scheduleTimerEnd({
    required DateTime endTime,
    required TimerMode mode,
    required int completedSessions,
  }) async {
    scheduled += 1;
  }

  @override
  Future<void> cancelTimerEnd() async => cancelled += 1;
}
