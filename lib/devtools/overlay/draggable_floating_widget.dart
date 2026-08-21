import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Which screen edge this widget is currently tucked against.
enum _PeekSide { none, left, right }

/// Positions its content via an internally-managed, user-draggable
/// offset — defaulting near the bottom-right corner of the screen (or
/// wherever [defaultOffset] says), clamped so it can never be dragged
/// off-screen. Shared by `DevToolsBubble` and `DevToolsFloatingWindow`
/// so both drag (and edge-peek) identically.
///
/// Must be used as a (possibly indirect) child of a [Stack] — it
/// produces a [Positioned] from its own build method, and relies on the
/// Stack's default hard-edge clipping to visually hide the "peeked"
/// portion that sits past the screen edge. [builder] gets `onPanUpdate`
/// / `onPanEnd` callbacks to attach wherever dragging should be
/// possible: the whole widget (a small bubble, say), or just a
/// drag-handle sub-region (e.g. a header bar) so the rest of the content
/// can scroll/tap normally without fighting the drag gesture.
///
/// Releasing a drag within [edgeSnapThreshold] of the left or right
/// screen edge slides the widget mostly off-screen at that edge — like
/// Android's floating chat-bubble / floating-window widgets — leaving
/// just [peekExtent] pixels visible so it stays out of the way. Tapping
/// that peeking sliver slides it back to fully visible (it doesn't also
/// trigger the widget's own tap action — that would risk firing it by
/// accident on the same tap that was really just "bring this back").
/// Dragging always works from the fully-visible state, regardless of
/// which edge it's docked at.
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
    this.edgeSnapThreshold = 80,
    this.peekExtent = 28,
  });

  final Size size;
  final Widget Function(
    BuildContext context,
    GestureDragUpdateCallback onPanUpdate,
    GestureDragEndCallback onPanEnd,
  )
  builder;

  /// Computes the initial position from the screen size and this
  /// widget's [size]; defaults to near the bottom-right corner.
  final Offset Function(Size screenSize, Size widgetSize)? defaultOffset;

  /// How close to the left/right screen edge a drag has to end for the
  /// widget to dock and peek there, in logical pixels.
  final double edgeSnapThreshold;

  /// How many pixels remain visible when peeking at an edge.
  final double peekExtent;

  @override
  State<DraggableFloatingWidget> createState() =>
      _DraggableFloatingWidgetState();
}

class _DraggableFloatingWidgetState extends State<DraggableFloatingWidget>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset?> _offset = ValueNotifier(null);
  late final AnimationController _settleController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
        ..addListener(_onSettleTick);

  Tween<Offset>? _settleTween;
  _PeekSide _peekSide = _PeekSide.none;

  @override
  void didUpdateWidget(covariant DraggableFloatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the caller resizes its content (e.g. the floating window's
    // resize handle), re-clamp so growing it never leaves part of it
    // hanging off the opposite screen edge from wherever it's docked.
    final current = _offset.value;
    if (oldWidget.size != widget.size && current != null) {
      final screenSize = MediaQuery.sizeOf(context);
      _offset.value = Offset(
        _clamp(current.dx, screenSize.width - widget.size.width),
        _clamp(current.dy, screenSize.height - widget.size.height),
      );
    }
  }

  @override
  void dispose() {
    _settleController.dispose();
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

  void _onSettleTick() {
    final tween = _settleTween;
    if (tween == null) return;
    _offset.value = tween.transform(
      Curves.easeOutCubic.transform(_settleController.value),
    );
  }

  void _animateTo(Offset target) {
    _settleTween = Tween<Offset>(begin: _offset.value ?? target, end: target);
    _settleController.forward(from: 0);
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    if (_settleController.isAnimating) _settleController.stop();
    final current = _offset.value ?? _defaultOffset(screenSize);
    final next = current + details.delta;
    _offset.value = Offset(
      _clamp(next.dx, screenSize.width - widget.size.width),
      _clamp(next.dy, screenSize.height - widget.size.height),
    );
  }

  void _onPanEnd(DragEndDetails details, Size screenSize) {
    final current = _offset.value ?? _defaultOffset(screenSize);
    final distanceToLeft = current.dx;
    final distanceToRight =
        screenSize.width - (current.dx + widget.size.width);
    if (distanceToLeft > widget.edgeSnapThreshold &&
        distanceToRight > widget.edgeSnapThreshold) {
      return; // released away from both edges — leave it exactly there.
    }
    final peekLeft = distanceToLeft <= distanceToRight;
    setState(() => _peekSide = peekLeft ? _PeekSide.left : _PeekSide.right);
    final peekedX = peekLeft
        ? -(widget.size.width - widget.peekExtent)
        : screenSize.width - widget.peekExtent;
    _animateTo(Offset(peekedX, current.dy));
  }

  void _reveal(Size screenSize) {
    final current = _offset.value ?? _defaultOffset(screenSize);
    final dockedX = _peekSide == _PeekSide.left
        ? 0.0
        : screenSize.width - widget.size.width;
    setState(() => _peekSide = _PeekSide.none);
    _animateTo(Offset(dockedX, current.dy));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final peekSide = _peekSide;
    return ValueListenableBuilder<Offset?>(
      valueListenable: _offset,
      // Built once per peek-state change (a rare, discrete event) — NOT
      // on every drag frame, which is instead driven purely through the
      // ValueListenableBuilder above.
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: peekSide == _PeekSide.none
              ? widget.builder(
                  context,
                  (details) => _onPanUpdate(details, screenSize),
                  (details) => _onPanEnd(details, screenSize),
                )
              : _PeekNub(
                  peekingLeft: peekSide == _PeekSide.left,
                  onTap: () => _reveal(screenSize),
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

/// The small tab shown once docked and peeking at a screen edge — most
/// of the widget's normal content is off-screen at this point, so this
/// intentionally isn't that content, just a clear "tap to bring back"
/// affordance sized to the same box (only `peekExtent` pixels of which
/// end up on-screen; the rest is clipped by the Stack).
class _PeekNub extends StatelessWidget {
  const _PeekNub({required this.peekingLeft, required this.onTap});

  /// Whether this is peeking at the *left* edge — i.e. the visible
  /// sliver is this box's right side, and the built-in chevron points
  /// right (toward the screen) to invite tapping it back into view.
  final bool peekingLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.horizontal(
        left: peekingLeft ? Radius.zero : const Radius.circular(12),
        right: peekingLeft ? const Radius.circular(12) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        child: Align(
          alignment: peekingLeft ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              peekingLeft ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
