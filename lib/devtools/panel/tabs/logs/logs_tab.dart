import 'package:corextra/logs/enum/log_level.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../corextra_devtools.dart';
import '../../../find/find.dart';
import '../../../models/log_entry.dart';
import '../../widgets/devtools_empty_state.dart';
import '../../widgets/devtools_live_builder.dart';
import '../../widgets/devtools_scroll_to_top.dart';

// ---------------- Constants ----------------

// Shared by the screen and its find targets, so find always matches what's shown.
const _emptyMessage = 'No logs captured yet';
const _emptyHint = 'Call debugLog() or AppLogger to see entries here.';
final _timeFormat = DateFormat('HH:mm:ss.SSS');

// ---------------- Logs tab ----------------

/// The Logs tab: every captured log line, newest first, color-coded and filterable by level.
///
/// `DevToolsPanel` already shows it; use it on its own to show your app's logs in your own screen.
///
/// Example:
/// ```dart
/// // A logs screen for testers, fed by debugLog() and AppLogger
/// Scaffold(
///   appBar: AppBar(title: const Text('Logs')),
///   body: const LogsTab(),
/// )
/// ```
class LogsTab extends StatefulWidget {
  /// Creates the Logs tab with every level shown.
  const LogsTab({super.key});

  // ---------------- Find ----------------

  /// Every text this tab shows, in on-screen order, for the panel's find bar.
  static final FindSource findSource = FindSource(
    changes: CorextraDevTools.instance.logs,
    targets: _findTargets,
  );

  static Iterable<FindTarget> _findTargets() sync* {
    final entries = CorextraDevTools.instance.logs.entries;
    if (entries.isEmpty) {
      yield const FindTarget('logs/empty/message', _emptyMessage);
      yield const FindTarget('logs/empty/hint', _emptyHint);
      return;
    }
    for (final entry in entries.reversed) {
      final id = _findId(entry);
      yield FindTarget('$id/message', entry.message, entry);
      yield FindTarget('$id/time', _timeFormat.format(entry.timestamp), entry);
    }
  }

  @override
  State<LogsTab> createState() => _LogsTabState();
}

// ---------------- Private helpers ----------------

// An Expando gives each entry a stable find id without adding a field to the public LogEntry.
final _entryIds = Expando<int>();
var _nextEntryId = 0;

String _findId(LogEntry entry) => 'log/${_entryIds[entry] ??= _nextEntryId++}';

// ---------------- State ----------------

class _LogsTabState extends State<LogsTab> with FindAware<LogsTab> {
  final Set<LogLevel> _activeLevels = Set.of(LogLevel.values);

  // ---------------- Find ----------------

  /// Like a browser expanding a collapsed section: a match is never left hidden behind a level filter.
  @override
  void onFindReveal(FindHit hit) {
    final entry = hit.target.meta;
    if (entry is LogEntry && !_activeLevels.contains(entry.level)) {
      setState(() => _activeLevels.add(entry.level));
    }
  }

  // ---------------- Levels ----------------

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

  void _toggleLevel(LogLevel level, bool active) {
    setState(() {
      if (active) {
        _activeLevels.add(level);
      } else {
        _activeLevels.remove(level);
      }
    });
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CorextraDevTools.instance.logs;
    return DevToolsLiveBuilder(
      listenable: store,
      builder: (context) {
        final entries = store.entries.reversed.toList();
        if (entries.isEmpty) {
          return const DevToolsEmptyState(
            icon: LucideIcons.fileText,
            message: _emptyMessage,
            hint: _emptyHint,
            findId: 'logs/empty',
          );
        }

        final filtered =
            entries.where((e) => _activeLevels.contains(e.level)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Wrap(
                spacing: 6,
                children:
                    LogLevel.values.map((level) {
                      final color = _colorFor(level);
                      final active = _activeLevels.contains(level);
                      return FilterChip(
                        label: FindText(_labelFor(level)),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color:
                              active
                                  ? color
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                        avatar: Icon(_iconFor(level), size: 14, color: color),
                        selected: active,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        selectedColor: color.withValues(alpha: 0.15),
                        side: BorderSide(
                          color:
                              active
                                  ? color.withValues(alpha: 0.4)
                                  : theme.colorScheme.outlineVariant,
                        ),
                        onSelected: (value) => _toggleLevel(level, value),
                      );
                    }).toList(),
              ),
            ),
            Expanded(
              child:
                  filtered.isEmpty
                      ? const DevToolsEmptyState(
                        icon: LucideIcons.searchX,
                        message: 'No logs match the selected levels',
                      )
                      : DevToolsScrollToTop(
                        scrollbar: true,
                        builder:
                            (context, controller) => FindListView(
                              controller: controller,
                              itemCount: filtered.length,
                              itemKey: (index) => filtered[index],
                              indexOfHit: (hit) {
                                final entry = hit.target.meta;
                                return entry is LogEntry
                                    ? filtered.indexOf(entry)
                                    : null;
                              },
                              separatorBuilder:
                                  (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                final color = _colorFor(entry.level);
                                final id = _findId(entry);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _iconFor(entry.level),
                                        size: 16,
                                        color: color,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FindText(
                                              entry.message,
                                              id: '$id/message',
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12.5,
                                                color: color,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            FindText(
                                              _timeFormat.format(
                                                entry.timestamp,
                                              ),
                                              id: '$id/time',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme
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
            ),
          ],
        );
      },
    );
  }
}
