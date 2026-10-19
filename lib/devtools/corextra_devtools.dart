import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'stores/log_entry_store.dart';
import 'stores/network_event_store.dart';

/// The one place DevTools keeps its settings and captured data, in memory only for this app run.
///
/// DevTools is on in debug builds and off in release, so it never records in production unless you turn it on.
///
/// Example:
/// ```dart
/// // Turn it on for a QA build
/// CorextraDevTools.instance.enabled = true;
///
/// // Read what was captured
/// final requests = CorextraDevTools.instance.network.events;
/// ```
class CorextraDevTools {
  CorextraDevTools._internal();

  /// The shared DevTools instance.
  static final CorextraDevTools instance = CorextraDevTools._internal();

  // ---------------- Settings ----------------

  /// Notifies listeners when [enabled] changes.
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(kDebugMode);

  /// Whether DevTools records data and shows its bubble; defaults to on in debug builds only.
  ///
  /// Example:
  /// ```dart
  /// CorextraDevTools.instance.enabled = true;  // e.g. in a QA build
  /// ```
  bool get enabled => enabledNotifier.value;

  set enabled(bool value) => enabledNotifier.value = value;

  /// Notifies listeners when [themeMode] changes.
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  /// The panel's own light or dark theme, separate from your app's; defaults to dark.
  ///
  /// Example:
  /// ```dart
  /// CorextraDevTools.instance.themeMode = ThemeMode.light;
  /// ```
  ThemeMode get themeMode => themeModeNotifier.value;

  set themeMode(ThemeMode value) => themeModeNotifier.value = value;

  // ---------------- Captured data ----------------

  /// The captured requests and socket messages.
  final NetworkEventStore network = NetworkEventStore();

  /// The captured log lines.
  final LogEntryStore logs = LogEntryStore();

  /// Clears every captured request and log line; [enabled] stays as it is.
  ///
  /// Example:
  /// ```dart
  /// CorextraDevTools.instance.resetAll(); // e.g. when the user logs out
  /// ```
  void resetAll() {
    network.clear();
    logs.clear();
  }

  // ---------------- Back button ----------------

  final List<VoidCallback> _backHandlers = [];

  /// Makes Android's back button call [handler] until the returned callback is called; used by the panel's nested views.
  VoidCallback pushBackHandler(VoidCallback handler) {
    _backHandlers.add(handler);
    return () => _backHandlers.remove(handler);
  }

  /// Calls the newest back handler, if any, and returns whether one ran.
  bool handleBackPress() {
    if (_backHandlers.isEmpty) return false;
    _backHandlers.last();
    return true;
  }
}
