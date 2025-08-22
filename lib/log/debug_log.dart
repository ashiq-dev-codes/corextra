import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Logging levels
enum LogLevel { info, warning, error }

/// Logs messages to console in debug mode with optional level.
///
/// Example:
/// ```dart
/// debugLog('This is an info message');
/// debugLog('This is a warning', level: LogLevel.warning);
/// debugLog('This is an error', level: LogLevel.error);
/// ```
void debugLog(String message, {LogLevel level = LogLevel.info}) {
  if (kDebugMode) {
    log('[${level.name.toUpperCase()}] $message');
  }
}
