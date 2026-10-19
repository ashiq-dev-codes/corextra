import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../corextra_devtools.dart';
import '../panel/devtools_tabs.dart';
import '../util/devtools_theme.dart';
import 'draggable_floating_widget.dart';

/// A small floating window with the same DevTools tabs as the full panel, so you can watch live activity while still using your app.
///
/// Drag the header to move it, press and hold the bottom-right corner to resize it within the screen, tap Expand for the full panel, or Close to go back to the bubble.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     const HomeScreen(),
///     DevToolsFloatingWindow(
///       onExpand: () => setState(() => showFullPanel = true),
///       onClose: () => setState(() => showWindow = false),
///     ),
///   ],
/// )
/// ```
class DevToolsFloatingWindow extends StatefulWidget {
  /// Creates a floating window with Expand and Close buttons.
  const DevToolsFloatingWindow({
    super.key,
    required this.onExpand,
    required this.onClose,
  });

  // ---------------- Settings ----------------

  /// Called when Expand is tapped, e.g. to open the full-screen panel.
  final VoidCallback onExpand;

  /// Called when Close is tapped, e.g. to go back to the bubble.
  final VoidCallback onClose;

  @override
  State<DevToolsFloatingWindow> createState() => _DevToolsFloatingWindowState();
}

// ---------------- Private widgets ----------------

class _DevToolsFloatingWindowState extends State<DevToolsFloatingWindow> {
  static const Size _minSize = Size(280, 360);
  static const Size _maxSizeCap = Size(480, 640);

  Size _size = const Size(320, 440);

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  void _onResizeDelta(Offset delta, Size maxAllowed) {
    setState(() {
      _size = Size(
        _clamp(_size.width + delta.dx, _minSize.width, maxAllowed.width),
        _clamp(_size.height + delta.dy, _minSize.height, maxAllowed.height),
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
      // Matches the Material's radius so the box's corners show the app underneath, not what's painted behind the window.
      borderRadius: BorderRadius.circular(16),
      // Top-right by default, since the bottom is where most apps keep the nav bars and main actions a developer needs to reach.
      defaultOffset:
          (screenSize, size) => Offset(screenSize.width - size.width - 16, 64),
      builder:
          (context, onPanUpdate, onPanEnd) => ValueListenableBuilder<ThemeMode>(
            valueListenable: CorextraDevTools.instance.themeModeNotifier,
            builder:
                (context, mode, _) => Theme(
                  data: buildDevToolsTheme(
                    mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                  ),
                  // Its own Overlay sized to the window, so tooltips work but taps outside it still reach the app (see DevToolsBubble).
                  child: Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder:
                            (context) => Stack(
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
                                    onResizeDelta:
                                        (delta) =>
                                            _onResizeDelta(delta, maxAllowed),
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

// Diagonal corner grip that needs a hold before dragging, so swipes through the corner never resize by accident; drawn as an iOS-style crop bracket.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.onResizeDelta});

  final ValueChanged<Offset> onResizeDelta;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  Offset _lastOffset = Offset.zero;

  void _onLongPressStart(LongPressStartDetails details) {
    _lastOffset = Offset.zero;
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    widget.onResizeDelta(details.localOffsetFromOrigin - _lastOffset);
    _lastOffset = details.localOffsetFromOrigin;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        key: const Key('devtools-resize-handle'),
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        behavior: HitTestBehavior.opaque,
        // A generous hit area even though the visible bracket is small.
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 7, bottom: 7),
              child: _CornerBracket(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CornerBracketPainter(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({required this.color});

  final Color color;

  static const double _armLength = 3;
  static const double _radius = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // A quadratic bezier with its control point on the corner rounds it smoothly in any orientation, more reliably than arc sweeps.
    final path =
        Path()
          ..moveTo(size.width - _armLength - _radius, size.height)
          ..lineTo(size.width - _radius, size.height)
          ..quadraticBezierTo(
            size.width,
            size.height,
            size.width,
            size.height - _radius,
          )
          ..lineTo(size.width, size.height - _armLength - _radius);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
