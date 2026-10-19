import 'package:corextra/logs/enum/log_level.dart';

/// One log line shown in the DevTools Logs tab.
///
/// Example:
/// ```dart
/// for (final entry in CorextraDevTools.instance.logs.entries) {
///   print('[${entry.level.name}] ${entry.message}');
/// }
/// ```
class LogEntry {
  /// Creates a log line; `debugLog` and `AppLogger` make these for you.
  const LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  /// The logged text.
  final String message;

  /// How serious it is: info, warning or error.
  final LogLevel level;

  /// When it was logged.
  final DateTime timestamp;
}
