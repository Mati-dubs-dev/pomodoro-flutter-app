import 'dart:async';

class TimerService {
  Timer? _timer;

  Duration _duration = Duration.zero;
  Duration _remaining = Duration.zero;

  DateTime? _endTime;

  void Function(Duration remaining)? _onTick;
  void Function()? _onFinish;

  bool _isPaused = false;
  Duration _pausedRemaining = Duration.zero;

  bool get isActive => _timer?.isActive ?? false;
  bool get isPaused => _isPaused;

  Duration get remaining => _remaining;
  Duration get duration => _duration;

  /// endTime actual, útil para persistirlo externamente.
  DateTime? get endTime => _endTime;

  void start({
    required Duration duration,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  }) {
    stop();

    _duration = duration;
    _remaining = duration;
    _onTick = onTick;
    _onFinish = onFinish;
    _isPaused = false;

    _endTime = DateTime.now().add(duration);

    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  /// Reanuda el timer usando un endTime ya conocido (restaurado desde storage).
  /// Útil para reconstruir el estado tras un reinicio de la app.
  void startFromEndTime({
    required DateTime endTime,
    required void Function(Duration remaining) onTick,
    void Function()? onFinish,
  }) {
    stop();

    final remaining = endTime.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      // El timer ya habría terminado mientras la app estaba cerrada
      onFinish?.call();
      return;
    }

    _duration = remaining;
    _remaining = remaining;
    _onTick = onTick;
    _onFinish = onFinish;
    _isPaused = false;
    _endTime = endTime;

    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (_isPaused || _endTime == null) return;

    final now = DateTime.now();
    final remaining = _endTime!.difference(now);

    if (remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _onTick?.call(_remaining);
      _onFinish?.call();
      stop();
      return;
    }

    _remaining = remaining;
    _onTick?.call(_remaining);
  }

  void pause() {
    if (!isActive || _isPaused) return;
    _isPaused = true;
    _pausedRemaining = _remaining;
  }

  void resume() {
    if (!isActive || !_isPaused) return;
    _isPaused = false;
    _endTime = DateTime.now().add(_pausedRemaining);
  }

  void restart() {
    if (_duration == Duration.zero || _onTick == null) return;
    start(duration: _duration, onTick: _onTick!, onFinish: _onFinish);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isPaused = false;
    _endTime = null;
  }

  void dispose() {
    stop();
    _onTick = null;
    _onFinish = null;
  }
}