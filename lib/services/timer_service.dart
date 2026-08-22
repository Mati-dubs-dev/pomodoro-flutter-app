import 'dart:async';

abstract interface class TimerDriver {
  bool get isActive;
  bool get isPaused;
  Duration get remaining;
  DateTime? get endTime;

  void start({
    required Duration duration,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  });
  void startFromEndTime({
    required DateTime endTime,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  });
  void pause();
  void resume();
  void stop();
  void dispose();
}

class TimerService implements TimerDriver {
  final DateTime Function() _now;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  DateTime? _endTime;
  void Function(Duration remaining)? _onTick;
  void Function()? _onFinish;
  bool _isPaused = false;
  Duration _pausedRemaining = Duration.zero;

  TimerService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  bool get isActive => _timer?.isActive ?? false;
  @override
  bool get isPaused => _isPaused;
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
    stop();
    _remaining = duration;
    _onTick = onTick;
    _onFinish = onFinish;
    _endTime = _now().add(duration);
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void startFromEndTime({
    required DateTime endTime,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  }) {
    stop();
    final remaining = endTime.difference(_now());
    if (remaining <= Duration.zero) {
      onFinish?.call();
      return;
    }
    _remaining = remaining;
    _onTick = onTick;
    _onFinish = onFinish;
    _endTime = endTime;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_isPaused || _endTime == null) return;
    final remaining = _endTime!.difference(_now());
    if (remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _onTick?.call(Duration.zero);
      final onFinish = _onFinish;
      stop();
      onFinish?.call();
      return;
    }
    _remaining = remaining;
    _onTick?.call(remaining);
  }

  @override
  void pause() {
    if (!isActive || _isPaused) return;
    _isPaused = true;
    _pausedRemaining = _remaining;
  }

  @override
  void resume() {
    if (!isActive || !_isPaused) return;
    _isPaused = false;
    _endTime = _now().add(_pausedRemaining);
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isPaused = false;
    _endTime = null;
  }

  @override
  void dispose() {
    stop();
    _onTick = null;
    _onFinish = null;
  }
}
