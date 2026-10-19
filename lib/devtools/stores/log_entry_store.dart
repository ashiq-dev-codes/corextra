import 'package:flutter/foundation.dart';

import '../models/log_entry.dart';

/// The log lines DevTools has captured, oldest first, capped at [maxEntries].
///
/// Example:
/// ```dart
/// final entries = CorextraDevTools.instance.logs.entries;
/// print('${entries.length} logs captured');
/// ```
class LogEntryStore extends ChangeNotifier {
  /// Creates a store that keeps the newest [maxEntries] log lines.
  LogEntryStore({this.maxEntries = 500});

  // ---------------- Data ----------------

  /// The most log lines kept; the oldest is dropped when a new one arrives.
  final int maxEntries;

  final List<LogEntry> _entries = [];

  /// Every captured log line in capture order, oldest first.
  ///
  /// Example:
  /// ```dart
  /// final errors = CorextraDevTools.instance.logs.entries.where((e) => e.level == LogLevel.error);
  /// ```
  List<LogEntry> get entries => List.unmodifiable(_entries);

  // ---------------- Recording ----------------

  /// Adds a log line; `debugLog` and `AppLogger` already call this for you.
  ///
  /// Example:
  /// ```dart
  /// CorextraDevTools.instance.logs.add(
  ///   LogEntry(message: 'Cache cleared', level: LogLevel.info, timestamp: DateTime.now()),
  /// );
  /// ```
  void add(LogEntry entry) {
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    notifyListeners();
  }

  /// Removes every captured log line.
  ///
  /// Example:
  /// ```dart
  /// CorextraDevTools.instance.logs.clear();
  /// ```
  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
