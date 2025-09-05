import 'package:flutter/widgets.dart';

/// Provides helpers to check screen size categories for responsive layouts.
class ResponsiveBreakpoints {
  // Default breakpoint values (modifiable by user)
  static double sm = 375;
  static double md = 500;
  static double lg = 768;
  static double xl = 1024;
  static double xxl = 1280;

  /// Override default breakpoints. All parameters are optional.
  ///
  /// Example:
  /// ```dart
  /// ResponsiveBreakpoints.setCustomBreakpoints(lg: 900, xl: 1200);
  /// ```
  static void setCustomBreakpoints({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    if (sm != null) ResponsiveBreakpoints.sm = sm;
    if (md != null) ResponsiveBreakpoints.md = md;
    if (lg != null) ResponsiveBreakpoints.lg = lg;
    if (xl != null) ResponsiveBreakpoints.xl = xl;
    if (xxl != null) ResponsiveBreakpoints.xxl = xxl;
  }

  // --- Context-based helpers ---
  static double _w(BuildContext context) => MediaQuery.of(context).size.width;

  /// Returns true if width from [BuildContext] is ≥ sm.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isSmContext(context)) {
  ///   // layout for small screen
  /// }
  /// ```
  static bool isSmContext(BuildContext context) => _w(context) >= sm;

  /// Returns true if width from [BuildContext] is ≥ md.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isMdContext(context)) {
  ///   // layout for medium screen
  /// }
  /// ```
  static bool isMdContext(BuildContext context) => _w(context) >= md;

  /// Returns true if width from [BuildContext] is ≥ lg.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isLgContext(context)) {
  ///   // layout for large screen
  /// }
  /// ```
  static bool isLgContext(BuildContext context) => _w(context) >= lg;

  /// Returns true if width from [BuildContext] is ≥ xl.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXlContext(context)) {
  ///   // layout for extra large screen
  /// }
  /// ```
  static bool isXlContext(BuildContext context) => _w(context) >= xl;

  /// Returns true if width from [BuildContext] is ≥ xxl.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isxxlContext(context)) {
  ///   // layout for XXL screen
  /// }
  /// ```
  static bool isxxlContext(BuildContext context) => _w(context) >= xxl;

  // --- Constraints-based helpers ---

  /// Returns true if width from [BoxConstraints] is ≥ sm.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isSm(constraints)) {
  ///   // layout for small screen
  /// }
  /// ```
  static bool isSm(BoxConstraints constraints) => constraints.maxWidth >= sm;

  /// Returns true if width from [BoxConstraints] is ≥ md.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isMd(constraints)) {
  ///   // layout for medium screen
  /// }
  /// ```
  static bool isMd(BoxConstraints constraints) => constraints.maxWidth >= md;

  /// Returns true if width from [BoxConstraints] is ≥ lg.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isLg(constraints)) {
  ///   // layout for large screen
  /// }
  /// ```
  static bool isLg(BoxConstraints constraints) => constraints.maxWidth >= lg;

  /// Returns true if width from [BoxConstraints] is ≥ xl.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXl(constraints)) {
  ///   // layout for extra large screen
  /// }
  /// ```
  static bool isXl(BoxConstraints constraints) => constraints.maxWidth >= xl;

  /// Returns true if width from [BoxConstraints] is ≥ xxl.
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isxxl(constraints)) {
  ///   // layout for XXL screen
  /// }
  /// ```
  static bool isxxl(BoxConstraints constraints) => constraints.maxWidth >= xxl;

  // --- Utility: breakpoint-based selection ---
  /// Returns a value depending on the current screen width.
  ///
  /// The first matching breakpoint (from largest to smallest) is returned.
  /// If none match, [base] is used.
  ///
  /// Example:
  /// ```dart
  /// LayoutBuilder(
  ///   builder: (context, constraints) {
  ///     return ResponsiveBreakpoints.when(
  ///       constraints,
  ///       base: () => const Text("Base"),
  ///       smBuilder: () => const Text("≥ Small"),
  ///       mdBuilder: () => const Text("≥ Medium"),
  ///       lgBuilder: () => const Text("≥ Large"),
  ///       xlBuilder: () => const Text("≥ Extra Large"),
  ///       xxlBuilder: () => const Text("≥ 2XL"),
  ///     );
  ///   },
  /// );
  /// ```
  static T when<T>(
    BoxConstraints constraints, {
    required T Function() base,
    T Function()? smBuilder,
    T Function()? mdBuilder,
    T Function()? lgBuilder,
    T Function()? xlBuilder,
    T Function()? xxlBuilder,
  }) {
    final w = constraints.maxWidth;
    if (w >= xxl && xxlBuilder != null) return xxlBuilder();
    if (w >= xl && xlBuilder != null) return xlBuilder();
    if (w >= lg && lgBuilder != null) return lgBuilder();
    if (w >= md && mdBuilder != null) return mdBuilder();
    if (w >= sm && smBuilder != null) return smBuilder();
    return base();
  }
}
