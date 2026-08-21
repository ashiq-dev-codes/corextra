import 'package:flutter/material.dart';

/// Builds the DevTools panel's own theme. Intentionally decoupled from
/// the host app's theme, so the panel always looks the same regardless
/// of what the app around it looks like.
ThemeData buildDevToolsTheme(Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}
