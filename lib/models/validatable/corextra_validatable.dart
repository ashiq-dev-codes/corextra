import 'corextra_validation_result.dart';

/// Adds a [validation] result to a class, using the checks you write once in [validate].
///
/// Example:
/// ```dart
/// class SignUpForm with CorextraValidatable {
///   SignUpForm(this.name, this.email);
///   final String? name;
///   final String? email;
///
///   @override
///   Map<String, String?> validate() => {
///     'name': FormValidators.required(name),
///     'email': FormValidators.email(email),
///   };
/// }
///
/// final result = form.validation;
/// if (!result.isValid) showError(result.firstError);
/// ```
mixin CorextraValidatable {
  // ---------------- Checks ----------------

  /// Each field's error message, or null when it's valid; `FormValidators` fit here directly.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, String?> validate() => {
  ///   'name': FormValidators.required(name),
  ///   'email': FormValidators.email(email),
  ///   'age': (age ?? 0) < 18 ? 'You must be 18 or older' : null,
  /// };
  /// ```
  Map<String, String?> validate();

  // ---------------- Result ----------------

  /// Runs [validate] and returns which fields failed and why.
  ///
  /// Example:
  /// ```dart
  /// final result = form.validation;
  /// if (result.isValid) submit();
  /// ```
  CorextraValidationResult get validation =>
      CorextraValidationResult(validate());
}
