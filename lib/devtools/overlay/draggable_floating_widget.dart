import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Which screen edge this widget is currently tucked against.
enum _PeekSide { none, left, right }

/// Positions its content via an internally-managed, user-draggable
/// offset — defaulting near the bottom-right corner of the screen (or
/// wherever [defaultOffset] says). Shared by `DevToolsBubble` and
/// `DevToolsFloatingWindow` so both drag (and edge-peek) identically.
///
/// Must be used as a (possibly indirect) child of a [Stack] — it
/// produces a [Positioned] from its own build method, and relies on the
/// Stack's default hard-edge clipping to visually hide whatever part of
/// it is dragged past the screen edge. [builder] gets `onPanUpdate` /
/// `onPanEnd` callbacks to attach wherever dragging should be possible:
/// the whole widget (a small bubble, say), or just a drag-handle
/// sub-region (e.g. a header bar) so the rest of the content can
/// scroll/tap normally without fighting the drag gesture.
///
/// Dragging past the left or right screen edge is allowed — up to
/// [peekExtent] pixels remaining visible — so it visibly, continuously
/// slides off-screen as you drag it there, the same real-time feedback
/// Android's floating chat-bubble / floating-window widgets give.
/// Releasing the drag then *commits* to fully peeking (leaving just
/// [peekExtent] pixels visible) only if you've pushed it past the edge
/// by at least [commitThreshold] of the available peek travel;
/// otherwise it springs back to flush-at-the-edge, fully visible — so
/// merely nudging it near the edge, or a little past it, doesn't hide
/// it. Never having crossed the edge at all leaves it exactly where
/// dropped, with no snap either way. Tapping a peeked sliver slides it
/// back to fully visible (it doesn't also trigger the widget's own tap
/// action — that would risk firing it by accident on the same tap that
/// was really just "bring this back"). Dragging always works from the
/// fully-visible state, regardless of which edge it's docked at.
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
    this.commitThreshold = 0.5,
    this.peekExtent = 28,
    this.borderRadius = BorderRadius.zero,
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

  /// How far past the edge a drag has to be released — as a fraction of
  /// the available peek travel (`size.width - peekExtent`) — to commit
  /// to fully peeking rather than springing back to flush-at-the-edge.
  final double commitThreshold;

  /// How many pixels remain visible when peeking at an edge.
  final double peekExtent;

  /// Clips the whole [size] bounding box to this shape. A rounded
  /// `Material` sized to exactly fill that box (as the floating window
  /// does) still leaves this box's own four corners uncovered — a
  /// rounded shape inscribed in a same-sized square doesn't reach into
  /// the square's corners — so anything painted behind it within this
  /// widget (the `Overlay` beneath the window's content clips to a hard
  /// rectangular edge by default) shows through there unless this outer
  /// box is rounded to match. Defaults to no rounding, since the bubble
  /// is already a circle with nothing behind it to leak through.
  final BorderRadius borderRadius;

  /// Extra clearance kept beyond the system safe-area inset on the top
  /// and bottom edges — dragging can never bring this widget closer to
  /// either edge than that. The safe-area inset alone marks where the
  /// OS's own status bar / home-indicator / Dynamic Island area ends,
  /// but edge-swipe gesture recognition (pull down for notifications,
  /// swipe up for home, Control Center's top-right corner) can reach
  /// slightly past that boundary — sitting a widget flush against it
  /// risks the OS intercepting drags meant for this widget instead,
  /// leaving it effectively stuck with no way to grab it back.
  static const double _verticalSafetyMargin = 12;

  @override
  State<DraggableFloatingWidget> createState() =>
      _DraggableFloatingWidgetState();
}

class _DraggableFloatingWidgetState extends State<DraggableFloatingWidget>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset?> _offset = ValueNotifier(null);
  late final AnimationController _settleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_onSettleTick);

  Tween<Offset>? _settleTween;
  _PeekSide _peekSide = _PeekSide.none;

  @override
  void didUpdateWidget(covariant DraggableFloatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the caller resizes its content (e.g. the floating window's
    // resize handle), re-clamp to the strict on-screen bounds — not the
    // wider peek-travel ones drag uses — so growing it never leaves
    // part of it hanging off the opposite screen edge from wherever
    // it's docked. Resizing only happens while fully visible anyway.
    final current = _offset.value;
    if (oldWidget.size != widget.size && current != null) {
      final screenSize = MediaQuery.sizeOf(context);
      final safePadding = MediaQuery.paddingOf(context);
      _offset.value = Offset(
        _clamp(current.dx, 0, screenSize.width - widget.size.width),
        _clamp(current.dy, _minY(safePadding), _maxY(screenSize, safePadding)),
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

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  double _minY(EdgeInsets safePadding) =>
      safePadding.top + DraggableFloatingWidget._verticalSafetyMargin;

  double _maxY(Size screenSize, EdgeInsets safePadding) {
    final min = _minY(safePadding);
    final raw =
        screenSize.height -
        widget.size.height -
        safePadding.bottom -
        DraggableFloatingWidget._verticalSafetyMargin;
    // On a short screen with generous safe-area insets there may not be
    // enough room to honor both margins — prefer keeping clear of the
    // top inset (where the OS's own gesture area actually lives) over
    // the bottom one.
    return math.max(min, raw);
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

  void _onPanUpdate(
    DragUpdateDetails details,
    Size screenSize,
    EdgeInsets safePadding,
  ) {
    if (_settleController.isAnimating) _settleController.stop();
    final current = _offset.value ?? _defaultOffset(screenSize);
    final next = current + details.delta;
    // X is allowed to travel past the true screen edges — down to just
    // [peekExtent] pixels remaining visible on either side — so
    // dragging it there visibly, continuously slides it off-screen in
    // real time instead of it staying invisibly pinned at the edge
    // until release. Peeking is horizontal-only: Y is instead kept
    // clear of the top/bottom system safe area (status bar, Dynamic
    // Island, home indicator) plus a small margin, so this widget can
    // never be dragged into the strip where the OS's own edge-swipe
    // gestures live — sitting there risks the OS intercepting drags
    // meant for this widget instead, leaving it stuck with no way to
    // grab it back.
    final minX = -(widget.size.width - widget.peekExtent);
    final maxX = screenSize.width - widget.peekExtent;
    _offset.value = Offset(
      _clamp(next.dx, minX, maxX),
      _clamp(next.dy, _minY(safePadding), _maxY(screenSize, safePadding)),
    );
  }

  void _onPanEnd(DragEndDetails details, Size screenSize) {
    final current = _offset.value ?? _defaultOffset(screenSize);
    final leftOverflow = current.dx < 0 ? -current.dx : 0.0;
    final rightOverflow =
        (current.dx + widget.size.width) > screenSize.width
            ? (current.dx + widget.size.width) - screenSize.width
            : 0.0;

    if (leftOverflow <= 0 && rightOverflow <= 0) {
      return; // never dragged past either edge — leave it exactly there.
    }

    final peekingLeft = leftOverflow > rightOverflow;
    final overflow = peekingLeft ? leftOverflow : rightOverflow;
    final travel = widget.size.width - widget.peekExtent;
    final commitFraction = travel > 0 ? overflow / travel : 1.0;

    if (commitFraction >= widget.commitThreshold) {
      // Pushed far enough past the edge — commit to fully peeking.
      setState(
        () => _peekSide = peekingLeft ? _PeekSide.left : _PeekSide.right,
      );
      final peekedX =
          peekingLeft
              ? -(widget.size.width - widget.peekExtent)
              : screenSize.width - widget.peekExtent;
      _animateTo(Offset(peekedX, current.dy));
    } else {
      // Nudged past the edge but not far enough — spring back to
      // flush-at-the-edge, fully visible, rather than hiding.
      final dockedX =
          peekingLeft ? 0.0 : screenSize.width - widget.size.width;
      _animateTo(Offset(dockedX, current.dy));
    }
  }

  void _reveal(Size screenSize) {
    final current = _offset.value ?? _defaultOffset(screenSize);
    final dockedX =
        _peekSide == _PeekSide.left
            ? 0.0
            : screenSize.width - widget.size.width;
    setState(() => _peekSide = _PeekSide.none);
    _animateTo(Offset(dockedX, current.dy));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final peekSide = _peekSide;
    return ValueListenableBuilder<Offset?>(
      valueListenable: _offset,
      // Built once per peek-state change (a rare, discrete event) — NOT
      // on every drag frame, which is instead driven purely through the
      // ValueListenableBuilder above.
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            width: widget.size.width,
            height: widget.size.height,
            child:
                peekSide == _PeekSide.none
                    ? widget.builder(
                      context,
                      (details) => _onPanUpdate(details, screenSize, safePadding),
                      (details) => _onPanEnd(details, screenSize),
                    )
                    : _PeekNub(
                      peekingLeft: peekSide == _PeekSide.left,
                      onTap: () => _reveal(screenSize),
                    ),
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
