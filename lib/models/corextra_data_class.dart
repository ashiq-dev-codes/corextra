import 'util/deep_equality.dart';

/// Gives a class with normal fields `==`, `hashCode` and a readable `toString`, like a Python `@dataclass` or a Java `record`.
mixin CorextraDataClass {
  /// The values that define this object, by name; lists, maps and sets are compared by their contents.
  Map<String, Object?> get fields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorextraDataClass &&
          other.runtimeType == runtimeType &&
          deepEquals(fields, other.fields);

  @override
  int get hashCode => deepHash(fields);

  @override
  String toString() {
    final values = fields.entries.map((e) => '${e.key}: ${e.value}');
    return '$runtimeType(${values.join(', ')})';
  }
}
