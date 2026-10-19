import 'dart:math' as math;

import 'package:flutter/gestures.dart' show Drag, DragStartBehavior;
import 'package:flutter/material.dart';

/// A slim edge scrollbar with a wide invisible grab strip, so a finger never has to hit the thin thumb; drag or tap anywhere in the strip to scroll.
class DevToolsEdgeScrollbar extends StatefulWidget {
  const DevToolsEdgeScrollbar({
    super.key,
    required this.controller,
    required this.axis,
    this.startInset = 0,
    this.endInset = 0,
    this.touchWidth = 32,
    this.thumbKeyPrefix = 'scrollbar-thumb',
  });

  // ---------------- Settings ----------------

  /// The controller of the scrollable this bar drives.
  final ScrollController controller;

  /// Vertical for the right edge, horizontal for the bottom edge.
  final Axis axis;

  /// How far the track stays clear of the edge's start, e.g. of a header.
  final double startInset;

  /// How far the track stays clear of the edge's end, e.g. of the floating action bar.
  final double endInset;

  /// Width of the invisible grab strip — narrower over tappable rows, so it takes less of each row's tap area.
  final double touchWidth;

  /// Thumb keys are this plus the axis name, so tests can tell scrollbars apart.
  final String thumbKeyPrefix;

  @override
  State<DevToolsEdgeScrollbar> createState() => _DevToolsEdgeScrollbarState();
}

// ---------------- State ----------------

class _DevToolsEdgeScrollbarState extends State<DevToolsEdgeScrollbar> {
  static const _thickness = 5.0;

  // Thicker, and accent-colored, while held so it's clear the thumb was grabbed.
  static const _activeThickness = 9.0;
  static const _minThumbLength = 36.0;

  /// A drag starting this close to the thumb grabs it where it is; further away, the thumb first jumps under the finger.
  static const _grabTolerance = 12.0;

  bool _active = false;
  Drag? _drag;
  double _trackLength = 0;

  // ---------------- Geometry ----------------

  bool get _vertical => widget.axis == Axis.vertical;

  /// The position to drive, or null while there's nothing to scroll along this axis.
  ScrollPosition? get _position {
    if (!widget.controller.hasClients) return null;
    final position = widget.controller.position;
    if (!position.hasContentDimensions ||
        !position.hasViewportDimension ||
        position.maxScrollExtent <= 0) {
      return null;
    }
    return position;
  }

  double _thumbLength(ScrollPosition position) {
    final visibleFraction =
        position.viewportDimension /
        (position.viewportDimension + position.maxScrollExtent);
    return (_trackLength * visibleFraction).clamp(
      math.min(_minThumbLength, _trackLength),
      _trackLength,
    );
  }

  double _thumbStart(ScrollPosition position, double thumbLength) {
    final scrolledFraction = (position.pixels / position.maxScrollExtent).clamp(
      0.0,
      1.0,
    );
    return (_trackLength - thumbLength) * scrolledFraction;
  }

  /// The scroll offset that centers the thumb on [trackOffset].
  double _pixelsCenteredOn(ScrollPosition position, double trackOffset) {
    final thumbLength = _thumbLength(position);
    final travel = _trackLength - thumbLength;
    if (travel <= 0) return position.pixels;
    final fraction = ((trackOffset - thumbLength / 2) / travel).clamp(0.0, 1.0);
    return fraction * position.maxScrollExtent;
  }

  double _alongTrack(Offset localPosition) =>
      _vertical ? localPosition.dy : localPosition.dx;

  // ---------------- Gestures ----------------

  void _setActive(bool active) {
    if (_active != active) setState(() => _active = active);
  }

  void _handleDragStart(DragStartDetails details) {
    final position = _position;
    if (position == null) return;
    final along = _alongTrack(details.localPosition);
    final thumbLength = _thumbLength(position);
    final thumbStart = _thumbStart(position, thumbLength);
    if (along < thumbStart - _grabTolerance ||
        along > thumbStart + thumbLength + _grabTolerance) {
      position.jumpTo(_pixelsCenteredOn(position, along));
    }
    _drag = position.drag(details, () => _drag = null);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final position = _position;
    if (position == null || _drag == null) return;
    final travel = _trackLength - _thumbLength(position);
    if (travel <= 0) return;
    // Thumb pixels → content pixels, negated: a thumb moves the opposite way to content dragged by hand.
    final delta = -details.primaryDelta! * position.maxScrollExtent / travel;
    _drag!.update(
      DragUpdateDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        delta: _vertical ? Offset(0, delta) : Offset(delta, 0),
        primaryDelta: delta,
      ),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    // No fling: the content stops where the thumb was let go.
    _drag?.end(DragEndDetails(primaryVelocity: 0));
    _drag = null;
    _setActive(false);
  }

  void _handleDragCancel() {
    _drag?.cancel();
    _drag = null;
    _setActive(false);
  }

  void _handleTapUp(TapUpDetails details) {
    final position = _position;
    if (position == null) return;
    position.animateTo(
      _pixelsCenteredOn(position, _alongTrack(details.localPosition)),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  // ---------------- Build ----------------

  @override
  void dispose() {
    _drag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      top: _vertical ? widget.startInset : null,
      bottom: _vertical ? widget.endInset : 0,
      left: _vertical ? null : widget.startInset,
      right: _vertical ? 0 : widget.endInset,
      width: _vertical ? widget.touchWidth : null,
      height: _vertical ? null : widget.touchWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _trackLength =
              _vertical ? constraints.maxHeight : constraints.maxWidth;
          return ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final position = _position;
              // Nothing to scroll: no thumb, and touches fall through to the content.
              if (position == null) return const SizedBox.shrink();

              final thumbLength = _thumbLength(position);
              final thumbStart = _thumbStart(position, thumbLength);
              final thickness = _active ? _activeThickness : _thickness;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onTapUp: _handleTapUp,
                onVerticalDragDown: _vertical ? (_) => _setActive(true) : null,
                onVerticalDragStart: _vertical ? _handleDragStart : null,
                onVerticalDragUpdate: _vertical ? _handleDragUpdate : null,
                onVerticalDragEnd: _vertical ? _handleDragEnd : null,
                onVerticalDragCancel: _vertical ? _handleDragCancel : null,
                onHorizontalDragDown:
                    _vertical ? null : (_) => _setActive(true),
                onHorizontalDragStart: _vertical ? null : _handleDragStart,
                onHorizontalDragUpdate: _vertical ? null : _handleDragUpdate,
                onHorizontalDragEnd: _vertical ? null : _handleDragEnd,
                onHorizontalDragCancel: _vertical ? null : _handleDragCancel,
                child: Stack(
                  children: [
                    // Hugs the box's edge, however wide the touch strip around it is.
                    Positioned(
                      top: _vertical ? thumbStart : null,
                      left: _vertical ? null : thumbStart,
                      right: _vertical ? 2 : null,
                      bottom: _vertical ? null : 2,
                      child: AnimatedContainer(
                        key: ValueKey(
                          '${widget.thumbKeyPrefix}-${widget.axis.name}',
                        ),
                        duration: const Duration(milliseconds: 120),
                        width: _vertical ? thickness : thumbLength,
                        height: _vertical ? thumbLength : thickness,
                        decoration: BoxDecoration(
                          color:
                              _active
                                  ? colors.primary
                                  : colors.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  ),
                          borderRadius: BorderRadius.circular(thickness / 2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
