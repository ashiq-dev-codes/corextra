import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';

/// Extensions on [BuildContext] for Tailwind-style responsive checks.
///
/// Provides boolean getters for each breakpoint (`sm`, `md`, `lg`, `xl`, `xxl`)
/// to make responsive layouts easy and readable.
///
/// Example usage:
/// ```dart
/// // Inside a widget build method
/// if (context.sm) {
///   print("Small screen or larger");
/// }
///
/// if (context.lg) {
///   print("Large screen or larger");
/// }
///
/// // Full example with conditional widget
/// Widget build(BuildContext context) {
///   return Container(
///     width: context.md ? 500 : 300,
///     child: Text(
///       context.xl ? "Extra Large Screen" : "Smaller Screen",
///     ),
///   );
/// }
/// ```
extension ResponsiveContextExtensions on BuildContext {
  /// Returns true if screen width ≥ small breakpoint
  bool get sm => ResponsiveBreakpoints.isSmContext(this);

  /// Returns true if screen width ≥ medium breakpoint
  bool get md => ResponsiveBreakpoints.isMdContext(this);

  /// Returns true if screen width ≥ large breakpoint
  bool get lg => ResponsiveBreakpoints.isLgContext(this);

  /// Returns true if screen width ≥ extra large breakpoint
  bool get xl => ResponsiveBreakpoints.isXlContext(this);

  /// Returns true if screen width ≥ XXL breakpoint
  bool get xxl => ResponsiveBreakpoints.isXxlContext(this);
}
