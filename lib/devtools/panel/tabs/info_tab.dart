import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../util/platform_services.dart';
import '../scroll_to_top_fab.dart';

/// App + device details, plus current capture-buffer counts from `CorextraDevTools.instance`.
class InfoTab extends StatefulWidget {
  const InfoTab({super.key});

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  late final Future<Map<String, String>> _future = loadAppInfo();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final devtools = CorextraDevTools.instance;
        return DevToolsScrollToTop(
          builder:
              (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionHeader('App', icon: LucideIcons.layoutGrid),
                  for (final entry in data.entries)
                    _row(entry.key, entry.value),
                  const Divider(height: 32),
                  const _SectionHeader(
                    'Capture buffers',
                    icon: LucideIcons.database,
                  ),
                  _row('Network events', '${devtools.network.events.length}'),
                  _row('Log entries', '${devtools.logs.entries.length}'),
                  _row(
                    'Frame samples',
                    '${devtools.performance.samples.length}',
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
