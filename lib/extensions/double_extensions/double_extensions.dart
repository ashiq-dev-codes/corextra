/// Extensions on double for convenience.
extension DoubleExtensions on double {
  /// Returns 0.0 if the number is negative, otherwise returns the number itself.
  ///
  /// Useful to sanitize values and avoid negative doubles where not allowed.
  ///
  /// Example:
  /// ```dart
  /// (-3.5).toZeroIfNegative(); // returns 0.0
  /// 7.2.toZeroIfNegative();    // returns 7.2
  /// value?.toZeroIfNegative(); // returns 0.0 or double value
  /// ```
  double toZeroIfNegative() => this < 0 ? 0.0 : this;
}
