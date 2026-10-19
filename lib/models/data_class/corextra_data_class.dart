import '../util/deep_equality.dart';

/// Gives a class with normal fields `==`, `hashCode` and a readable `toString`, like a Python `@dataclass` or a Java `record`.
///
/// Example:
/// ```dart
/// class GeoPoint with CorextraDataClass {
///   const GeoPoint(this.lat, this.lng);
///   final double lat;
///   final double lng;
///
///   @override
///   Map<String, Object?> get fields => {'lat': lat, 'lng': lng};
/// }
///
/// GeoPoint(25.2, 55.27) == GeoPoint(25.2, 55.27); // true
/// print(GeoPoint(25.2, 55.27)); // GeoPoint(lat: 25.2, lng: 55.27)
/// ```
mixin CorextraDataClass {
  // ---------------- Fields ----------------

  /// The values that define this object, by name; used for `==`, `hashCode` and `toString`.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, Object?> get fields => {'lat': lat, 'lng': lng};
  /// ```
  Map<String, Object?> get fields;

  // ---------------- Equality and printing ----------------

  /// Equal when both are the same type with the same [fields]; lists, maps and sets are compared by their contents.
  ///
  /// Example:
  /// ```dart
  /// GeoPoint(25.2, 55.27) == GeoPoint(25.2, 55.27); // true
  /// {GeoPoint(1, 2), GeoPoint(1, 2)}.length;        // 1
  /// ```
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorextraDataClass &&
          other.runtimeType == runtimeType &&
          deepEquals(fields, other.fields);

  @override
  int get hashCode => deepHash(fields);

  /// Lists each field by name, for logs and debugging.
  ///
  /// Example:
  /// ```dart
  /// print(GeoPoint(25.2, 55.27)); // GeoPoint(lat: 25.2, lng: 55.27)
  /// ```
  @override
  String toString() {
    final values = fields.entries.map((e) => '${e.key}: ${e.value}');
    return '$runtimeType(${values.join(', ')})';
  }
}
