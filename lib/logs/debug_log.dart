import 'dart:developer';

import 'package:corextra/logs/enum/log_level.dart';
import 'package:flutter/foundation.dart';

/// Logs messages to console in debug mode with optional level.
///
/// Example:
/// ```dart
/// debugLog('This is an info message');
/// debugLog('This is a warning', level: LogLevel.warning);
/// debugLog('This is an error', level: LogLevel.error);
/// ```
void debugLog(String message, {LogLevel level = LogLevel.info}) {
  if (!kDebugMode) return;
  log('[${level.name.toUpperCase()}] $message');
}
