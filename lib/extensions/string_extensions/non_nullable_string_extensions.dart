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
  int? toTryInt() => int.tryParse(this);

  /// Tries to parse the string to a double.
  /// Returns null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// '3.14'.toTryDouble(); // returns 3.14
  /// 'pi'.toTryDouble();   // returns null
  /// value?.toString().toTryDouble(); // returns null or double value
  /// ```
  double? toTryDouble() => double.tryParse(this);

  /// Tries to parse the string to a boolean.
  /// Returns true if string is 'true' (case-insensitive) or '1',
  /// false otherwise.
  ///
  /// Example:
  /// ```dart
  /// 'true'.toTryBool();  // returns true
  /// '1'.toTryBool();     // returns true
  /// 'false'.toTryBool(); // returns false
  /// value?.toString().toTryBool(); // returns null or bool value
  /// ```
  bool? toTryBool() => bool.tryParse(toLowerCase()) ?? toTryInt() == 1;

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
    try {
      return inputFormat == null
          ? DateTime.tryParse(this)
          : DateFormat(inputFormat).parseLoose(this);
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
  String capitalize() => split(' ')
      .map(
        (word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '',
      )
      .join(' ');
}
