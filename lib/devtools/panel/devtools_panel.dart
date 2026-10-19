import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../corextra_devtools.dart';
import 'devtools_tabs.dart';

/// The full DevTools panel: the Network, Logs and Info tabs under a header with theme, minimize, clear and close buttons.
///
/// `CorextraDevToolsOverlay` shows it for you; build it yourself only to put DevTools on your own screen.
///
/// Example:
/// ```dart
/// // Open DevTools from a "Debug" button in your settings screen
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => DevToolsPanel(
///       onClose: () => Navigator.of(context).pop(),
///       onMinimize: () => Navigator.of(context).pop(),
///     ),
///   ),
/// );
/// ```
class DevToolsPanel extends StatelessWidget {
  /// Creates the panel; both callbacks are required since the header always shows their buttons.
  const DevToolsPanel({
    super.key,
    required this.onClose,
    required this.onMinimize,
  });

  // ---------------- Callbacks ----------------

  /// Called when the user taps the close button.
  final VoidCallback onClose;

  /// Called when the user taps minimize; the overlay shrinks the panel into `DevToolsFloatingWindow` instead of closing it.
  final VoidCallback onMinimize;

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: onClose, onMinimize: onMinimize),
            const Divider(height: 1),
            const Expanded(child: DevToolsTabs()),
          ],
        ),
      ),
    );
  }
}

// ---------------- Private widgets ----------------

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onMinimize});

  final VoidCallback onClose;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(LucideIcons.bug, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'DevTools',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const _ThemeToggleButton(),
          IconButton(
            tooltip: 'Minimize',
            icon: const Icon(LucideIcons.pictureInPicture2),
            onPressed: onMinimize,
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(LucideIcons.trash),
            onPressed: () => CorextraDevTools.instance.resetAll(),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: CorextraDevTools.instance.themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
          icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
          onPressed:
              () =>
                  CorextraDevTools.instance.themeMode =
                      isDark ? ThemeMode.light : ThemeMode.dark,
        );
      },
    );
  }
}
