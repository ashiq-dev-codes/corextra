import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../devtools_controller.dart';
import '../panel/devtools_tabs.dart';
import '../util/devtools_theme.dart';
import 'draggable_floating_widget.dart';

/// A small, draggable floating window showing the *same* DevTools tab
/// content (Network / Logs / Performance / Info) as the full panel —
/// not a stripped-down summary — just confined to a smaller window that
/// floats over the app instead of covering the whole screen. Lets a
/// developer watch live activity while still freely interacting with
/// (and testing) the rest of the app underneath, closer to inspecting a
/// page in a browser than a full-screen-only panel would allow.
///
/// Drag the header to move it; tap Expand to return to the full-screen
/// panel, or Close to dismiss back to the bubble.
class DevToolsFloatingWindow extends StatelessWidget {
  const DevToolsFloatingWindow({
    super.key,
    required this.onExpand,
    required this.onClose,
  });

  final VoidCallback onExpand;
  final VoidCallback onClose;

  static const _size = Size(320, 440);

  @override
  Widget build(BuildContext context) {
    return DraggableFloatingWidget(
      size: _size,
      // Anchored near the top-right by default, not bottom-right like
      // the bubble — the bottom of the screen is where most app UIs
      // (nav bars, primary actions) live, and that's exactly what a
      // developer testing the app needs clear access to.
      defaultOffset: (screenSize, size) =>
          Offset(screenSize.width - size.width - 16, 64),
      builder: (context, onPanUpdate, onPanEnd) => ValueListenableBuilder<ThemeMode>(
        valueListenable: CorextraDevTools.instance.themeModeNotifier,
        builder: (context, mode, _) => Theme(
          data: buildDevToolsTheme(
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          ),
          // Its own Overlay, sized to exactly this window's bounds (not
          // the whole screen) — the tab content includes tooltips (e.g.
          // the Network tab's copy button) that need one, and because
          // this Overlay's bounds match what's actually visible, it
          // only ever intercepts taps within the window itself, not the
          // app underneath — unlike the full-screen case this pattern
          // deliberately avoids (see `DevToolsBubble`'s doc comment).
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Material(
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
                          onExpand: onExpand,
                          onClose: onClose,
                        ),
                      ),
                      const Divider(height: 1),
                      const Expanded(child: DevToolsTabs()),
                    ],
                  ),
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
