import 'package:corextra/corextra.dart';

void main() {
  // String extensions
  print('123'.toTryInt()); // 123
  print('3.14'.toTryDouble()); // 3.14
  print('true'.toTryBool()); // true
  print('hello world'.capitalize()); // Hello World

  // Nullable List extensions
  List<int>? items;
  print(items.isNullOrEmpty); // true
  print([1, 2, 3].isNotNullOrEmpty); // true

  // Numeric sanitizers
  print((-5).toZeroIfNegative()); // 0
  print((-3.5).toZeroIfNegative()); // 0.0

  // Helper functions
  print(isStringEmpty(null)); // true
  print(isListEmpty([1, 2])); // false
}
