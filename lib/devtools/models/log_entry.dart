import 'package:corextra/logs/enum/log_level.dart';

/// A single log line captured for the DevTools Logs tab.
class LogEntry {
  const LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  final String message;
  final LogLevel level;
  final DateTime timestamp;
}
