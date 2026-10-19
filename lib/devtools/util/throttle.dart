import 'dart:async';

/// Runs [action] at once, then at most once per [interval] while calls keep coming — the last call is never dropped.
class Throttle {
  Throttle(this.interval, this.action);

  final Duration interval;
  final void Function() action;

  Timer? _timer;
  bool _pending = false;

  /// Runs [action] now, or once more when the current [interval] ends.
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

  /// Cancels the timer and drops any pending run.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = false;
  }
}
