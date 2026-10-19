/// The outcome of a validation: which fields failed and why.
///
/// Example:
/// ```dart
/// final result = form.validation;
/// result.isValid;            // false
/// result.errors;             // {email: Please enter a valid email address}
/// result.firstError;         // Please enter a valid email address
/// result.errorFor('email');  // Please enter a valid email address
/// ```
class CorextraValidationResult {
  /// Keeps only the fields in [checks] that have an error message.
  CorextraValidationResult(Map<String, String?> checks) {
    for (final entry in checks.entries) {
      final message = entry.value;
      if (message != null) errors[entry.key] = message;
    }
  }

  // ---------------- Errors ----------------

  /// The fields that failed, with their messages.
  ///
  /// Example:
  /// ```dart
  /// for (final MapEntry(:key, :value) in form.validation.errors.entries) {
  ///   debugPrint('$key: $value');
  /// }
  /// ```
  final Map<String, String> errors = {};

  /// Whether every field passes.
  ///
  /// Example:
  /// ```dart
  /// if (form.validation.isValid) submit();
  /// ```
  bool get isValid => errors.isEmpty;

  /// The first error message, or null when everything is valid.
  ///
  /// Example:
  /// ```dart
  /// final error = form.validation.firstError;
  /// if (error != null) showSnackBar(error);
  /// ```
  String? get firstError => errors.values.firstOrNull;

  /// The error message for [field], or null when it's valid.
  ///
  /// Example:
  /// ```dart
  /// TextField(decoration: InputDecoration(errorText: form.validation.errorFor('email')));
  /// ```
  String? errorFor(String field) => errors[field];

  @override
  String toString() => 'CorextraValidationResult($errors)';
}
