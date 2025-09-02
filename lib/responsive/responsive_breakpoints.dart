import 'package:flutter/widgets.dart';

/// Provides helpers to check screen size categories for responsive layouts.
class ResponsiveBreakpoints {
  // Default breakpoint values (modifiable by user)
  static double xsMax = 375;
  static double smMax = 500;
  static double mdMax = 768;
  static double lgMax = 1024;
  static double xlMax = 1280;

  /// Override default breakpoints. All parameters are optional.
  ///
  /// Example:
  /// ```dart
  /// ResponsiveBreakpoints.setCustomBreakpoints(xsMax: 500, mdMax: 1100);
  /// ```
  static void setCustomBreakpoints({
    double? xsMax,
    double? smMax,
    double? mdMax,
    double? lgMax,
    double? xlMax,
  }) {
    if (xsMax != null) ResponsiveBreakpoints.xsMax = xsMax;
    if (smMax != null) ResponsiveBreakpoints.smMax = smMax;
    if (mdMax != null) ResponsiveBreakpoints.mdMax = mdMax;
    if (lgMax != null) ResponsiveBreakpoints.lgMax = lgMax;
    if (xlMax != null) ResponsiveBreakpoints.xlMax = xlMax;
  }

  /// Returns true if width from [BoxConstraints] is less than xsMax (extra small).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXS(constraints)) {
  ///   // layout for extra small screen
  /// }
  /// ```
  static bool isXS(BoxConstraints constraints) => constraints.maxWidth < xsMax;

  /// Returns true if width from [BuildContext] is less than xsMax (extra small).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXSContext(context)) {
  ///   // layout for extra small screen
  /// }
  /// ```
  static bool isXSContext(BuildContext context) =>
      MediaQuery.of(context).size.width < xsMax;

  /// Returns true if width from [BoxConstraints] is between xsMax and smMax (small).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isSM(constraints)) {
  ///   // layout for small screen
  /// }
  /// ```
  static bool isSM(BoxConstraints constraints) =>
      constraints.maxWidth >= xsMax && constraints.maxWidth < smMax;

  /// Returns true if width from [BuildContext] is between xsMax and smMax (small).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isSMContext(context)) {
  ///   // layout for small screen
  /// }
  /// ```
  static bool isSMContext(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= xsMax && w < smMax;
  }

  /// Returns true if width from [BoxConstraints] is between smMax and mdMax (medium).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isMD(constraints)) {
  ///   // layout for medium screen
  /// }
  /// ```
  static bool isMD(BoxConstraints constraints) =>
      constraints.maxWidth >= smMax && constraints.maxWidth < mdMax;

  /// Returns true if width from [BuildContext] is between smMax and mdMax (medium).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isMDContext(context)) {
  ///   // layout for medium screen
  /// }
  /// ```
  static bool isMDContext(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= smMax && w < mdMax;
  }

  /// Returns true if width from [BoxConstraints] is between mdMax and lgMax (large).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isLG(constraints)) {
  ///   // layout for large screen
  /// }
  /// ```
  static bool isLG(BoxConstraints constraints) =>
      constraints.maxWidth >= mdMax && constraints.maxWidth < lgMax;

  /// Returns true if width from [BuildContext] is between mdMax and lgMax (large).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isLGContext(context)) {
  ///   // layout for large screen
  /// }
  /// ```
  static bool isLGContext(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mdMax && w < lgMax;
  }

  /// Returns true if width from [BoxConstraints] is between lgMax and xlMax (extra large).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXL(constraints)) {
  ///   // layout for extra large screen
  /// }
  /// ```
  static bool isXL(BoxConstraints constraints) =>
      constraints.maxWidth >= lgMax && constraints.maxWidth < xlMax;

  /// Returns true if width from [BuildContext] is between lgMax and xlMax (extra large).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXLContext(context)) {
  ///   // layout for extra large screen
  /// }
  /// ```
  static bool isXLContext(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= lgMax && w < xlMax;
  }

  /// Returns true if width from [BoxConstraints] is greater than or equal to xlMax (xxl).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXXL(constraints)) {
  ///   // layout for very large screen
  /// }
  /// ```
  static bool isXXL(BoxConstraints constraints) =>
      constraints.maxWidth >= xlMax;

  /// Returns true if width from [BuildContext] is greater than or equal to xlMax (xxl).
  ///
  /// Example:
  /// ```dart
  /// if (ResponsiveBreakpoints.isXXLContext(context)) {
  ///   // layout for very large screen
  /// }
  /// ```
  static bool isXXLContext(BuildContext context) =>
      MediaQuery.of(context).size.width >= xlMax;
}
