/* <------ String Functions ------> */

/// Checks if a nullable string is null or empty.
/// Use `String?` extension `isNullOrEmpty` for cleaner code.
///
/// Example:
/// ```dart
/// isStringEmpty(null); // true
/// isStringEmpty(''); // true
/// isStringEmpty('abc'); // false
/// ```
bool isStringEmpty(String? value) => value == null || value.isEmpty;

/* <------ List Functions ------> */

/// Checks if a nullable list is null or empty.
/// Use `List?` extension `isNullOrEmpty` for cleaner code.
///
/// Example:
/// ```dart
/// isListEmpty(null); // true
/// isListEmpty([]); // true
/// isListEmpty([1,2]); // false
/// ```
bool isListEmpty<T>(List<T>? value) => value == null || value.isEmpty;
