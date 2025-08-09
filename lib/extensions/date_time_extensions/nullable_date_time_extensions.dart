import 'package:intl/intl.dart';

/// Extension on nullable DateTime to format it into a string.
///
/// Requires [outputFormat] to specify the desired string format.
/// Returns null if the DateTime object is null.
///
/// Example:
/// ```dart
/// DateTime? now = DateTime.now();
/// String? formatted = now.formatDate(outputFormat: 'dd MMM yyyy');
/// print(formatted); // e.g. "10 Aug 2023"
///
/// DateTime? nullDate;
/// print(nullDate.formatDate(outputFormat: 'dd/MM/yyyy')); // prints null
/// ```
extension NullableDateTimeExtensions on DateTime? {
  String? formatDate({required String outputFormat}) {
    if (this == null) return null;
    return DateFormat(outputFormat).format(this!);
  }
}
