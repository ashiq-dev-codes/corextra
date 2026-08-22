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
///
/// For non-string [data] (typically a JSON-decoded Map/List), that
/// string form is [prettyFormatBody]'s *indented* rendering, not
/// [Object.toString] — a truncated Map/List can never be valid JSON
/// again (the cut necessarily leaves it unbalanced), so once
/// truncated it can never be pretty-printed again either; deciding
/// the cut point against the plain `toString()` (Dart's `{key:
/// value}` syntax, no indentation) would have permanently frozen a
/// large body into that single unreadable line. Pretty-printing
/// first means the visible, truncated prefix is still properly
/// indented, multi-line JSON, right up to the cutoff.
Object? truncateBody(Object? data, int maxLength) {
  if (data == null) return null;
  final asString = data is String ? data : prettyFormatBody(data);
  if (asString.length <= maxLength) return data;
  return '${asString.substring(0, maxLength)}… [truncated, ${asString.length} chars total]';
}
