import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';

/// Extensions on [BoxConstraints] for Tailwind-style responsive checks.
///
/// Provides boolean getters for each breakpoint (`sm`, `md`, `lg`, `xl`, `xxl`)
/// to make responsive layouts easier inside `LayoutBuilder` or similar widgets.
///
/// Example usage:
/// ```dart
/// LayoutBuilder(
///   builder: (context, constraints) {
///     if (constraints.sm) {
///       print("Small screen or larger");
///     }
///
///     if (constraints.lg) {
///       print("Large screen or larger");
///     }
///
///     // Conditional widget example
///     return Container(
///       width: constraints.md ? 500 : 300,
///       child: Text(
///         constraints.xl ? "Extra Large Screen" : "Smaller Screen",
///       ),
///     );
///   },
/// );
/// ```
extension ResponsiveConstraintsExtensions on BoxConstraints {
  /// Returns true if maxWidth ≥ small breakpoint
  bool get sm => ResponsiveBreakpoints.isSm(this);

  /// Returns true if maxWidth ≥ medium breakpoint
  bool get md => ResponsiveBreakpoints.isMd(this);

  /// Returns true if maxWidth ≥ large breakpoint
  bool get lg => ResponsiveBreakpoints.isLg(this);

  /// Returns true if maxWidth ≥ extra large breakpoint
  bool get xl => ResponsiveBreakpoints.isXl(this);

  /// Returns true if maxWidth ≥ XXL breakpoint
  bool get xxl => ResponsiveBreakpoints.isXxl(this);
}
