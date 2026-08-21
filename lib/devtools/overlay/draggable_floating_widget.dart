import 'package:flutter/material.dart';

/// Positions [child] via an internally-managed, user-draggable offset —
/// defaulting near the bottom-right corner of the screen, clamped so it
/// can never be dragged off-screen. Shared by `DevToolsBubble` and the
/// PiP status chip so both drag identically.
///
/// Must be used as a (possibly indirect) child of a [Stack] — it
/// produces a [Positioned] from its own build method. [child] is
/// responsible for its own tap handling (e.g. via `InkWell`) — this
/// widget only ever attaches a pan (drag) gesture, so tap and drag don't
/// fight over the same gesture recognizer.
class DraggableFloatingWidget extends StatefulWidget {
  const DraggableFloatingWidget({
    super.key,
    required this.size,
    required this.child,
  });

  final Size size;
  final Widget child;

  @override
  State<DraggableFloatingWidget> createState() =>
      _DraggableFloatingWidgetState();
}

class _DraggableFloatingWidgetState extends State<DraggableFloatingWidget> {
  Offset? _offset;

  Offset _defaultOffset(Size screenSize) {
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
      child: GestureDetector(
        onPanUpdate: (details) => _onPanUpdate(details, screenSize),
        child: SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: widget.child,
        ),
      ),
    );
  }
}
