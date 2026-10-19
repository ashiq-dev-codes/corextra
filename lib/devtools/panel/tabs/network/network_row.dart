part of 'network_tab.dart';

// ---------------- Row ----------------

/// One request in the list; the path wraps up to 3 lines because one cut-off line often hides the part that tells requests apart.
class _CompactNetworkRow extends StatelessWidget {
  const _CompactNetworkRow({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final NetworkEvent event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = _findPrefix(event, _Section.row);

    return Material(
      color:
          selected
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
                findId: '$prefix/method',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FindText(
                      _displayPath(event),
                      id: '$prefix/path',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FindText(
                      _rowCaption(event),
                      id: '$prefix/caption',
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

// ---------------- Row text and colors ----------------

final _rowTimeFormat = DateFormat('HH:mm:ss');

/// The duration and start time under a row's path, or "pending…" while it's in flight.
String _rowCaption(NetworkEvent event) {
  final durationMs = event.duration?.inMilliseconds;
  return durationMs != null
      ? '${durationMs}ms  ·  ${_rowTimeFormat.format(event.startedAt)}'
      : 'pending…';
}

/// The path for HTTP, or the event name for a socket message, since a name like `chat:open` would parse as a URL scheme.
String _displayPath(NetworkEvent event) {
  if (event.isSocket) return event.socketEvent!;
  final uri = Uri.tryParse(event.url);
  return (uri != null && uri.path.isNotEmpty) ? uri.path : event.url;
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
    case 'EMIT':
    case 'SOCKET':
      return Colors.teal;
    case 'ON':
      return Colors.indigo;
    default:
      return Colors.blueGrey;
  }
}

Color _statusColorFor(NetworkEvent event) {
  if (event.isPending) return Colors.grey;
  if (event.isError && event.statusCode == null) return Colors.red;
  if (event.isSocket) return Colors.green;
  final code = event.statusCode ?? 0;
  if (code >= 200 && code < 300) return Colors.green;
  if (code >= 300 && code < 400) return Colors.blue;
  if (code >= 400 && code < 500) return Colors.orange;
  return Colors.red;
}

String _statusLabelFor(NetworkEvent event) {
  if (event.isPending) return '···';
  if (event.isError && event.statusCode == null) return 'ERR';
  if (event.isSocket) return 'OK';
  return '${event.statusCode}';
}
