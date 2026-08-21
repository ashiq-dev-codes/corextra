import 'package:flutter/material.dart';

/// Positions its content via an internally-managed, user-draggable
/// offset — defaulting near the bottom-right corner of the screen (or
/// wherever [defaultOffset] says), clamped so it can never be dragged
/// off-screen. Shared by `DevToolsBubble` and `DevToolsFloatingWindow`
/// so both drag identically.
///
/// Must be used as a (possibly indirect) child of a [Stack] — it
/// produces a [Positioned] from its own build method. [builder] gets a
/// `onPanUpdate` callback to attach wherever dragging should be
/// possible: the whole widget (a small bubble, say), or just a
/// drag-handle sub-region (e.g. a header bar) so the rest of the content
/// can scroll/tap normally without fighting the drag gesture.
class DraggableFloatingWidget extends StatefulWidget {
  const DraggableFloatingWidget({
    super.key,
    required this.size,
    required this.builder,
    this.defaultOffset,
  });

  final Size size;
  final Widget Function(
    BuildContext context,
    GestureDragUpdateCallback onPanUpdate,
  )
  builder;

  /// Computes the initial position from the screen size and this
  /// widget's [size]; defaults to near the bottom-right corner.
  final Offset Function(Size screenSize, Size widgetSize)? defaultOffset;

  @override
  State<DraggableFloatingWidget> createState() =>
      _DraggableFloatingWidgetState();
}

class _DraggableFloatingWidgetState extends State<DraggableFloatingWidget> {
  Offset? _offset;

  Offset _defaultOffset(Size screenSize) {
    final custom = widget.defaultOffset;
    if (custom != null) return custom(screenSize, widget.size);
    return Offset(
      screenSize.width - widget.size.width - 16,
      screenSize.height - widget.size.height - 96,
    );
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
        _clamp(next.dx, screenSize.width - widget.size.width),
        _clamp(next.dy, screenSize.height - widget.size.height),
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
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: widget.builder(
          context,
          (details) => _onPanUpdate(details, screenSize),
        ),
      ),
    );
  }
}
