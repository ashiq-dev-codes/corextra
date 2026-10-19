import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../extensions/string_extensions/non_nullable_string_extensions.dart';
import '../../logs/deferred_log.dart';
import '../util/deep_equality.dart';
import '../util/json_value.dart';

/// Turns a class into a JSON model with no code generation: write each field once as a typed getter, e.g. `int? get id => read('id');`.
mixin CorextraJsonModel {
  // ---------------- Source ----------------

  /// The raw JSON this model reads from, set by your constructor, e.g. `UserModel.fromJson(this.json);`.
  Map<String, dynamic> get json;

  // ---------------- State ----------------

  // Parsed values by key, so each field is parsed only once.
  final Map<String, Object?> _parsed = {};

  // Values set with write(), kept apart so json is never modified.
  final Map<String, Object?> _written = {};

  // Results of cached(), cleared on every write() since they may depend on any field.
  final Map<String, Object?> _computed = {};

  // ---------------- Reading values ----------------

  /// Reads [key] as the getter's type (`int`, `double`, `num`, `String`, `bool`, `DateTime` or `Map`), or null, e.g. `int? get id => read('id');`.
  @protected
  T? read<T>(String key, {List<String> fallbackKeys = const []}) =>
      _read(key, fallbackKeys, convertJsonValue<T>);

  /// Reads [key] as a date in a custom [format], e.g. `DateTime? get startTime => readDate('start_time', format: 'HH:mm:ss');`.
  @protected
  DateTime? readDate(
    String key, {
    required String format,
    List<String> fallbackKeys = const [],
  }) => _read(
    key,
    fallbackKeys,
    (raw) => switch (raw) {
      DateTime() => raw,
      String() => raw.toTryDateTime(inputFormat: format),
      _ => null,
    },
  );

  /// Reads [key] as one of [values] by name, in any letter case, e.g. `Role? get role => readEnum('role', Role.values);`.
  @protected
  T? readEnum<T extends Enum>(
    String key,
    List<T> values, {
    List<String> fallbackKeys = const [],
  }) => _read(key, fallbackKeys, (raw) {
    if (raw is T) return raw;
    if (raw is! String) return null;
    final name = raw.trim().toLowerCase();
    for (final value in values) {
      if (value.name.toLowerCase() == name) return value;
    }
    return null;
  });

  // ---------------- Reading lists and nested models ----------------

  /// Reads [key] as a list, skipping items that can't be converted, e.g. `List<String>? get tags => readList('tags');`.
  @protected
  List<T>? readList<T>(String key, {List<String> fallbackKeys = const []}) =>
      _read(key, fallbackKeys, (raw) => _list(raw, convertJsonValue<T>));

  /// Reads [key] as a nested model, or null when it's missing or invalid, e.g. `CourtModel? get court => readModel('court', CourtModel.fromJson);`.
  @protected
  T? readModel<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    List<String> fallbackKeys = const [],
  }) => _read(key, fallbackKeys, (raw) => _model(key, raw, fromJson));

  /// Reads [key] as a list of nested models, skipping invalid items, e.g. `List<CourtModel>? get courts => readModelList('courts', CourtModel.fromJson);`.
  @protected
  List<T>? readModelList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    List<String> fallbackKeys = const [],
  }) => _read(
    key,
    fallbackKeys,
    (raw) => _list(raw, (item) => _model(key, item, fromJson)),
  );

  // ---------------- Custom values and changes ----------------

  /// Builds a value once and reuses it until the next [write], e.g. `String get fullName => cached('fullName', () => '$name $lastName');`.
  @protected
  T cached<T>(String name, T Function() build) {
    if (_computed.containsKey(name)) {
      final value = _computed[name];
      if (value is T) return value;
    }
    final value = build();
    _computed[name] = value;
    return value;
  }

  /// Changes the top-level [key] without touching [json], e.g. `set name(String? value) => write('name', value);`.
  @protected
  void write(String key, Object? value) {
    _written[key] = value;
    _parsed.removeWhere((k, _) => k == key || k.startsWith('$key.'));
    _computed.clear();
  }

  // ---------------- Output, equality and printing ----------------

  /// This model as JSON: unchanged values exactly as they came in, plus every [write], e.g. `api.post(url, data: user.toJson());`.
  Map<String, dynamic> toJson() {
    final data = <String, Object?>{...json};
    for (final entry in _parsed.entries) {
      final value = entry.value;
      if (!data.containsKey(entry.key) || !_hasChanges(value)) continue;
      // Nested JSON that came in as text goes back as text.
      data[entry.key] = data[entry.key] is String ? _encode(value) : value;
    }
    data.addAll(_written);
    return {for (final e in data.entries) e.key: toJsonValue(e.value)};
  }

  /// Equal when both are the same type with the same [toJson]; override it to compare by id instead.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorextraJsonModel &&
          other.runtimeType == runtimeType &&
          deepEquals(toJson(), other.toJson());

  @override
  int get hashCode => deepHash(toJson());

  @override
  String toString() => '$runtimeType${toJson()}';

  // ---------------- Private helpers ----------------

  T? _read<T>(
    String key,
    List<String> fallbackKeys,
    T? Function(Object? raw) parse,
  ) {
    final value = _readKey(key, parse);
    // An explicit write(), even a null one, wins over the fallback keys.
    if (value != null || fallbackKeys.isEmpty || _written.containsKey(key)) {
      return value;
    }
    for (final other in fallbackKeys) {
      final fallback = _readKey(other, parse);
      if (fallback != null) return fallback;
    }
    return null;
  }

  T? _readKey<T>(String key, T? Function(Object? raw) parse) {
    final cachedValue = _parsed[key];
    if (cachedValue is T && cachedValue != null) return cachedValue;
    final value = parse(_rawValue(key));
    if (value != null) _parsed[key] = value;
    return value;
  }

  // An exact key always wins, so a real key with a dot still works; otherwise 'user.name' walks into nested maps.
  Object? _rawValue(String key) {
    if (_written.containsKey(key)) return _written[key];
    if (json.containsKey(key) || !key.contains('.')) return json[key];
    final parts = key.split('.');
    var value = _rawValue(parts.first);
    for (final part in parts.skip(1)) {
      final parent = decodeJsonText(value);
      value = parent is Map ? parent[part] : null;
    }
    return value;
  }

  T? _model<T>(
    String key,
    Object? raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (raw is T) return raw;
    final map = convertJsonValue<Map<String, dynamic>>(raw);
    if (map == null) return null;
    try {
      return fromJson(map);
    } catch (error) {
      if (kDebugMode) {
        deferredLog(
          () => 'Could not read "$key" in $runtimeType: $error',
          name: 'corextra',
        );
      }
      return null;
    }
  }

  static List<T>? _list<T>(Object? raw, T? Function(Object? item) convert) {
    final list = decodeJsonText(raw);
    if (list is! Iterable) return null;
    final items = <T>[];
    for (final item in list) {
      final value = convert(item);
      if (value != null) items.add(value);
    }
    return items;
  }

  bool get _isChanged => _written.isNotEmpty || _parsed.values.any(_hasChanges);

  static bool _hasChanges(Object? value) {
    if (value is CorextraJsonModel) return value._isChanged;
    return value is Iterable &&
        value.any((item) => item is CorextraJsonModel && item._isChanged);
  }

  static Object? _encode(Object? value) {
    final plain = toJsonValue(value);
    try {
      return jsonEncode(plain);
    } on JsonUnsupportedObjectError {
      return plain;
    }
  }
}
