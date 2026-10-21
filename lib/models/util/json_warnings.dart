import 'package:flutter/foundation.dart';

import '../../logs/deferred_log.dart';
import '../json_model/corextra_json_model.dart';

// ---------------- Warnings ----------------

/// Where model warnings go; tests swap it to read them.
@visibleForTesting
void Function(String Function() message) jsonModelWarningSink = _log;

// Model type and key pairs already reported, so a list of 100 bad items warns once.
final Set<String> _warned = {};

/// In debug builds, warns once per model type and key that [raw] exists but couldn't be read as [expected].
void warnUnreadable(
  Object model,
  String key,
  Object? raw,
  Type expected, {
  Object? error,
}) {
  if (!kDebugMode || !CorextraJsonModel.debugWarnings) return;
  // Missing and blank values are normal for optional fields, so they aren't worth a warning.
  if (raw == null || raw is String && raw.trim().isEmpty) return;
  final type = model.runtimeType;
  if (!_warned.add('$type.$key')) return;
  jsonModelWarningSink(() {
    final reason = error == null ? '' : ' ($error)';
    return '$type: "$key" should be $expected, but the JSON has ${_describe(raw)}$reason. It reads as null.';
  });
}

/// Forgets which warnings were shown, so each test starts clean.
@visibleForTesting
void resetJsonModelWarnings() => _warned.clear();

// ---------------- Private helpers ----------------

void _log(String Function() message) => deferredLog(message, name: 'corextra');

String _describe(Object raw) {
  return switch (raw) {
    String() => 'text "${raw.length > 40 ? '${raw.substring(0, 40)}…' : raw}"',
    num() || bool() => '$raw',
    Map() => 'an object',
    Iterable() => 'a list',
    _ => 'a ${raw.runtimeType}',
  };
}
