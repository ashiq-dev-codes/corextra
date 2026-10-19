part of 'network_tab.dart';

// ---------------- Detail view ----------------

/// A request's detail for both layouts: a short summary over tabs that each scroll on their own, so a huge response never buries the rest.
class _NetworkEventDetail extends StatefulWidget {
  const _NetworkEventDetail({required this.event});

  final NetworkEvent event;

  @override
  State<_NetworkEventDetail> createState() => _NetworkEventDetailState();
}

/// How far a tab must scroll before swipes fold or restore the summary; big enough to ignore a bounce at the top.
const _summaryCollapseThreshold = 24.0;

class _NetworkEventDetailState extends State<_NetworkEventDetail>
    with SingleTickerProviderStateMixin, FindAware<_NetworkEventDetail> {
  bool _summaryCollapsed = false;
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  void onFindReveal(FindHit hit) {
    final meta = hit.target.meta;
    if (meta is! _NetworkFindMeta || meta.eventId != widget.event.id) return;
    final tab = meta.section.detailTab;
    // Instant, so the match isn't scrolled into view on a page that's still sliding in.
    if (tab != null && tab != _tabs.index) _tabs.index = tab;
  }

  void _handleTabScroll(double offset, ScrollDirection direction) {
    final collapse =
        offset > _summaryCollapseThreshold &&
        direction == ScrollDirection.reverse;
    final expand =
        offset <= _summaryCollapseThreshold ||
        direction == ScrollDirection.forward;
    if (collapse && !_summaryCollapsed) {
      setState(() => _summaryCollapsed = true);
    } else if (expand && _summaryCollapsed) {
      setState(() => _summaryCollapsed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              _summaryCollapsed
                  ? Padding(
                    key: const ValueKey('compact-summary'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _DetailSummary(event: event, compact: true),
                  )
                  : Padding(
                    key: const ValueKey('full-summary'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _DetailSummary(event: event),
                  ),
        ),
        Expanded(
          child: Column(
            children: [
              const Divider(height: 1),
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: event.isSocket ? 'General' : 'Headers'),
                  const Tab(text: 'Payload'),
                  const Tab(text: 'Response'),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _HeadersTab(event: event, onScroll: _handleTabScroll),
                    _PayloadTab(event: event, onScroll: _handleTabScroll),
                    _ResponseTab(event: event, onScroll: _handleTabScroll),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Detail tabs ----------------

/// The full URL, any error and the headers; the URL and error live here, not in the summary, because either can run long.
class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.event, this.onScroll});

  final NetworkEvent event;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return DevToolsScrollToTop(
      onScroll: onScroll,
      builder:
          (context, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SubsectionLabel('URL'),
                const SizedBox(height: 4),
                FindText(
                  event.url,
                  id: '${_findPrefix(event, _Section.url)}/text',
                  selectable: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                  ),
                ),
                if (event.errorMessage != null) ...[
                  const SizedBox(height: 20),
                  const _SubsectionLabel('ERROR'),
                  const SizedBox(height: 4),
                  _ErrorBanner(
                    message: event.errorMessage!,
                    findId: '${_findPrefix(event, _Section.error)}/text',
                  ),
                ],
                if (!event.isSocket) ...[
                  const SizedBox(height: 20),
                  const _SubsectionLabel('REQUEST HEADERS'),
                  const SizedBox(height: 4),
                  _KeyValueList(
                    data: event.requestHeaders,
                    hiddenKeys: event.hiddenHeaderKeys,
                    findPrefix: _findPrefix(event, _Section.requestHeaders),
                  ),
                  const SizedBox(height: 20),
                  const _SubsectionLabel('RESPONSE HEADERS'),
                  const SizedBox(height: 4),
                  _KeyValueList(
                    data: event.responseHeaders,
                    hiddenKeys: event.hiddenHeaderKeys,
                    findPrefix: _findPrefix(event, _Section.responseHeaders),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}

/// The query parameters and request body: everything sent to the server.
class _PayloadTab extends StatelessWidget {
  const _PayloadTab({required this.event, this.onScroll});

  final NetworkEvent event;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = _maxBodyHeight(constraints);
        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.queryParameters.isNotEmpty) ...[
                const _SubsectionLabel('QUERY PARAMETERS'),
                const SizedBox(height: 4),
                _BodyView(
                  event: event,
                  section: _Section.query,
                  title: 'Query Parameters',
                  maxHeight: maxHeight,
                  onScroll: onScroll,
                ),
                const SizedBox(height: 20),
              ],
              const _SubsectionLabel('REQUEST BODY'),
              const SizedBox(height: 4),
              _BodyView(
                event: event,
                section: _Section.requestBody,
                title: 'Request Body',
                maxHeight: maxHeight,
                onScroll: onScroll,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The response body in its own tab, since it's the part most likely to be large.
class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.event, this.onScroll});

  final NetworkEvent event;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.all(16),
            child: _BodyView(
              event: event,
              section: _Section.responseBody,
              title: 'Response',
              maxHeight: _maxBodyHeight(constraints),
              onScroll: onScroll,
            ),
          ),
    );
  }
}

/// Fills the tab so a large body scrolls inside its block with its toolbar and scrollbars in view; never below a usable height in a tiny window.
double _maxBodyHeight(BoxConstraints constraints) =>
    math.max(constraints.maxHeight - 32, 200);

// ---------------- Summary and labels ----------------

/// Method, path, status, duration and time; the path is cut to one line so this never needs a second scrollbar above the tabs.
class _DetailSummary extends StatelessWidget {
  const _DetailSummary({required this.event, this.compact = false});

  final NetworkEvent event;

  /// Shows a one-line strip instead, while the detail view has folded the summary to make room for the tab.
  final bool compact;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColorFor(event);
    final durationMs = event.duration?.inMilliseconds;
    final path = _displayPath(event);
    final statusId = '${_findPrefix(event, _Section.status)}/label';

    if (compact) {
      return Row(
        children: [
          _Pill(
            text: event.method.toUpperCase(),
            color: _methodColor(event.method),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FindText(
              path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FindText(
            _statusLabelFor(event),
            id: statusId,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Pill(
              text: event.method.toUpperCase(),
              color: _methodColor(event.method),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FindText(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            FindText(
              _statusLabelFor(event),
              id: statusId,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            FindText(
              durationMs != null ? '${durationMs}ms' : 'pending…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            FindText(
              _timeFormat.format(event.startedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small colored pill, used for the HTTP method badge.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.findId});

  final String text;
  final Color color;
  final String? findId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: FindText(
        text,
        id: findId,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// A small muted heading for a part of a tab, like "REQUEST BODY".
class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FindText(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
