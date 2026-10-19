import 'package:intl/intl.dart';

/// Extensions on non-nullable String for common parsing and formatting.
extension NonNullableStringExtensions on String {
  // ---------------- Parsing Methods ----------------

  /// Tries to parse the string to an integer.
  /// Returns null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// '123'.toTryInt(); // returns 123
  /// 'abc'.toTryInt(); // returns null
  /// value?.toString().toTryInt(); // returns null or int value
  /// ```
  int? toTryInt() => int.tryParse(trim());

  /// Tries to parse the string to a double.
  /// Returns null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// '3.14'.toTryDouble(); // returns 3.14
  /// 'pi'.toTryDouble();   // returns null
  /// value?.toString().toTryDouble(); // returns null or double value
  /// ```
  double? toTryDouble() => double.tryParse(trim());

  /// Tries to parse the string to a boolean, in any letter case.
  /// Returns true for 'true', '1' or 'yes', false for 'false', '0' or 'no',
  /// and null for anything else.
  ///
  /// Example:
  /// ```dart
  /// 'TRUE'.toTryBool();  // returns true
  /// '0'.toTryBool();     // returns false
  /// 'maybe'.toTryBool(); // returns null
  /// value?.toString().toTryBool(); // returns null or bool value
  /// ```
  bool? toTryBool() => switch (trim().toLowerCase()) {
    'true' || '1' || 'yes' => true,
    'false' || '0' || 'no' => false,
    _ => null,
  };

  /// Tries to parse the string into a DateTime object.
  ///
  /// Supports optional [inputFormat] to specify the date format.
  /// Returns null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// String? dateStr = '10/08/2023';
  /// DateTime? dt = dateStr.toTryDateTime(inputFormat: 'dd/MM/yyyy');
  /// print(dt); // Parsed DateTime or null
  ///
  /// String? isoDate = '2023-08-10T14:00:00Z';
  /// DateTime? dt2 = isoDate.toTryDateTime();
  /// print(dt2); // Parsed DateTime or null
  /// ```
  DateTime? toTryDateTime({String? inputFormat}) {
    final text = trim();
    try {
      return inputFormat == null
          ? DateTime.tryParse(text)
          : DateFormat(inputFormat).parseLoose(text);
    } catch (_) {
      return null;
    }
  }

  // ---------------- Formatting Methods ----------------

  /// Capitalizes the first letter of each word and lowercases the rest.
  ///
  /// Example:
  /// ```dart
  /// 'hello WORLD'.capitalize(); // returns 'Hello World'
  /// ```
  String capitalize() {
    return split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Converts `snake_case` or `kebab-case` to PascalCase
  ///
  /// Example:
  /// ```dart
  /// 'app_settings'.toPascalCase(); // AppSettings
  /// 'user-profile-info'.toPascalCase(); // UserProfileInfo
  /// ```
  String toPascalCase() {
    return split(RegExp(r'[_\-]'))
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join();
  }

  /// Converts `snake_case` or `kebab-case` to camelCase
  ///
  /// Example:
  /// ```dart
  /// 'app_settings'.toCamelCase(); // appSettings
  /// 'user-profile-info'.toCamelCase(); // userProfileInfo
  /// ```
  String toCamelCase() {
    final pascal = toPascalCase();
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}
