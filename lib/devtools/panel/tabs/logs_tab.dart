import 'package:corextra/logs/enum/log_level.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../empty_state.dart';

/// Reverse-chronological, color-coded list of captured log entries from
/// `CorextraDevTools.instance.logs`.
class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  static final _timeFormat = DateFormat('HH:mm:ss.SSS');

  Color _colorFor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blueGrey;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData _iconFor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return LucideIcons.info;
      case LogLevel.warning:
        return LucideIcons.triangleAlert;
      case LogLevel.error:
        return LucideIcons.circleAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CorextraDevTools.instance.logs;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final entries = store.entries.reversed.toList();
        if (entries.isEmpty) {
          return const DevToolsEmptyState(
            icon: LucideIcons.fileText,
            message: 'No logs captured yet',
            hint: 'Call debugLog() or AppLogger to see entries here.',
          );
        }
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final color = _colorFor(entry.level);
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(entry.level), size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.message,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeFormat.format(entry.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
