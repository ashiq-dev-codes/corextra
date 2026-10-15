import 'dart:async';

/// Runs [action] at once, then at most once per [interval] while calls keep coming — the last call is never dropped.
class Throttle {
  Throttle(this.interval, this.action);

  final Duration interval;
  final void Function() action;

  Timer? _timer;
  bool _pending = false;

  void call() {
    if (_timer != null) {
      _pending = true;
      return;
    }
    action();
    _timer = Timer(interval, _onTick);
  }

  void _onTick() {
    _timer = null;
    if (!_pending) return;
    _pending = false;
    call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = false;
  }
}
