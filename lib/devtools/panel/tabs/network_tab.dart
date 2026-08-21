import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/network_event.dart';
import '../../util/pretty_json.dart';
import '../empty_state.dart';

/// Lists captured HTTP exchanges from `CorextraDevTools.instance.network`.
///
/// Below [_splitBreakpoint] this is a single-column, expandable list (the
/// only way to fit both the list and its detail on a phone). Above it,
/// it switches to a master/detail split — a compact list on the left,
/// the selected request's full detail on the right — the same layout
/// Flutter's own DevTools Network view uses once there's room for it.
class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  static const double _splitBreakpoint = 700;

  NetworkEvent? _selected;

  @override
  Widget build(BuildContext context) {
    final store = CorextraDevTools.instance.network;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final events = store.events.reversed.toList();
        if (events.isEmpty) {
          return const DevToolsEmptyState(
            icon: LucideIcons.network,
            message: 'No requests captured yet',
            hint:
                'Add CorextraDevToolsInterceptor to a Dio instance to see '
                'requests here.',
          );
        }

        // The selected event may have scrolled out of the ring buffer
        // since it was picked; treat that as "nothing selected" rather
        // than pointing the detail pane at stale data.
        final selected = (_selected != null && events.contains(_selected))
            ? _selected
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _splitBreakpoint) {
              return _MasterDetailView(
                events: events,
                selected: selected,
                onSelect: (event) => setState(() => _selected = event),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: events.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) =>
                  _NetworkEventTile(event: events[index]),
            );
          },
        );
      },
    );
  }
}

/// The wide-screen layout: a compact request list on the left, the
/// selected request's full detail on the right.
class _MasterDetailView extends StatelessWidget {
  const _MasterDetailView({
    required this.events,
    required this.selected,
    required this.onSelect,
  });

  final List<NetworkEvent> events;
  final NetworkEvent? selected;
  final ValueChanged<NetworkEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedEvent = selected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Text(
                      'Requests',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${events.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _CompactNetworkRow(
                      event: event,
                      selected: identical(event, selected),
                      onTap: () => onSelect(event),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedEvent == null
              ? const DevToolsEmptyState(
                  icon: LucideIcons.mousePointerClick,
                  message: 'Select a request to see its details',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _NetworkEventDetail(
                    event: selectedEvent,
                    showSummary: true,
                  ),
                ),
        ),
      ],
    );
  }
}

/// A single-line row for the master/detail list: status dot, method
/// pill, path, and a duration/time caption — enough to scan quickly
/// without needing to expand it, since the detail pane already shows
/// everything else.
class _CompactNetworkRow extends StatelessWidget {
  const _CompactNetworkRow({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final NetworkEvent event;
  final bool selected;
  final VoidCallback onTap;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = Uri.tryParse(event.url);
    final path = (uri != null && uri.path.isNotEmpty) ? uri.path : event.url;
    final durationMs = event.duration?.inMilliseconds;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColorFor(event),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              _Pill(
                text: event.method.toUpperCase(),
                color: _methodColor(event.method),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      durationMs != null
                          ? '${durationMs}ms  ·  ${_timeFormat.format(event.startedAt)}'
                          : 'pending…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _methodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return Colors.blue;
    case 'POST':
      return Colors.green;
    case 'PUT':
      return Colors.orange;
    case 'PATCH':
      return Colors.purple;
    case 'DELETE':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

Color _statusColorFor(NetworkEvent event) {
  if (event.isPending) return Colors.grey;
  if (event.isError && event.statusCode == null) return Colors.red;
  final code = event.statusCode ?? 0;
  if (code >= 200 && code < 300) return Colors.green;
  if (code >= 300 && code < 400) return Colors.blue;
  if (code >= 400 && code < 500) return Colors.orange;
  return Colors.red;
}

String _statusLabelFor(NetworkEvent event) {
  if (event.isPending) return '···';
  if (event.isError && event.statusCode == null) return 'ERR';
  return '${event.statusCode}';
}

/// The narrow-screen (phone) row: an expandable tile showing the same
/// detail inline, since there's no room for a separate detail pane.
class _NetworkEventTile extends StatelessWidget {
  const _NetworkEventTile({required this.event});

  final NetworkEvent event;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final uri = Uri.tryParse(event.url);
    final path = (uri != null && uri.path.isNotEmpty) ? uri.path : event.url;
    final query = (uri != null && uri.query.isNotEmpty) ? '?${uri.query}' : '';
    final host = uri?.host ?? '';
    final durationMs = event.duration?.inMilliseconds;
    final statusColor = _statusColorFor(event);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(13, 4, 16, 4),
        title: Row(
          children: [
            _Pill(text: event.method.toUpperCase(), color: _methodColor(event.method)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$path$query',
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                _statusLabelFor(event),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                durationMs != null ? '${durationMs}ms' : 'pending…',
                style: mutedStyle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  host.isNotEmpty
                      ? '$host  ·  ${_timeFormat.format(event.startedAt)}'
                      : _timeFormat.format(event.startedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _NetworkEventDetail(event: event),
          ),
        ],
      ),
    );
  }
}

/// The headers/body detail shared by the phone-sized expandable tile and
/// the wide-screen detail pane.
class _NetworkEventDetail extends StatelessWidget {
  const _NetworkEventDetail({required this.event, this.showSummary = false});

  final NetworkEvent event;

  /// Whether to show a method/URL/status header above the detail —
  /// needed in the master/detail pane, where (unlike the expandable
  /// tile) there's no title row already showing that information.
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummary) ...[
          _DetailSummary(event: event),
          const SizedBox(height: 16),
        ],
        if (event.errorMessage != null) ...[
          _ErrorBanner(message: event.errorMessage!),
          const SizedBox(height: 16),
        ],
        const _GroupHeader(icon: LucideIcons.arrowUpRight, label: 'Request'),
        const SizedBox(height: 8),
        _KeyValueList(data: event.requestHeaders),
        const SizedBox(height: 8),
        _CodeBlock(content: prettyFormatBody(event.requestBody)),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        const _GroupHeader(icon: LucideIcons.arrowDownLeft, label: 'Response'),
        const SizedBox(height: 8),
        _KeyValueList(data: event.responseHeaders),
        const SizedBox(height: 8),
        _CodeBlock(content: prettyFormatBody(event.responseBody)),
      ],
    );
  }
}

/// Method + full URL + status/duration/time — the summary header shown
/// above the detail pane in master/detail mode.
class _DetailSummary extends StatelessWidget {
  const _DetailSummary({required this.event});

  final NetworkEvent event;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColorFor(event);
    final durationMs = event.duration?.inMilliseconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pill(
              text: event.method.toUpperCase(),
              color: _methodColor(event.method),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                event.url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _statusLabelFor(event),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              durationMs != null ? '${durationMs}ms' : 'pending…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
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
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

/// A small "Request" / "Response" group header with a leading icon.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// A clean key/value list, used for headers — instead of a raw
/// `Map.toString()` dump.
class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return Text(
        'No headers',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      entry.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// A monospace "code block" used for request/response bodies, with a
/// one-tap copy button.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
          _CopyIconButton(text: content),
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatefulWidget {
  const _CopyIconButton({required this.text});

  final String text;

  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy),
      onPressed: _copy,
    );
  }
}

/// A small callout banner for connection/network errors.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
