/// Extensions on int for convenience.
extension IntExtensions on int {
  /// Returns 0 if the number is negative, otherwise returns the number itself.
  ///
  /// This can be useful to sanitize inputs or prevent negative values in calculations.
  ///
  /// Example:
  /// ```dart
  /// (-5).toZeroIfNegative(); // returns 0
  /// 10.toZeroIfNegative();   // returns 10
  /// value?.toZeroIfNegative(); // returns 0 or int value
  /// ```
  int toZeroIfNegative() => this < 0 ? 0 : this;
}
