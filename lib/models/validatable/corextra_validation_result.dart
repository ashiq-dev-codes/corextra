/// The outcome of a validation: which fields failed and why, e.g. `form.validation.errors`.
class CorextraValidationResult {
  /// Keeps only the fields in [checks] that have an error message.
  CorextraValidationResult(Map<String, String?> checks) {
    for (final entry in checks.entries) {
      final message = entry.value;
      if (message != null) errors[entry.key] = message;
    }
  }

  // ---------------- Errors ----------------

  /// The fields that failed, with their messages, e.g. `{'email': 'Please enter a valid email address'}`.
  final Map<String, String> errors = {};

  /// Whether every field passes.
  bool get isValid => errors.isEmpty;

  /// The first error message, or null when everything is valid, e.g. `showSnackBar(form.validation.firstError)`.
  String? get firstError => errors.values.firstOrNull;

  /// The error message for [field], or null when it's valid, e.g. `errorText: form.validation.errorFor('email')`.
  String? errorFor(String field) => errors[field];

  @override
  String toString() => 'CorextraValidationResult($errors)';
}
