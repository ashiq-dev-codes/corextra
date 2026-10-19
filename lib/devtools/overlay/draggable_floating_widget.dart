import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Which screen edge the widget is tucked against.
enum _PeekSide { none, left, right }

/// Floats its content over a [Stack] where the user can drag it, and tucks it against the left or right edge when pushed past it.
///
/// Put it inside a [Stack]: it builds a [Positioned] and relies on the Stack's clipping to hide the part dragged off-screen.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     const HomeScreen(),
///     DraggableFloatingWidget(
///       size: const Size(56, 56),
///       borderRadius: BorderRadius.circular(28),
///       builder: (context, onPanUpdate, onPanEnd) => GestureDetector(
///         onPanUpdate: onPanUpdate,
///         onPanEnd: onPanEnd,
///         child: const CircleAvatar(child: Icon(Icons.chat)),
///       ),
///     ),
///   ],
/// )
/// ```
class DraggableFloatingWidget extends StatefulWidget {
  /// Creates a draggable widget of [size] built by [builder].
  const DraggableFloatingWidget({
    super.key,
    required this.size,
    required this.builder,
    this.defaultOffset,
    this.commitThreshold = 0.5,
    this.peekExtent = 28,
    this.borderRadius = BorderRadius.zero,
  });

  // ---------------- Settings ----------------

  /// The content's width and height, e.g. `const Size(48, 48)`.
  final Size size;

  /// Builds the content; attach `onPanUpdate` and `onPanEnd` only where a drag should start, e.g. a header, so the rest can still scroll and tap.
  final Widget Function(
    BuildContext context,
    GestureDragUpdateCallback onPanUpdate,
    GestureDragEndCallback onPanEnd,
  )
  builder;

  /// The starting position from the screen size and [size]; defaults to near the bottom-right corner.
  ///
  /// Example:
  /// ```dart
  /// defaultOffset: (screenSize, size) =>
  ///     Offset(screenSize.width - size.width - 16, 64), // top-right
  /// ```
  final Offset Function(Size screenSize, Size widgetSize)? defaultOffset;

  /// How far past an edge, as a fraction of `size.width - peekExtent`, a drag must end to tuck it away; less springs back fully visible.
  final double commitThreshold;

  /// How many pixels stay visible while tucked against an edge.
  final double peekExtent;

  /// Clips the box to this shape so a rounded child's corners don't show what's painted behind it, e.g. `BorderRadius.circular(16)`; defaults to none.
  final BorderRadius borderRadius;

  // Extra gap beyond the safe area, since OS edge swipes reach past it and could steal drags, leaving the widget stuck.
  static const double _verticalSafetyMargin = 12;

  @override
  State<DraggableFloatingWidget> createState() =>
      _DraggableFloatingWidgetState();
}

// ---------------- Private widgets ----------------

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
    // On resize, re-clamp to the on-screen bounds, not the wider drag ones, so growing never leaves it hanging off the opposite edge.
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
    // On a short screen, keep clear of the top inset, where the OS gesture area lives, before the bottom one.
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
    // X may pass the edges down to peekExtent so it slides off live; Y stays out of the safe area, where OS edge swipes could steal the drag.
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
      // Not far enough past the edge, so spring back flush and fully visible instead of hiding.
      final dockedX = peekingLeft ? 0.0 : screenSize.width - widget.size.width;
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
      // Built once per peek change, not per drag frame, since rebuilding the floating window's tabs every frame makes dragging janky.
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
                      (details) =>
                          _onPanUpdate(details, screenSize, safePadding),
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

// The "tap to bring back" tab shown while tucked; it only reveals the widget, so the same tap can't fire the content's own action by accident.
class _PeekNub extends StatelessWidget {
  const _PeekNub({required this.peekingLeft, required this.onTap});

  // Tucked at the left edge, so the visible sliver is the right side and the chevron points right, toward the screen.
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
