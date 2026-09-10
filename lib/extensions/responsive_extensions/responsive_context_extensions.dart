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

  /// The screen's [DeviceType] (mobile / tablet / desktop).
  DeviceType get deviceType => ResponsiveBreakpoints.deviceTypeContext(this);

  /// Returns true if [deviceType] is [DeviceType.mobile].
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Returns true if [deviceType] is [DeviceType.tablet].
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Returns true if [deviceType] is [DeviceType.desktop].
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// The screen's width in logical pixels, from [MediaQuery].
  double get screenWidth => MediaQuery.of(this).size.width;

  /// The screen's height in logical pixels, from [MediaQuery].
  double get screenHeight => MediaQuery.of(this).size.height;

  /// The screen's current [Orientation], from [MediaQuery].
  Orientation get screenOrientation => MediaQuery.of(this).orientation;

  /// Returns true if the screen is in portrait orientation.
  bool get isPortrait => screenOrientation == Orientation.portrait;

  /// Returns true if the screen is in landscape orientation.
  bool get isLandscape => screenOrientation == Orientation.landscape;

  /// Picks the highest-matching value for the current screen width, falling back to [base].
  T responsive<T>({
    required T base,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
  }) => ResponsiveBreakpoints.valueOf<T>(
    screenWidth,
    base: base,
    sm: sm,
    md: md,
    lg: lg,
    xl: xl,
    xxl: xxl,
  );
}
