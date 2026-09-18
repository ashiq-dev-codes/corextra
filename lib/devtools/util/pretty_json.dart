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

/// Bounds [data] before capture, without pretty-printing a Map/List
/// just to measure it — that cost must stay lazy, paid only on open.
Object? truncateBody(Object? data, int maxLength) {
  if (data == null) return null;
  if (data is Uint8List || data is FormData) return prettyFormatBody(data);
  if (data is String && data.length > maxLength) {
    return '${data.substring(0, maxLength)}… [truncated, ${data.length} chars total]';
  }
  return data;
}

/// Like [prettyFormatBody], but bounds total work via [_boundForLogging]
/// for an eager caller with no later display step to defer cost to.
String boundedPrettyFormatBody(
  Object? data, {
  int budget = 2000,
  int maxListItems = 50,
  int maxStringLength = 2000,
}) {
  if (data == null) return 'null';
  if (data is Uint8List) return _formatBytes(data);
  if (data is FormData) return _formatFormData(data);
  Object? value;
  try {
    value = data is String ? jsonDecode(data) : data;
  } catch (_) {
    return data.toString();
  }
  final remaining = [budget];
  final bounded = _boundForLogging(
    value,
    remaining,
    maxListItems: maxListItems,
    maxStringLength: maxStringLength,
  );
  try {
    return const JsonEncoder.withIndent('  ').convert(bounded);
  } catch (_) {
    return bounded.toString();
  }
}

/// [remaining] is a shared 1-element counter every nested call decrements,
/// so the walk stops the instant the budget is spent, at any depth.
Object? _boundForLogging(
  Object? value,
  List<int> remaining, {
  required int maxListItems,
  required int maxStringLength,
}) {
  if (remaining[0] <= 0) return '…';
  remaining[0]--;

  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (remaining[0] <= 0) {
        result['…'] = '(budget exceeded, ${value.length} keys total)';
        break;
      }
      result[entry.key.toString()] = _boundForLogging(
        entry.value,
        remaining,
        maxListItems: maxListItems,
        maxStringLength: maxStringLength,
      );
    }
    return result;
  }

  if (value is List) {
    final result = [];
    for (final item in value.take(maxListItems)) {
      if (remaining[0] <= 0) break;
      result.add(_boundForLogging(
        item,
        remaining,
        maxListItems: maxListItems,
        maxStringLength: maxStringLength,
      ));
    }
    if (value.length > result.length) {
      result.add('… ${value.length - result.length} more items');
    }
    return result;
  }

  if (value is String && value.length > maxStringLength) {
    return '${value.substring(0, maxStringLength)}… [${value.length} chars total]';
  }

  return value;
}
