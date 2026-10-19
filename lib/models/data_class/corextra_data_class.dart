import '../util/deep_equality.dart';

/// Gives a class with normal fields `==`, `hashCode` and a readable `toString`, like a Python `@dataclass` or a Java `record`.
mixin CorextraDataClass {
  // ---------------- Fields ----------------

  /// The values that define this object, by name, e.g. `Map<String, Object?> get fields => {'lat': lat, 'lng': lng};`.
  Map<String, Object?> get fields;

  // ---------------- Equality and printing ----------------

  /// Equal when both are the same type with the same [fields]; lists, maps and sets are compared by their contents.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorextraDataClass &&
          other.runtimeType == runtimeType &&
          deepEquals(fields, other.fields);

  @override
  int get hashCode => deepHash(fields);

  /// Lists each field by name, e.g. `GeoPoint(lat: 25.2, lng: 55.27)`.
  @override
  String toString() {
    final values = fields.entries.map((e) => '${e.key}: ${e.value}');
    return '$runtimeType(${values.join(', ')})';
  }
}
