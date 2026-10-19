import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

// ---------------- Formatting ----------------

/// Formats a request or response body as indented JSON; bytes and [FormData] get a short summary, and other text is returned as is.
///
/// Example:
/// ```dart
/// final text = prettyFormatBody(response.data);
/// prettyFormatBody('{"id":7}'); // '{\n  "id": 7\n}'
/// prettyFormatBody('<html></html>'); // '<html></html>', not JSON so unchanged
/// ```
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

// ---------------- Formatting helpers ----------------

// The first bytes are enough to spot the format (a PNG starts `89 50 4e 47`); JsonEncoder would dump every byte as a number.
String _formatBytes(Uint8List bytes) {
  final preview = bytes
      .take(16)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ');
  final ellipsis = bytes.length > 16 ? '…' : '';
  return '<binary data, ${bytes.length} bytes>\n'
      'first bytes (hex): $preview$ellipsis';
}

// FormData's toString() is just `Instance of 'FormData'`, so show its fields and file details as JSON instead.
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

// ---------------- Bounding ----------------

/// Cuts a text body to [maxLength] chars before capture; Maps and Lists pass through so formatting is paid only when shown.
///
/// Example:
/// ```dart
/// event.responseBody = truncateBody(response.data, 10000);
/// truncateBody('abcdef', 3); // 'abc… [truncated, 6 chars total]'
/// ```
Object? truncateBody(Object? data, int maxLength) {
  if (data == null) return null;
  if (data is Uint8List || data is FormData) return prettyFormatBody(data);
  if (data is String && data.length > maxLength) {
    return '${data.substring(0, maxLength)}… [truncated, ${data.length} chars total]';
  }
  return data;
}

/// Like [prettyFormatBody], but caps how much it walks and prints, for callers that format right away, like a logger.
///
/// Example:
/// ```dart
/// final text = boundedPrettyFormatBody(response.data);
/// boundedPrettyFormatBody(users, maxListItems: 10); // 100 users print as 10, then '… 90 more items'
/// ```
String boundedPrettyFormatBody(
  Object? data, {
  int budget = 2000,
  int maxListItems = 50,
  int maxStringLength = 2000,
  int maxDecodeLength = 50000,
}) {
  if (data == null) return 'null';
  if (data is Uint8List) return _formatBytes(data);
  if (data is FormData) return _formatFormData(data);
  // Decoding is all-or-nothing, so a huge string is cut down as text instead of decoded in full.
  if (data is String && data.length > maxDecodeLength) {
    final cut = maxStringLength < data.length ? maxStringLength : data.length;
    return '${data.substring(0, cut)}… [${data.length} chars total]';
  }
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

// ---------------- Private helpers ----------------

// [remaining] is a one-item counter shared by every nested call, so the walk stops as soon as the budget runs out, at any depth.
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
      result.add(
        _boundForLogging(
          item,
          remaining,
          maxListItems: maxListItems,
          maxStringLength: maxStringLength,
        ),
      );
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
