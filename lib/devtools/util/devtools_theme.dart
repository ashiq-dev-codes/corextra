import 'package:material_ui/material_ui.dart';

/// The panel's own theme, kept apart from the host app's so the panel looks the same in every app.
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
