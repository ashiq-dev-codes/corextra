import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/network_event.dart';
import '../../util/pretty_json.dart';
import '../empty_state.dart';

/// Lists captured HTTP exchanges from
/// `CorextraDevTools.instance.network`.
class NetworkTab extends StatelessWidget {
  const NetworkTab({super.key});

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
        return ListView.separated(
          itemCount: events.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _NetworkEventTile(event: events[index]),
        );
      },
    );
  }
}

class _NetworkEventTile extends StatelessWidget {
  const _NetworkEventTile({required this.event});

  final NetworkEvent event;

  static final _timeFormat = DateFormat('HH:mm:ss');

  Color _statusColor() {
    if (event.isError) return Colors.red;
    if (event.isPending) return Colors.grey;
    final code = event.statusCode ?? 0;
    if (code >= 200 && code < 300) return Colors.green;
    if (code >= 300 && code < 400) return Colors.blue;
    return Colors.orange;
  }

  String _statusLabel() {
    if (event.isError) return event.statusCode?.toString() ?? 'ERR';
    return '${event.statusCode}';
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = event.duration?.inMilliseconds;
    return ExpansionTile(
      leading: event.isPending
          ? const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : CircleAvatar(
              radius: 14,
              backgroundColor: _statusColor(),
              child: Text(
                _statusLabel(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            ),
      title: Text(
        '${event.method}  ${event.url}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      subtitle: Text(
        '${_timeFormat.format(event.startedAt)}'
        '${durationMs != null ? ' · ${durationMs}ms' : ' · pending…'}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Request headers'),
              Text(
                event.requestHeaders.isEmpty
                    ? 'none'
                    : event.requestHeaders.toString(),
              ),
              const SizedBox(height: 8),
              const _SectionLabel('Request body'),
              Text(prettyFormatBody(event.requestBody)),
              const SizedBox(height: 8),
              const _SectionLabel('Response headers'),
              Text(
                event.responseHeaders.isEmpty
                    ? 'none'
                    : event.responseHeaders.toString(),
              ),
              const SizedBox(height: 8),
              const _SectionLabel('Response body'),
              Text(prettyFormatBody(event.responseBody)),
              if (event.errorMessage != null) ...[
                const SizedBox(height: 8),
                const _SectionLabel('Error'),
                Text(
                  event.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    );
  }
}
