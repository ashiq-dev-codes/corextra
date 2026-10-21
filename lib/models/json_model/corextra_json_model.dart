import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../extensions/string_extensions/non_nullable_string_extensions.dart';
import '../util/deep_equality.dart';
import '../util/json_value.dart';
import '../util/json_warnings.dart';

/// Turns a class into a JSON model with no code generation: write each field once as a typed getter.
///
/// You get safe parsing, [toJson], `==`, `hashCode` and `toString` for free.
/// Bad or missing data reads as null and never throws; in debug builds, a bad value also prints one warning.
///
/// Example:
/// ```dart
/// class UserModel with CorextraJsonModel {
///   UserModel.fromJson(this.json);
///
///   @override
///   final Map<String, dynamic> json;
///
///   int? get id => read('id');
///   String get name => read('name') ?? '';
///   CourtModel? get court => readModel('court', CourtModel.fromJson);
///   List<String>? get tags => readList('tags');
/// }
///
/// final user = UserModel.fromJson(response.data);
/// print(user.id); // 7, even when the API sends "7"
/// ```
mixin CorextraJsonModel {
  // ---------------- Settings ----------------

  /// Whether debug builds print a warning when a value exists but can't be read; release builds never do.
  ///
  /// Each model type and key warns once, and missing or blank values never warn.
  ///
  /// Example:
  /// ```dart
  /// // The API sends {"id": "abc"} and the getter is `int? get id => read('id');`
  /// // Debug console: UserModel: "id" should be int, but the JSON has text "abc". It reads as null.
  ///
  /// CorextraJsonModel.debugWarnings = false; // turn them off
  /// ```
  static bool debugWarnings = true;

  // ---------------- Source ----------------

  /// The raw JSON this model reads from; the model never modifies it, and if you change it, the model reads the new value.
  ///
  /// Example:
  /// ```dart
  /// UserModel.fromJson(this.json);
  ///
  /// // Optional: a typed constructor for building a model by hand
  /// UserModel({int? id, String? name}) : json = {'id': id, 'name': name};
  ///
  /// @override
  /// final Map<String, dynamic> json;
  /// ```
  Map<String, dynamic> get json;

  // ---------------- State ----------------

  // Parsed values by key, with the source they came from, so a value is reused only while its source is unchanged.
  final Map<String, (Object? source, Object value)> _parsed = {};

  // Values set with write(), kept apart so json is never modified.
  final Map<String, Object?> _written = {};

  // Results of cached(), cleared on every write() since they may depend on any field.
  final Map<String, Object?> _computed = {};

  // ---------------- Reading values ----------------

  /// Reads [key] as the getter's type: `int`, `double`, `num`, `String`, `bool`, `DateTime` or `Map`.
  ///
  /// Accepts loose API values, like `"7"` for an int or `1` for true, and returns null when it can't, with one warning in debug builds.
  /// Always write the getter's type, since that's what [read] converts to.
  ///
  /// Example:
  /// ```dart
  /// int? get id => read('id');                      // "7", 7 and 7.0 read as 7; "abc" reads as null
  /// String get name => read('name') ?? '';          // a default when missing
  /// bool? get isActive => read('is_active');        // true, "true", 1 and "yes" read as true
  /// DateTime? get startsAt => read('starts_at');    // ISO text or a Unix timestamp
  /// String? get ownerName => read('owner.name');    // json['owner']['name']
  /// String? get email => read('user_email', fallbackKeys: ['email']); // first key with a value
  /// ```
  @protected
  T? read<T>(String key, {List<String> fallbackKeys = const []}) =>
      _read(key, fallbackKeys, convertJsonValue<T>);

  /// Reads [key] as a date in a custom [format]; for ISO dates and Unix timestamps, use [read].
  ///
  /// Example:
  /// ```dart
  /// DateTime? get startTime => readDate('start_time', format: 'HH:mm:ss');
  /// DateTime? get birthday => readDate('dob', format: 'dd/MM/yyyy');
  /// // "18:30:00" reads as 6:30 PM; "late" reads as null
  /// ```
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

  /// Reads [key] as one of [values], matching the enum's name in any letter case.
  ///
  /// Example:
  /// ```dart
  /// Role? get role => readEnum('role', Role.values);
  /// // "admin", "ADMIN" and " Admin " read as Role.admin; "owner" reads as null
  /// ```
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

  /// Reads [key] as a list of plain values, skipping items that can't be converted; each read returns a fresh copy.
  ///
  /// Example:
  /// ```dart
  /// List<String>? get tags => readList('tags');
  /// List<int>? get scores => readList('scores');
  /// // ["1", 2, "x"] reads as [1, 2]; the text '["1", 2]' works too
  /// ```
  @protected
  List<T>? readList<T>(String key, {List<String> fallbackKeys = const []}) =>
      _read(key, fallbackKeys, (raw) => _list(raw, convertJsonValue<T>));

  /// Reads [key] as a nested model, or null when it's missing or invalid.
  ///
  /// Example:
  /// ```dart
  /// CourtModel? get court => readModel('court', CourtModel.fromJson);
  /// // {"court": {"id": 3}} and {"court": "{\"id\": 3}"} both work; {"court": "abc"} reads as null
  /// ```
  @protected
  T? readModel<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson, {
    List<String> fallbackKeys = const [],
  }) => _read(key, fallbackKeys, (raw) => _model(key, raw, fromJson));

  /// Reads [key] as a list of nested models, skipping invalid items instead of failing the whole list.
  ///
  /// Example:
  /// ```dart
  /// List<CourtModel>? get courts => readModelList('courts', CourtModel.fromJson);
  /// // [{"id": 1}, "junk", {"id": 2}] reads as two courts
  /// ```
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

  /// Builds a custom value once and reuses it until the next [write], with full access to [json].
  ///
  /// Example:
  /// ```dart
  /// String get fullName => cached('fullName', () => '$name $lastName');
  /// ImageModel? get avatar => cached('avatar', () => ImageModel.fromProfile(json));
  /// ```
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

  /// Changes the top-level [key] without touching [json]; later reads and [toJson] see the new value.
  ///
  /// Example:
  /// ```dart
  /// String? get name => read('name');
  /// set name(String? value) => write('name', value);
  ///
  /// user.name = 'Ali';
  /// print(user.toJson()['name']); // Ali
  /// ```
  @protected
  void write(String key, Object? value) {
    _written[key] = value;
    _parsed.removeWhere((k, _) => k == key || k.startsWith('$key.'));
    _computed.clear();
  }

  // ---------------- Output, equality and printing ----------------

  /// This model as JSON: unchanged values exactly as they came in, plus every [write].
  ///
  /// Example:
  /// ```dart
  /// await api.post(url, data: user.toJson());
  ///
  /// // copyWith: change any field, or set it to null
  /// final renamed = UserModel.fromJson({...user.toJson(), 'name': 'Ali'});
  /// ```
  Map<String, dynamic> toJson() {
    final data = <String, Object?>{...json};
    for (final entry in _parsed.entries) {
      final (_, value) = entry.value;
      if (!data.containsKey(entry.key) || !_hasChanges(value)) continue;
      // Nested JSON that came in as text goes back as text.
      data[entry.key] = data[entry.key] is String ? _encode(value) : value;
    }
    data.addAll(_written);
    return {for (final e in data.entries) e.key: toJsonValue(e.value)};
  }

  /// Equal when both are the same type with the same [toJson]; override it to compare by id instead.
  ///
  /// Example:
  /// ```dart
  /// UserModel.fromJson({'id': 1}) == UserModel.fromJson({'id': 1}); // true
  ///
  /// // Compare by id only
  /// @override
  /// bool operator ==(Object other) => other is UserModel && other.id == id;
  ///
  /// @override
  /// int get hashCode => id.hashCode;
  /// ```
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
    final source = _source(key);
    final entry = _parsed[key];
    if (entry != null && identical(entry.$1, source)) {
      if (entry.$2 case final T value) return _copy(value);
    }
    final raw = _rawValue(key);
    final value = parse(raw);
    if (value == null) {
      warnUnreadable(this, key, raw, T);
      return null;
    }
    _parsed[key] = (source, value);
    return _copy(value);
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

  // The top-level value a key reads from; a path is checked by its first part, so JSON sent as text isn't decoded on every read.
  Object? _source(String key) {
    if (_written.containsKey(key)) return _written[key];
    if (json.containsKey(key) || !key.contains('.')) return json[key];
    return _source(key.substring(0, key.indexOf('.')));
  }

  // Lists and maps go out as copies, so editing one can never half-change the model.
  static T _copy<T>(T value) {
    final Object? copy = switch (value) {
      List() => value.toList(),
      Map<String, dynamic>() => Map<String, dynamic>.of(value),
      _ => value,
    };
    return copy is T ? copy : value;
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
      warnUnreadable(this, key, raw, T, error: error);
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

  bool get _isChanged =>
      _written.isNotEmpty ||
      _parsed.values.any((entry) => _hasChanges(entry.$2));

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
