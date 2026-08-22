import 'package:flutter/material.dart';

/// A small floating "scroll to top" button overlaid on a scrollable built by [builder].
class DevToolsScrollToTop extends StatefulWidget {
  const DevToolsScrollToTop({super.key, required this.builder});

  /// Must attach the given [ScrollController] to its scrollable.
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

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
    final shouldShow =
        _controller.hasClients && _controller.offset > _showAfterOffset;
    if (shouldShow != _visible) setState(() => _visible = shouldShow);
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
        widget.builder(context, _controller),
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
