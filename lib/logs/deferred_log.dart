import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;

const _maxPending = 500;

// Short enough to slot between frames without delaying one.
const _sliceBudget = Duration(milliseconds: 3);

final _pending = ListQueue<(String Function(), String)>();
var _draining = false;
var _dropped = 0;

/// Builds and prints [message] after the caller returns, in small slices between frames, so console logging never stalls a request or a frame.
void deferredLog(String Function() message, {String name = ''}) {
  if (_pending.length >= _maxPending) {
    _pending.removeFirst();
    _dropped++;
  }
  _pending.add((message, name));
  if (_draining) return;
  _draining = true;
  Timer.run(_drain);
}

void _drain() {
  final clock = Stopwatch()..start();
  while (_pending.isNotEmpty && clock.elapsed < _sliceBudget) {
    if (_dropped > 0) {
      dev.log(
        '… $_dropped older log entries skipped to keep the app responsive',
        name: 'corextra',
      );
      _dropped = 0;
    }
    final (message, name) = _pending.removeFirst();
    try {
      dev.log(message(), name: name);
    } catch (error) {
      dev.log('Could not format a log entry: $error', name: 'corextra');
    }
  }
  if (_pending.isEmpty) {
    _draining = false;
  } else {
    Timer.run(_drain);
  }
}
