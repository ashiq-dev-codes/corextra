import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import 'edge_scrollbar.dart';

/// A small floating "scroll to top" button overlaid on a scrollable built by [builder].
class DevToolsScrollToTop extends StatefulWidget {
  const DevToolsScrollToTop({
    super.key,
    required this.builder,
    this.onScroll,
    this.scrollbar = false,
  });

  /// Must attach the given [ScrollController] to its scrollable.
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  /// Called on every scroll update with the live offset and the user's scroll direction — e.g. so a parent can collapse a header while scrolling down and restore it near the top.
  final void Function(double offset, ScrollDirection direction)? onScroll;

  /// Adds an easy-to-grab scrollbar along the right edge, for long lists where flicking alone is slow.
  final bool scrollbar;

  @override
  State<DevToolsScrollToTop> createState() => _DevToolsScrollToTopState();
}

class _DevToolsScrollToTopState extends State<DevToolsScrollToTop> {
  static const double _showAfterOffset = 300;

  final ScrollController _controller = ScrollController();

  // Unique per instance so simultaneously-mounted FABs never collide on the default hero tag.
  final Object _heroTag = Object();

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    final shouldShow = offset > _showAfterOffset;
    if (shouldShow != _visible) setState(() => _visible = shouldShow);
    widget.onScroll?.call(offset, _controller.position.userScrollDirection);
  }

  void _scrollToTop() {
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.scrollbar)
          // The list's length changes as data arrives; resize the thumb to match.
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              setState(() {});
              return false;
            },
            child: widget.builder(context, _controller),
          )
        else
          widget.builder(context, _controller),
        if (widget.scrollbar)
          // Stops above the scroll-to-top button, so the two never overlap.
          DevToolsEdgeScrollbar(
            controller: _controller,
            axis: Axis.vertical,
            endInset: 60,
            touchWidth: 24,
            thumbKeyPrefix: 'list-scrollbar-thumb',
          ),
        Positioned(
          right: 12,
          bottom: 12,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _visible ? Offset.zero : const Offset(0, 1.5),
            child: AnimatedOpacity(
              key: const Key('devtools-scroll-to-top-opacity'),
              duration: const Duration(milliseconds: 200),
              opacity: _visible ? 1 : 0,
              child: IgnorePointer(
                key: const Key('devtools-scroll-to-top-ignore-pointer'),
                ignoring: !_visible,
                child: FloatingActionButton.small(
                  heroTag: _heroTag,
                  tooltip: 'Scroll to top',
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.arrow_upward),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
