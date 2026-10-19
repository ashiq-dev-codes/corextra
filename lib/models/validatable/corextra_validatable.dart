import 'corextra_validation_result.dart';

/// Adds a [validation] result to a class, using the checks you write once in [validate].
mixin CorextraValidatable {
  // ---------------- Checks ----------------

  /// Each field's error message, or null when it's valid, e.g. `{'email': FormValidators.email(email)}`.
  Map<String, String?> validate();

  // ---------------- Result ----------------

  /// Runs [validate] and returns which fields failed and why, e.g. `if (form.validation.isValid) submit();`.
  CorextraValidationResult get validation =>
      CorextraValidationResult(validate());
}
