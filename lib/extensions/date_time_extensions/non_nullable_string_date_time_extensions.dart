import 'package:intl/intl.dart';

/// Extension on nullable String to parse it into a DateTime object.
///
/// Supports optional [inputFormat] to specify the date format.
/// Returns null if parsing fails or the string is null/empty.
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
extension NonNullableStringDateTimeExtensions on String {
  DateTime? toTryDateTime({String? inputFormat}) {
    try {
      return inputFormat == null
          ? DateTime.tryParse(this)
          : DateFormat(inputFormat).parseLoose(this);
    } catch (_) {
      return null;
    }
  }
}
