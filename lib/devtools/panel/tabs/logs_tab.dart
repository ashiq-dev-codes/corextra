import 'package:corextra/logs/enum/log_level.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/log_entry.dart';
import '../empty_state.dart';
import '../search_field.dart';

/// Reverse-chronological, color-coded list of captured log entries from
/// `CorextraDevTools.instance.logs` — filterable by message text and by
/// level.
class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<LogLevel> _activeLevels = Set.of(LogLevel.values);

  static final _timeFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _labelFor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }

  bool _matches(LogEntry entry, String query) {
    if (!_activeLevels.contains(entry.level)) return false;
    if (query.isEmpty) return true;
    return entry.message.toLowerCase().contains(query);
  }

  void _toggleLevel(LogLevel level, bool active) {
    setState(() {
      if (active) {
        _activeLevels.add(level);
      } else {
        _activeLevels.remove(level);
      }
    });
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

        final query = _query.trim().toLowerCase();
        final filtered = entries.where((e) => _matches(e, query)).toList();

        return Column(
          children: [
            DevToolsSearchField(
              controller: _searchController,
              hintText: 'Search log messages',
              onChanged: (value) => setState(() => _query = value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 6,
                children: LogLevel.values.map((level) {
                  final color = _colorFor(level);
                  final active = _activeLevels.contains(level);
                  return FilterChip(
                    label: Text(_labelFor(level)),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: active ? color : theme.colorScheme.onSurfaceVariant,
                    ),
                    avatar: Icon(_iconFor(level), size: 14, color: color),
                    selected: active,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selectedColor: color.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: active ? color.withValues(alpha: 0.4) : theme.colorScheme.outlineVariant,
                    ),
                    onSelected: (value) => _toggleLevel(level, value),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? DevToolsEmptyState(
                      icon: LucideIcons.searchX,
                      message: query.isEmpty
                          ? 'No logs match the selected levels'
                          : 'No logs match "${_query.trim()}"',
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        final color = _colorFor(entry.level);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconFor(entry.level),
                                size: 16,
                                color: color,
                              ),
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
