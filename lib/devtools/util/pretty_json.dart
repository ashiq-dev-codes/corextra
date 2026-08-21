import 'dart:convert';

/// Pretty-prints [data] as indented JSON for display in the DevTools
/// panel, falling back to [Object.toString] when it isn't valid JSON.
String prettyFormatBody(Object? data) {
  if (data == null) return 'null';
  try {
    final value = data is String ? jsonDecode(data) : data;
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return data.toString();
  }
}

/// Truncates [data]'s string form to [maxLength] characters, appending a
/// marker with the original length, so a single large body can't dominate
/// the in-memory capture buffers.
Object? truncateBody(Object? data, int maxLength) {
  if (data == null) return null;
  final asString = data is String ? data : data.toString();
  if (asString.length <= maxLength) return data;
  return '${asString.substring(0, maxLength)}… [truncated, ${asString.length} chars total]';
}
