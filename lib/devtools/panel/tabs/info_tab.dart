import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../find/devtools_find.dart';
import '../../find/find_text.dart';
import '../../util/platform_services.dart';
import '../live_builder.dart';
import '../scroll_to_top_fab.dart';

/// App + device details, plus current capture-buffer counts from `CorextraDevTools.instance`.
class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  static final FindSource findSource = FindSource(
    changes: _changes,
    targets: () sync* {
      for (final item in _items(_ensureAppInfo())) {
        yield FindTarget('${item.id}/label', item.label);
        if (item.value != null) {
          yield FindTarget('${item.id}/value', item.value!);
        }
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    _ensureAppInfo();
    return DevToolsLiveBuilder(
      listenable: _changes,
      builder: (context) {
        return DevToolsScrollToTop(
          builder:
              (context, controller) => SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in _items(_appInfo.value))
                      item.icon != null
                          ? _SectionHeader(item)
                          : _InfoRowView(item),
                  ],
                ),
              ),
        );
      },
    );
  }
}

// Shared, so find can search app info before the Info tab is ever opened.
final _appInfo = ValueNotifier<Map<String, String>?>(null);
var _appInfoRequested = false;

Map<String, String>? _ensureAppInfo() {
  if (!_appInfoRequested) {
    _appInfoRequested = true;
    loadAppInfo().then(
      (info) => _appInfo.value = info,
      onError: (_) => _appInfo.value = const {},
    );
  }
  return _appInfo.value;
}

final _changes = Listenable.merge([
  _appInfo,
  CorextraDevTools.instance.network,
  CorextraDevTools.instance.logs,
]);

/// A section header (with [icon]) or a label/value row — one list drives both the screen and find, so they can't drift apart.
class _InfoItem {
  const _InfoItem.header(this.label, IconData this.icon) : value = null;

  const _InfoItem.row(this.label, String this.value) : icon = null;

  final String label;
  final String? value;
  final IconData? icon;

  String get id => 'info/$label';
}

/// [app] is null while it's still loading — the capture buffers don't wait for it.
Iterable<_InfoItem> _items(Map<String, String>? app) sync* {
  final devtools = CorextraDevTools.instance;
  yield const _InfoItem.header('App', LucideIcons.layoutGrid);
  for (final entry in app?.entries ?? const <MapEntry<String, String>>[]) {
    yield _InfoItem.row(entry.key, entry.value);
  }
  yield const _InfoItem.header('Capture buffers', LucideIcons.database);
  yield _InfoItem.row('Network events', '${devtools.network.events.length}');
  yield _InfoItem.row('Log entries', '${devtools.logs.entries.length}');
}

class _InfoRowView extends StatelessWidget {
  const _InfoRowView(this.item);

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: FindText(
              item.label,
              id: '${item.id}/label',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: FindText(item.value!, id: '${item.id}/value')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.item);

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The divider that used to sit between sections, now part of every header but the first.
    final first = item.label == 'App';
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!first) ...[const Divider(height: 1), const SizedBox(height: 16)],
          Row(
            children: [
              Icon(item.icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              FindText(
                item.label,
                id: '${item.id}/label',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
