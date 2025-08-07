/// Extensions on nullable String to check emptiness safely.
extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty.
  ///
  /// Example:
  /// ```dart
  /// String? s;
  /// s.isNullOrEmpty; // true
  /// ''.isNullOrEmpty; // true
  /// 'text'.isNullOrEmpty; // false
  /// value?.isNullOrEmpty; // returns true or false
  /// ```
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the string is not null and not empty.
  ///
  /// Example:
  /// ```dart
  /// String? s = 'hello';
  /// s.isNotNullOrEmpty; // true
  /// value?.isNotNullOrEmpty; // returns true or false
  /// ```
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}
