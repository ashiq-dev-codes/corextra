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
///
/// The dragged content is built once and reused on every drag frame —
/// only the [Positioned] offset itself updates per frame, via a
/// [ValueListenableBuilder] rather than `setState` on this whole widget.
/// For a small bubble that distinction barely matters, but the floating
/// window's content is a full tab set (Network/Logs/Performance/Info);
/// rebuilding all of that on every pixel of drag movement is exactly
/// the kind of per-frame cost that reads as janky, laggy dragging.
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
  final ValueNotifier<Offset?> _offset = ValueNotifier(null);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

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
    final current = _offset.value ?? _defaultOffset(screenSize);
    final next = current + details.delta;
    _offset.value = Offset(
      _clamp(next.dx, screenSize.width - widget.size.width),
      _clamp(next.dy, screenSize.height - widget.size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return ValueListenableBuilder<Offset?>(
      valueListenable: _offset,
      // Built once (or whenever this State's own build() re-runs, e.g.
      // on rotation) — NOT on every drag frame. RepaintBoundary turns
      // moving it into a cheap compositor-level operation instead of a
      // repaint of the affected screen region on every frame.
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: widget.builder(
            context,
            (details) => _onPanUpdate(details, screenSize),
          ),
        ),
      ),
      builder: (context, offset, child) {
        final resolved = offset ?? _defaultOffset(screenSize);
        return Positioned(left: resolved.dx, top: resolved.dy, child: child!);
      },
    );
  }
}
