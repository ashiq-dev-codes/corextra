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

  /// The layout's [DeviceType] (mobile / tablet / desktop), based on maxWidth.
  DeviceType get deviceType => ResponsiveBreakpoints.deviceType(this);

  /// Returns true if [deviceType] is [DeviceType.mobile].
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Returns true if [deviceType] is [DeviceType.tablet].
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Returns true if [deviceType] is [DeviceType.desktop].
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Returns true if maxHeight is at least maxWidth.
  bool get isPortrait => maxHeight >= maxWidth;

  /// Returns true if maxWidth exceeds maxHeight.
  bool get isLandscape => maxWidth > maxHeight;

  /// Picks the highest-matching value for maxWidth, falling back to [base].
  T responsive<T>({
    required T base,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
  }) => ResponsiveBreakpoints.valueOf<T>(
    maxWidth,
    base: base,
    sm: sm,
    md: md,
    lg: lg,
    xl: xl,
    xxl: xxl,
  );
}
