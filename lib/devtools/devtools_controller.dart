import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'models/frame_sample.dart';
import 'models/log_entry.dart';
import 'models/network_event.dart';

/// Bounded, FIFO ring buffer of captured [NetworkEvent]s.
class NetworkEventStore extends ChangeNotifier {
  NetworkEventStore({this.maxEntries = 200});

  final int maxEntries;
  final List<NetworkEvent> _events = [];

  /// Most recent events first is left to consumers; this list is kept in
  /// capture order (oldest first).
  List<NetworkEvent> get events => List.unmodifiable(_events);

  /// Records the start of a request and returns the event so the caller
  /// can complete it later via [complete].
  NetworkEvent begin({
    required String method,
    required String url,
    Map<String, String> queryParameters = const {},
    Map<String, String> requestHeaders = const {},
    Object? requestBody,
  }) {
    final event = NetworkEvent(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_events.length}',
      method: method,
      url: url,
      startedAt: DateTime.now(),
      queryParameters: queryParameters,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
    );
    _events.add(event);
    while (_events.length > maxEntries) {
      _events.removeAt(0);
    }
    notifyListeners();
    return event;
  }

  /// Notifies listeners that [event] (already mutated in place by the
  /// caller with response/error fields) has completed.
  void complete(NetworkEvent event) {
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }
}

/// Bounded, FIFO ring buffer of captured [LogEntry]s.
class LogEntryStore extends ChangeNotifier {
  LogEntryStore({this.maxEntries = 500});

  final int maxEntries;
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void add(LogEntry entry) {
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

/// Bounded, FIFO ring buffer of captured [FrameSample]s.
class FrameSampleStore extends ChangeNotifier {
  FrameSampleStore({this.maxEntries = 300});

  final int maxEntries;
  final List<FrameSample> _samples = [];

  /// Approximate resident set size in bytes, if available on this
  /// platform; pushed in periodically from outside this store.
  int? lastRssBytes;

  List<FrameSample> get samples => List.unmodifiable(_samples);

  void add(FrameSample sample) {
    _samples.add(sample);
    while (_samples.length > maxEntries) {
      _samples.removeAt(0);
    }
    notifyListeners();
  }

  /// Average FPS over the most recent [window] samples (~1s at 60Hz).
  double get currentFps {
    if (_samples.isEmpty) return 60;
    final recent = _samples.length > 60
        ? _samples.sublist(_samples.length - 60)
        : _samples;
    final total = recent.fold<double>(0, (sum, s) => sum + s.fps);
    return total / recent.length;
  }

  int recentJankyCount({int window = 60}) {
    final recent = _samples.length > window
        ? _samples.sublist(_samples.length - window)
        : _samples;
    return recent.where((s) => s.isJanky).length;
  }

  void setRssBytes(int? bytes) {
    lastRssBytes = bytes;
    notifyListeners();
  }

  void clear() {
    _samples.clear();
    lastRssBytes = null;
    notifyListeners();
  }
}

/// Central, in-memory DevTools store for the current app run.
///
/// Everything captured here lives only in memory and defaults to
/// [kDebugMode] so it can never accidentally stay active in a release
/// build. Toggle at runtime with [enabled]:
/// ```dart
/// CorextraDevTools.instance.enabled = false;
/// ```
class CorextraDevTools {
  CorextraDevTools._internal();

  static final CorextraDevTools instance = CorextraDevTools._internal();

  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(kDebugMode);

  bool get enabled => enabledNotifier.value;

  set enabled(bool value) => enabledNotifier.value = value;

  /// The DevTools panel's own theme — independent of the host app's
  /// theme. Defaults to dark; toggle with a light/dark [ThemeMode] via
  /// the panel's theme switcher, or set directly:
  /// ```dart
  /// CorextraDevTools.instance.themeMode = ThemeMode.light;
  /// ```
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  ThemeMode get themeMode => themeModeNotifier.value;

  set themeMode(ThemeMode value) => themeModeNotifier.value = value;

  final NetworkEventStore network = NetworkEventStore();
  final LogEntryStore logs = LogEntryStore();
  final FrameSampleStore performance = FrameSampleStore();

  /// Clears all captured data. Does not change [enabled].
  void resetAll() {
    network.clear();
    logs.clear();
    performance.clear();
  }
}
