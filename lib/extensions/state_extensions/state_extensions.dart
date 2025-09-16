import 'package:corextra/logs/debug_log.dart';
import 'package:flutter/widgets.dart';

/// Extension to safely call setState only if the widget is mounted.
extension SafeSetStateExtension on State {
  /// Safely updates the widget state.
  ///
  /// This prevents errors that occur when calling `setState` on
  /// an unmounted widget.
  ///
  /// Example:
  /// ```dart
  /// class MyWidget extends StatefulWidget { ... }
  ///
  /// class _MyWidgetState extends State<MyWidget> {
  ///   int counter = 0;
  ///
  ///   void increment() {
  ///     safeSetState(() {
  ///       counter++;
  ///     });
  ///   }
  /// }
  /// ```
  void safeSetState(VoidCallback callback) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(callback);
    } else {
      debugLog(
        'WARNING: Attempted to update state on an unmounted widget.',
        level: LogLevel.warning,
      );
    }
  }
}
