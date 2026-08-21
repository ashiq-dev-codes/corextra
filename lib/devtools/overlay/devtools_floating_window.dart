import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../devtools_controller.dart';
import '../panel/devtools_tabs.dart';
import '../util/devtools_theme.dart';
import 'draggable_floating_widget.dart';

/// A small, draggable, resizable floating window showing the *same*
/// DevTools tab content (Network / Logs / Performance / Info) as the
/// full panel — not a stripped-down summary — just confined to a
/// smaller window that floats over the app instead of covering the
/// whole screen. Lets a developer watch live activity while still
/// freely interacting with (and testing) the rest of the app
/// underneath, closer to inspecting a page in a browser than a
/// full-screen-only panel would allow.
///
/// Drag the header to move it; drag the bottom-right corner grip to
/// resize it (clamped between [_minSize] and a max that's capped by
/// both a fixed ceiling and the available screen size); tap Expand to
/// return to the full-screen panel, or Close to dismiss back to the
/// bubble.
class DevToolsFloatingWindow extends StatefulWidget {
  const DevToolsFloatingWindow({
    super.key,
    required this.onExpand,
    required this.onClose,
  });

  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  State<DevToolsFloatingWindow> createState() =>
      _DevToolsFloatingWindowState();
}

class _DevToolsFloatingWindowState extends State<DevToolsFloatingWindow> {
  static const Size _minSize = Size(280, 360);
  static const Size _maxSizeCap = Size(480, 640);

  Size _size = const Size(320, 440);

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  void _onResizePanUpdate(DragUpdateDetails details, Size maxAllowed) {
    setState(() {
      _size = Size(
        _clamp(_size.width + details.delta.dx, _minSize.width, maxAllowed.width),
        _clamp(
          _size.height + details.delta.dy,
          _minSize.height,
          maxAllowed.height,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxAllowed = Size(
      math.min(_maxSizeCap.width, screenSize.width - 32),
      math.min(_maxSizeCap.height, screenSize.height - 32),
    );

    return DraggableFloatingWidget(
      size: _size,
      // Anchored near the top-right by default, not bottom-right like
      // the bubble — the bottom of the screen is where most app UIs
      // (nav bars, primary actions) live, and that's exactly what a
      // developer testing the app needs clear access to.
      defaultOffset: (screenSize, size) =>
          Offset(screenSize.width - size.width - 16, 64),
      builder: (context, onPanUpdate, onPanEnd) =>
          ValueListenableBuilder<ThemeMode>(
            valueListenable: CorextraDevTools.instance.themeModeNotifier,
            builder: (context, mode, _) => Theme(
              data: buildDevToolsTheme(
                mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
              ),
              // Its own Overlay, sized to exactly this window's bounds
              // (not the whole screen) — the tab content includes
              // tooltips (e.g. the Network tab's copy button) that need
              // one, and because this Overlay's bounds match what's
              // actually visible, it only ever intercepts taps within
              // the window itself, not the app underneath — unlike the
              // full-screen case this pattern deliberately avoids (see
              // `DevToolsBubble`'s doc comment).
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 12,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              GestureDetector(
                                onPanUpdate: onPanUpdate,
                                onPanEnd: onPanEnd,
                                behavior: HitTestBehavior.opaque,
                                child: _WindowHeader(
                                  onExpand: widget.onExpand,
                                  onClose: widget.onClose,
                                ),
                              ),
                              const Divider(height: 1),
                              const Expanded(child: DevToolsTabs()),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _ResizeHandle(
                            onPanUpdate: (details) =>
                                _onResizePanUpdate(details, maxAllowed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _WindowHeader extends StatelessWidget {
  const _WindowHeader({required this.onExpand, required this.onClose});

  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Icon(
            LucideIcons.gripVertical,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'DevTools',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Clear all',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.trash),
            onPressed: () => CorextraDevTools.instance.resetAll(),
          ),
          IconButton(
            tooltip: 'Expand',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.maximize2),
            onPressed: onExpand,
          ),
          IconButton(
            tooltip: 'Close',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.x),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// The bottom-right resize grip — drag to resize the window, iOS/macOS
/// window-corner style.
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onPanUpdate});

  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: Icon(
                LucideIcons.moveDiagonal2,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
