import 'dart:developer';

import 'package:corextra/devtools/devtools_controller.dart';
import 'package:corextra/devtools/models/log_entry.dart';
import 'package:corextra/logs/enum/log_level.dart';
import 'package:flutter/foundation.dart';

/// Logs messages to console in debug mode with optional level.
///
/// Also feeds the DevTools Logs tab (see [CorextraDevTools]) whenever
/// devtools capture is enabled.
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

  if (CorextraDevTools.instance.enabled) {
    CorextraDevTools.instance.logs.add(
      LogEntry(message: message, level: level, timestamp: DateTime.now()),
    );
  }
}
