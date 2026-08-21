import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'draggable_floating_widget.dart';

/// A small, draggable floating button used to open the DevTools panel.
/// Must be used as a (possibly indirect) child of a [Stack] (see
/// [DraggableFloatingWidget]).
///
/// Deliberately has no [Tooltip]: this widget is meant to stay mounted
/// for as long as DevTools is enabled, and a `Tooltip` requires an
/// ancestor `Overlay` to exist at build time — which would mean keeping
/// a full-screen `Overlay` mounted permanently just for this button,
/// silently absorbing every tap/scroll meant for the host app underneath
/// wherever it doesn't paint anything. The panel itself (which *is*
/// wrapped in an `Overlay`, but only while it's actually open) still
/// supports tooltips fine.
class DevToolsBubble extends StatelessWidget {
  const DevToolsBubble({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return DraggableFloatingWidget(
      size: const Size(_size, _size),
      builder: (context, onPanUpdate) => GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Material(
          color: Colors.black87,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Icon(LucideIcons.bug, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
