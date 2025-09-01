import 'package:easy_localization/easy_localization.dart';

/// Form validation utility with optional translation support
class FormValidators {
  /// Global flag to enable/disable translation
  static bool canTranslate = false;

  /// Enable translation for the app
  /// Call this in main app before using validators
  static void enableTranslation([bool enable = true]) {
    canTranslate = enable;
  }

  /// Translate helper
  static String _msg(String msg) => canTranslate ? msg.tr() : msg;

  /// General required field validator
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: FormValidators.required,
  /// )
  /// ```
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _msg("This field is required");
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
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _msg("This field is required");
    }

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return _msg("Please enter a valid email address");
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
  static String? phone(String mask, String? value) {
    if (value == null || value.trim().isEmpty) {
      return _msg("This field is required");
    }

    if (mask.length != value.replaceAll(" ", "").length) {
      return _msg("Please enter a valid phone number");
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
  static String? otp(String? value, {int length = 4}) {
    if (value == null || value.trim().isEmpty) {
      return _msg("This field is required");
    }

    if (value.length < length) {
      return _msg("Please enter at least $length digits");
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
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return _msg("This field is required");
    }

    if (value.length < minLength) {
      return _msg("At least $minLength characters required");
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
  }) {
    if (value == null || value.isEmpty) {
      return _msg("This field is required");
    }

    if (value.length < minLength) {
      return _msg("At least $minLength characters required");
    }

    if (value != newPassword) {
      return _msg("Must match new password");
    }

    return null;
  }
}
