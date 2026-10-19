import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'draggable_floating_widget.dart';

/// The small draggable bug button that opens the DevTools panel; place it inside a [Stack].
///
/// It has no [Tooltip] on purpose: a tooltip needs an `Overlay` that would stay mounted and block taps on your app everywhere.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     const HomeScreen(),
///     DevToolsBubble(onTap: () => setState(() => panelOpen = true)),
///   ],
/// )
/// ```
class DevToolsBubble extends StatelessWidget {
  /// Creates a bubble that calls [onTap] when tapped.
  const DevToolsBubble({super.key, required this.onTap});

  // ---------------- Settings ----------------

  /// Called when the bubble is tapped, e.g. to open the panel.
  final VoidCallback onTap;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return DraggableFloatingWidget(
      size: const Size(_size, _size),
      // A circular clip hides the grey square the RepaintBoundary and elevation shadow leave in the box's corners around the circle.
      borderRadius: BorderRadius.circular(_size / 2),
      builder:
          (context, onPanUpdate, onPanEnd) => GestureDetector(
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            child: Material(
              color: Colors.black87,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const Icon(
                  LucideIcons.bug,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
    );
  }
}
