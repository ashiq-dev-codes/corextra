import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A small, self-positioning draggable floating button used to open the
/// DevTools panel. Must be used as a (possibly indirect) child of a
/// [Stack] — it produces a [Positioned] from its own build method.
///
/// Deliberately has no [Tooltip]: this widget is meant to stay mounted
/// for as long as DevTools is enabled, and a `Tooltip` requires an
/// ancestor `Overlay` to exist at build time — which would mean keeping
/// a full-screen `Overlay` mounted permanently just for this button,
/// silently absorbing every tap/scroll meant for the host app underneath
/// wherever it doesn't paint anything. The panel itself (which *is*
/// wrapped in an `Overlay`, but only while it's actually open) still
/// supports tooltips fine.
class DevToolsBubble extends StatefulWidget {
  const DevToolsBubble({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<DevToolsBubble> createState() => _DevToolsBubbleState();
}

class _DevToolsBubbleState extends State<DevToolsBubble> {
  static const _size = 48.0;

  Offset? _offset;

  Offset _defaultOffset(Size screenSize) {
    return Offset(screenSize.width - _size - 16, screenSize.height - _size - 96);
  }

  double _clamp(double value, double max) {
    if (value < 0) return 0;
    if (value > max) return max;
    return value;
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    final current = _offset ?? _defaultOffset(screenSize);
    final next = current + details.delta;
    setState(() {
      _offset = Offset(
        _clamp(next.dx, screenSize.width - _size),
        _clamp(next.dy, screenSize.height - _size),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final offset = _offset ?? _defaultOffset(screenSize);
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) => _onPanUpdate(details, screenSize),
        child: Material(
          color: Colors.black87,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: widget.onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: _size,
              height: _size,
              child: Icon(LucideIcons.bug, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
