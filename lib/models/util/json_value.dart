import 'dart:convert';

import '../../extensions/string_extensions/non_nullable_string_extensions.dart';
import '../json_model/corextra_json_model.dart';

// ---------------- Reading ----------------

/// Converts a raw JSON value to [T], or returns null when that would lose or invent data, e.g. `"7"` to `7`.
T? convertJsonValue<T>(Object? raw) {
  if (_isType<T, Map<String, dynamic>>()) {
    final map = decodeJsonText(raw);
    // Always a copy, so changing the returned map can't change the model's json.
    return map is Map
        ? _as<T>({for (final e in map.entries) '${e.key}': e.value})
        : null;
  }
  if (raw is T) return raw;
  if (raw == null) return null;
  final Object? value;
  if (_isType<T, int>()) {
    value = _toInt(raw);
  } else if (_isType<T, double>()) {
    value = _toDouble(raw);
  } else if (_isType<T, num>()) {
    value = _toNum(raw);
  } else if (_isType<T, String>()) {
    value = _toText(raw);
  } else if (_isType<T, bool>()) {
    value = _toBool(raw);
  } else if (_isType<T, DateTime>()) {
    value = _toDateTime(raw);
  } else {
    value = null;
  }
  return _as<T>(value);
}

/// Decodes [raw] when it's JSON sent as text, e.g. `'{"a": 1}'` to a map; anything else comes back unchanged.
Object? decodeJsonText(Object? raw) {
  if (raw is! String) return raw;
  final text = raw.trim();
  if (!text.startsWith('{') && !text.startsWith('[')) return raw;
  try {
    return jsonDecode(text);
  } on FormatException {
    return raw;
  }
}

// ---------------- Writing ----------------

/// Converts [value] to plain JSON: nested models become maps, dates ISO text and enums their name.
Object? toJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    CorextraJsonModel() => value.toJson(),
    DateTime() => value.toIso8601String(),
    Enum() => value.name,
    Map() => {for (final e in value.entries) '${e.key}': toJsonValue(e.value)},
    Iterable() => [for (final item in value) toJsonValue(item)],
    _ => value,
  };
}

// ---------------- Types ----------------

T? _as<T>(Object? value) => value is T ? value : null;

Type _typeOf<X>() => X;

// True when T is S or S?, so `read<int?>` converts the same way as `read<int>`.
bool _isType<T, S>() => T == S || T == _typeOf<S?>();

// ---------------- Numbers, text and bools ----------------

num? _toNum(Object raw) {
  final number = switch (raw) {
    num() => raw,
    String() => raw.toTryInt() ?? raw.toTryDouble(),
    _ => null,
  };
  return number != null && number.isFinite ? number : null;
}

// Only whole numbers, so 7.5 never silently becomes 7.
int? _toInt(Object raw) {
  final number = _toNum(raw);
  if (number == null) return null;
  final whole = number.toInt();
  return whole == number ? whole : null;
}

double? _toDouble(Object raw) => _toNum(raw)?.toDouble();

// Maps and lists aren't turned into text, so a wrong shape reads as null instead of "{...}".
String? _toText(Object raw) => raw is num || raw is bool ? '$raw' : null;

// Numbers are compared directly, since 1.0 prints as "1.0" on native but "1" on web.
bool? _toBool(Object raw) => switch (raw) {
  num() => raw == 1 ? true : (raw == 0 ? false : null),
  String() => raw.toTryBool(),
  _ => null,
};

// ---------------- Dates ----------------

// Whole numbers, even as text, are Unix timestamps; everything else is read as an ISO date.
DateTime? _toDateTime(Object raw) {
  final epoch = switch (raw) {
    num() => raw,
    String() => raw.toTryInt(),
    _ => null,
  };
  if (epoch != null) return _fromEpoch(epoch);
  return raw is String ? raw.toTryDateTime() : null;
}

// Like Python's pydantic: above 2e10 it's milliseconds, otherwise seconds.
DateTime? _fromEpoch(num epoch) {
  if (!epoch.isFinite) return null;
  final ms = (epoch.abs() > 2e10 ? epoch : epoch * 1000).round();
  // DateTime's own limit: ±100,000,000 days from 1970.
  if (ms.abs() > 8640000000000000) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}
