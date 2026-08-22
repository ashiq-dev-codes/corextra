import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Pretty-prints [data] as indented JSON for display in the DevTools
/// panel — the common case for an API request/response body. Falls
/// back to a short, readable summary for the two shapes JSON can't
/// represent meaningfully: raw bytes ([Uint8List], e.g. a
/// `ResponseType.bytes` download) and Dio's multipart [FormData]
/// request bodies. Anything else that isn't valid JSON (plain text,
/// HTML, XML, ...) is shown as-is via [Object.toString].
String prettyFormatBody(Object? data) {
  if (data == null) return 'null';
  if (data is Uint8List) return _formatBytes(data);
  if (data is FormData) return _formatFormData(data);
  try {
    final value = data is String ? jsonDecode(data) : data;
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return data.toString();
  }
}

/// A byte count plus a short hex preview — the leading bytes are
/// often enough to recognize the format (e.g. a PNG's `89 50 4e 47`)
/// without dumping the whole payload as a JSON array of numbers,
/// which [JsonEncoder] would otherwise happily (and uselessly) do,
/// since a byte list satisfies it just as well as a real JSON array.
String _formatBytes(Uint8List bytes) {
  final preview = bytes
      .take(16)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ');
  final ellipsis = bytes.length > 16 ? '…' : '';
  return '<binary data, ${bytes.length} bytes>\n'
      'first bytes (hex): $preview$ellipsis';
}

/// [FormData] doesn't override [Object.toString], so left to the
/// generic fallback it shows nothing but `Instance of 'FormData'`.
/// This instead surfaces the actual field values and file metadata
/// (name, filename, content type, byte length) as pretty JSON.
String _formatFormData(FormData data) {
  final summary = <String, dynamic>{
    if (data.fields.isNotEmpty)
      'fields': {for (final field in data.fields) field.key: field.value},
    if (data.files.isNotEmpty)
      'files': [
        for (final file in data.files)
          {
            'field': file.key,
            'filename': file.value.filename,
            'contentType': file.value.contentType?.toString(),
            'length': file.value.length,
          },
      ],
  };
  return const JsonEncoder.withIndent('  ').convert(summary);
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
///
/// Raw bytes and [FormData] are summarized unconditionally, before
/// the length check — [prettyFormatBody]'s summary for either is
/// already short regardless of the underlying payload's actual size
/// (a multi-megabyte download summarizes just as compactly as a
/// tiny one), so measuring *that* against [maxLength] would never
/// trip, and the raw bytes (or a live multipart stream) would sit in
/// the in-memory capture buffer at full size indefinitely — exactly
/// what this function exists to prevent.
Object? truncateBody(Object? data, int maxLength) {
  if (data == null) return null;
  if (data is Uint8List || data is FormData) return prettyFormatBody(data);
  final asString = data is String ? data : prettyFormatBody(data);
  if (asString.length <= maxLength) return data;
  return '${asString.substring(0, maxLength)}… [truncated, ${asString.length} chars total]';
}
