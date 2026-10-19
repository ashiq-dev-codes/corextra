part of 'network_tab.dart';

// ---------------- Code metrics ----------------

const _codeStyle = TextStyle(fontFamily: 'monospace', fontSize: 12.5);

/// A code line's height and a character's width at the current text scale, measured so lines get exact heights up front.
({double charWidth, double lineHeight}) _codeMetrics(TextScaler scaler) {
  final painter = TextPainter(
    text: const TextSpan(text: '0000000000', style: _codeStyle),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final metrics = (charWidth: painter.width / 10, lineHeight: painter.height);
  painter.dispose();
  return metrics;
}

// ---------------- Code view ----------------

/// A monospace code block that builds only the lines on screen, so even a huge body opens instantly and costs nothing while the app keeps capturing.
class _CodeView extends StatefulWidget {
  const _CodeView({
    required this.body,
    required this.title,
    required this.findPrefix,
    this.standalone = true,
    this.onScroll,
  });

  final _Body body;
  final String title;

  /// Each line's find id is this plus its index, matching the lines the find source lists.
  final String findPrefix;

  /// False for the copy shown in the fullscreen view, so it doesn't offer another fullscreen view on top of itself.
  final bool standalone;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  State<_CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<_CodeView> with FindAware<_CodeView> {
  final Set<String> _collapsedPaths = {};
  List<int>? _visible;
  ScrollController? _vertical;
  var _metrics = (charWidth: 7.5, lineHeight: 15.0);

  List<_CodeLine> get _lines => widget.body.lines;

  @override
  void didUpdateWidget(_CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.body, widget.body)) _visible = null;
  }

  /// Indices of the lines not folded away, in order.
  List<int> get _visibleLines =>
      _visible ??= () {
        final out = <int>[];
        for (var i = 0; i < _lines.length; i++) {
          out.add(i);
          final line = _lines[i];
          // Folded: its children and closing line are skipped; the toggle line shows them inline.
          if (line.isOpen && _collapsedPaths.contains(line.path)) {
            i = line.closeIndex!;
          }
        }
        return out;
      }();

  double _extentOf(_CodeLine line) {
    final text = _metrics.lineHeight;
    if (line.isOpen) return math.max(34, text + 4);
    return line.plain ? text + 4 : text + 10;
  }

  void _setCollapsed(void Function(Set<String> paths) change) {
    setState(() {
      change(_collapsedPaths);
      _visible = null;
    });
  }

  void _toggle(String path) => _setCollapsed((paths) {
    if (!paths.add(path)) paths.remove(path);
  });

  void _expandAll() => _setCollapsed((paths) => paths.clear());

  void _collapseAll() => _setCollapsed(
    (paths) =>
        paths
          ..clear()
          ..addAll([
            for (final line in _lines)
              if (line.isOpen) line.path,
          ]),
  );

  /// Unfolds whatever hides the current match, then scrolls its line into the built range so its [FindText] can show the exact words.
  @override
  void onFindReveal(FindHit hit) {
    final prefix = '${widget.findPrefix}/';
    if (!hit.target.id.startsWith(prefix)) return;
    final index = int.tryParse(hit.target.id.substring(prefix.length));
    if (index == null || index >= _lines.length) return;
    final hiding = [
      for (var i = 0; i < index; i++)
        if (_lines[i].isOpen &&
            index <= _lines[i].closeIndex! &&
            _collapsedPaths.contains(_lines[i].path))
          _lines[i].path,
    ];
    if (hiding.isNotEmpty) _setCollapsed((paths) => paths.removeAll(hiding));
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollTo(index));
  }

  void _scrollTo(int lineIndex) {
    final vertical = _vertical;
    if (!mounted || vertical == null || !vertical.hasClients) return;
    final rows = _visibleLines;
    final row = rows.indexOf(lineIndex);
    if (row < 0) return;
    var offset = _codeTopPadding;
    for (var i = 0; i < row; i++) {
      offset += _extentOf(_lines[rows[i]]);
    }
    final position = vertical.position;
    position.jumpTo(
      (offset - position.viewportDimension / 3).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _metrics = _codeMetrics(MediaQuery.textScalerOf(context));
    final rows = _visibleLines;
    var height = _codeTopPadding + _codeBottomPadding;
    for (final row in rows) {
      height += _extentOf(_lines[row]);
    }
    return _CodeBlockChrome(
      copyText: widget.body.copyText,
      title: widget.title,
      fullscreenBuilder:
          widget.standalone
              ? (context) => _CodeView(
                body: widget.body,
                title: widget.title,
                findPrefix: widget.findPrefix,
                standalone: false,
              )
              : null,
      actions: [
        if (widget.body.isJson) ...[
          IconButton(
            tooltip: 'Expand all',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.chevronsUpDown),
            onPressed: _expandAll,
          ),
          IconButton(
            tooltip: 'Collapse all',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.chevronsDownUp),
            onPressed: _collapseAll,
          ),
        ],
      ],
      child: _ScrollableCode(
        onScroll: widget.onScroll,
        onVerticalController: (controller) => _vertical = controller,
        height: height,
        contentWidth: widget.body.contentWidth(_metrics.charWidth),
        itemCount: rows.length,
        itemExtent: (row) => _extentOf(_lines[rows[row]]),
        itemBuilder: (context, row) {
          final index = rows[row];
          final line = _lines[index];
          final findId = '${widget.findPrefix}/$index';
          return line.isOpen
              ? _CodeToggleLine(
                line: line,
                collapsed: _collapsedPaths.contains(line.path),
                findId: findId,
                theme: theme,
                onTap: () => _toggle(line.path),
              )
              : _CodeLeafLine(line: line, findId: findId, theme: theme);
        },
      ),
    );
  }
}

const _codeTopPadding = 8.0;
const _codeBottomPadding = 16.0;

// ---------------- Code block frame ----------------

/// The box and buttons around a [_CodeView]; the buttons float in the top-right corner while content scrolls, instead of narrowing every line.
class _CodeBlockChrome extends StatelessWidget {
  const _CodeBlockChrome({
    required this.child,
    required this.copyText,
    required this.title,
    this.actions = const [],
    this.fullscreenBuilder,
  });

  final Widget child;
  final ValueGetter<String> copyText;
  final String title;
  final List<Widget> actions;

  /// Builds a separate copy for the fullscreen view, not [child] itself, so folding JSON there doesn't upset the inline view's state.
  final WidgetBuilder? fullscreenBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 4,
            right: 4,
            child: _CodeBlockActionBar(
              actions: [
                ...actions,
                if (fullscreenBuilder != null)
                  _FullscreenIconButton(
                    title: title,
                    builder: fullscreenBuilder!,
                  ),
                _ShareIconButton(text: copyText),
                _CopyIconButton(text: copyText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small floating pill of icon buttons, opaque so it stays readable over the code scrolling under it.
class _CodeBlockActionBar extends StatelessWidget {
  const _CodeBlockActionBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
    );
  }
}

// ---------------- Fullscreen ----------------

/// Opens [builder]'s content full screen through the ambient [Overlay], not [Navigator], since the panel may have no Navigator above it.
class _FullscreenIconButton extends StatefulWidget {
  const _FullscreenIconButton({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  State<_FullscreenIconButton> createState() => _FullscreenIconButtonState();
}

class _FullscreenIconButtonState extends State<_FullscreenIconButton> {
  OverlayEntry? _entry;

  void _open() {
    final entry = OverlayEntry(
      builder:
          (context) => _FullscreenContentView(
            title: widget.title,
            onClose: _close,
            child: widget.builder(context),
          ),
    );
    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'View fullscreen',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: const Icon(LucideIcons.maximize2),
      onPressed: _open,
    );
  }
}

/// The fullscreen frame: a back button and title over [child], which gets the whole screen instead of sharing it with the tab bar.
class _FullscreenContentView extends StatelessWidget {
  const _FullscreenContentView({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BackHandlerScope(
      onBack: onClose,
      child: Positioned.fill(
        child: Material(
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: onClose,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // The block scrolls itself, so here it just gets the whole screen as its limit.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(alignment: Alignment.topCenter, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Scrolling ----------------

/// Scrolls the code both ways inside its box, with draggable scrollbars pinned to the box's edges so neither ends up below the fold.
class _ScrollableCode extends StatefulWidget {
  const _ScrollableCode({
    required this.height,
    required this.contentWidth,
    required this.itemCount,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onVerticalController,
    this.onScroll,
  });

  /// The natural height of every line; the block shrinks to it when that's less than its limit.
  final double height;
  final double contentWidth;
  final int itemCount;
  final double Function(int index) itemExtent;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<ScrollController> onVerticalController;

  /// Reports vertical scrolling, e.g. so the detail view can collapse its summary.
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  State<_ScrollableCode> createState() => _ScrollableCodeState();
}

class _ScrollableCodeState extends State<_ScrollableCode> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Its own scroll-to-top button, sitting inside the box clear of both scrollbars.
    return DevToolsScrollToTop(
      onScroll: widget.onScroll,
      builder: (context, vertical) {
        widget.onVerticalController(vertical);
        return NotificationListener<ScrollMetricsNotification>(
          // Content or box size changed, e.g. a JSON node folded, so resize the thumbs to match.
          onNotification: (_) {
            setState(() {});
            return false;
          },
          child: SizedBox(
            height: widget.height,
            child: Stack(
              key: const ValueKey('code-block-scroll-area'),
              children: [
                LayoutBuilder(
                  builder:
                      (context, box) => SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 10, right: 16),
                        child: SizedBox(
                          width: math.max(
                            widget.contentWidth,
                            box.maxWidth - 26,
                          ),
                          // Lines are built only while on screen, each at a known height, so a huge body costs no more than a small one.
                          child: ListView.builder(
                            controller: vertical,
                            padding: const EdgeInsets.only(
                              top: _codeTopPadding,
                              bottom: _codeBottomPadding,
                            ),
                            itemCount: widget.itemCount,
                            itemExtentBuilder:
                                (index, _) =>
                                    index < widget.itemCount
                                        ? widget.itemExtent(index)
                                        : null,
                            itemBuilder:
                                (context, index) => OverflowBox(
                                  alignment: Alignment.centerLeft,
                                  maxWidth: double.infinity,
                                  // Never wraps: a line wider than the estimate just runs on, like an editor.
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: widget.itemBuilder(context, index),
                                  ),
                                ),
                          ),
                        ),
                      ),
                ),
                // Starts below the floating action bar, so the bar never covers the thumb.
                DevToolsEdgeScrollbar(
                  controller: vertical,
                  axis: Axis.vertical,
                  startInset: 48,
                  endInset: 16,
                  thumbKeyPrefix: 'code-scrollbar-thumb',
                ),
                DevToolsEdgeScrollbar(
                  controller: _horizontal,
                  axis: Axis.horizontal,
                  endInset: 16,
                  thumbKeyPrefix: 'code-scrollbar-thumb',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
