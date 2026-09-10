/// A function that translates a string.
typedef Translator = String Function(String);

/// A `Form` field validator: takes the field value, returns an error message or null.
typedef Validator = String? Function(String?);

/// Form validators with optional translation.
class FormValidators {
  /// The WHATWG `<input type="email">` pattern: catches typos without rejecting real addresses (`+` tags, long TLDs).
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+"
    r"@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Translator function. If not set, messages are returned as-is.
  static Translator? translator;

  /// Whether translation is enabled. Defaults to false.
  static bool canTranslate = false;

  /// Set the translator function.
  /// Example:
  /// ```dart
  /// FormValidators.setTranslator((msg) => msg.tr()); // using easy_localization
  /// ```
  static void setTranslator(Translator fn) {
    translator = fn;
  }

  /// Enable or disable translation.
  /// Example:
  /// ```dart
  /// FormValidators.enableTranslation(true);  // enable translation
  /// FormValidators.enableTranslation(false); // disable translation
  /// ```
  static void enableTranslation([bool enable = true]) {
    canTranslate = enable;
  }

  /// Return translated message if translation is enabled and a translator is set.
  /// Otherwise, returns the original message.
  static String _msg(String msg) =>
      (canTranslate && translator != null) ? translator!(msg) : msg;

  /// Runs [validators] in order and returns the first error, or null if all pass.
  static Validator compose(List<Validator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Wraps [validator] so it's skipped when the field is empty, for non-required fields.
  static Validator optional(Validator validator) {
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      return validator(value);
    };
  }

  /// General required field validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: FormValidators.required,
  /// )
  /// ```
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    return null;
  }

  /// Email validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: FormValidators.email,
  /// )
  /// ```
  static String? email(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return message ?? _msg("Please enter a valid email address");
    }

    return null;
  }

  /// General phone validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: (val) => FormValidators.phone("1234567890", val),
  /// )
  /// ```
  static String? phone(String mask, String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (mask.length != value.replaceAll(" ", "").length) {
      return message ?? _msg("Please enter a valid phone number");
    }

    return null;
  }

  /// OTP validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: (val) => FormValidators.otp(val, length: 6),
  /// )
  /// ```
  static String? otp(String? value, {int length = 4, String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (value.length < length) {
      return message ?? _msg("Please enter at least $length digits");
    }

    return null;
  }

  /// Password validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: (val) => FormValidators.password(val, minLength: 8),
  /// )
  /// ```
  static String? password(String? value, {int minLength = 6, String? message}) {
    if (value == null || value.isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (value.length < minLength) {
      return message ?? _msg("At least $minLength characters required");
    }

    return null;
  }

  /// Confirm password validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: (val) => FormValidators.confirmPassword(val, _newPasswordController.text),
  /// )
  /// ```
  static String? confirmPassword(
    String? value,
    String newPassword, {
    int minLength = 6,
    String? message,
  }) {
    if (value == null || value.isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (value.length < minLength) {
      return message ?? _msg("At least $minLength characters required");
    }

    if (value != newPassword) {
      return message ?? _msg("Must match new password");
    }

    return null;
  }

  /// Validates that the value is at least [length] characters long.
  static String? minLength(String? value, int length, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (value.length < length) {
      return message ?? _msg("At least $length characters required");
    }

    return null;
  }

  /// Validates that the value is at most [length] characters long.
  static String? maxLength(String? value, int length, {String? message}) {
    if (value != null && value.length > length) {
      return message ?? _msg("At most $length characters allowed");
    }

    return null;
  }

  /// Validates that the value contains digits only.
  static String? numeric(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (!RegExp(r"^[0-9]+$").hasMatch(value.trim())) {
      return message ?? _msg("Please enter numbers only");
    }

    return null;
  }

  /// Validates that the value is a well-formed http/https URL.
  static String? url(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    final uri = Uri.tryParse(value.trim());
    final isValid =
        uri != null &&
        (uri.isScheme("http") || uri.isScheme("https")) &&
        uri.host.isNotEmpty;

    if (!isValid) {
      return message ?? _msg("Please enter a valid URL");
    }

    return null;
  }

  /// Validates the value against a custom [regex]; pass [message] since the failure meaning is caller-defined.
  static String? pattern(String? value, RegExp regex, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? _msg("This field is required");
    }

    if (!regex.hasMatch(value.trim())) {
      return message ?? _msg("Invalid format");
    }

    return null;
  }
}
