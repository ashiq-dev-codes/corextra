/// Extensions on nullable List for safe emptiness checks.
extension ListExtensions<T> on List<T>? {
  /// Returns true if the list is null or empty.
  ///
  /// Example:
  /// ```dart
  /// List<int>? list;
  /// list.isNullOrEmpty; // true
  /// [].isNullOrEmpty; // true
  /// [1, 2, 3].isNullOrEmpty; // false
  /// value?.isNullOrEmpty; // returns true or false
  /// ```
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the list is not null and contains at least one element.
  ///
  /// Example:
  /// ```dart
  /// List<int>? list = [1];
  /// list.isNotNullOrEmpty; // true
  /// value?.isNullOrEmpty; // returns true or false
  /// ```
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}
