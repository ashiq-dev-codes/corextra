import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../corextra_devtools.dart';
import '../panel/devtools_panel.dart';
import '../util/devtools_theme.dart';
import 'devtools_bubble.dart';
import 'devtools_floating_window.dart';

// What the overlay shows: the bubble, the full panel, or the minimized floating window.
enum _DisplayMode { closed, open, pip }

/// Wraps your app with the DevTools bubble, which opens the in-app panel with Network, Logs and Info tabs.
///
/// Wrap it in `MaterialApp.builder` so the panel sits above your app's Navigator; the panel is mounted only while open, so it never blocks taps on your app.
///
/// Example:
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
///   home: const HomeScreen(),
/// )
/// ```
class CorextraDevToolsOverlay extends StatefulWidget {
  /// Creates the overlay around [child].
  const CorextraDevToolsOverlay({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  // ---------------- Settings ----------------

  /// Sets `CorextraDevTools.instance.enabled` when the overlay is created; defaults to on in debug builds only, e.g. `enabled: true` for a QA build.
  final bool enabled;

  /// Your app, shown under the bubble and the panel.
  final Widget child;

  @override
  State<CorextraDevToolsOverlay> createState() =>
      _CorextraDevToolsOverlayState();
}

// ---------------- Private widgets ----------------

class _CorextraDevToolsOverlayState extends State<CorextraDevToolsOverlay>
    with WidgetsBindingObserver {
  _DisplayMode _mode = _DisplayMode.closed;

  @override
  void initState() {
    super.initState();
    CorextraDevTools.instance.enabled = widget.enabled;
    CorextraDevTools.instance.enabledNotifier.addListener(_onEnabledChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CorextraDevTools.instance.enabledNotifier.removeListener(_onEnabledChanged);
    super.dispose();
  }

  // The panel sits above the app's Navigator, so PopScope can't catch the back button; this hooks the raw platform signal instead.
  @override
  Future<bool> didPopRoute() async {
    if (_mode == _DisplayMode.closed) return false;
    if (CorextraDevTools.instance.handleBackPress()) return true;
    _closePanel();
    return true;
  }

  void _onEnabledChanged() => setState(() {});

  void _openPanel() => setState(() => _mode = _DisplayMode.open);

  void _closePanel() => setState(() => _mode = _DisplayMode.closed);

  void _minimizeToPip() => setState(() => _mode = _DisplayMode.pip);

  @override
  Widget build(BuildContext context) {
    if (!CorextraDevTools.instance.enabled) {
      return widget.child;
    }
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_mode == _DisplayMode.closed) DevToolsBubble(onTap: _openPanel),
          if (_mode == _DisplayMode.pip)
            DevToolsFloatingWindow(onExpand: _openPanel, onClose: _closePanel),
          if (_mode == _DisplayMode.open)
            _PanelHost(onClose: _closePanel, onMinimize: _minimizeToPip),
        ],
      ),
    );
  }
}

// Mounted only while open, since an Overlay absorbs every tap across its bounds even where it paints nothing.
class _PanelHost extends StatelessWidget {
  const _PanelHost({required this.onClose, required this.onMinimize});

  final VoidCallback onClose;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    // A fixed screen size, not the loose constraints at the mount point, keeps the panel's Row/Column/Expanded layout well-defined.
    final screenSize = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        // The panel's own Theme above its Overlay, so it ignores the app's theme and updates live when the mode is toggled.
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: CorextraDevTools.instance.themeModeNotifier,
          builder:
              (context, mode, _) => Theme(
                data: buildDevToolsTheme(
                  mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                ),
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder:
                          (context) => DevToolsPanel(
                            onClose: onClose,
                            onMinimize: onMinimize,
                          ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
