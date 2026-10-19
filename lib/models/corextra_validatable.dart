/// Adds a [validation] result to a class, using the checks you write once in [validate].
mixin CorextraValidatable {
  /// Each field's error message, or null when that field is valid; `FormValidators` fit here directly.
  Map<String, String?> validate();

  /// Runs [validate] and returns which fields failed and why.
  CorextraValidationResult get validation =>
      CorextraValidationResult(validate());
}

/// The outcome of a validation: which fields failed and why.
class CorextraValidationResult {
  /// Keeps only the fields in [checks] that have an error message.
  CorextraValidationResult(Map<String, String?> checks) {
    for (final entry in checks.entries) {
      final message = entry.value;
      if (message != null) errors[entry.key] = message;
    }
  }

  /// The fields that failed, with their error messages.
  final Map<String, String> errors = {};

  /// Whether every field passes.
  bool get isValid => errors.isEmpty;

  /// The first error message, or null when everything is valid.
  String? get firstError => errors.values.firstOrNull;

  /// The error message for [field], or null when it's valid.
  String? errorFor(String field) => errors[field];

  @override
  String toString() => 'CorextraValidationResult($errors)';
}
