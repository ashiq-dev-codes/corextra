import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../devtools_controller.dart';
import '../scroll_to_top_fab.dart';

/// App + device details, plus current capture-buffer counts, sourced
/// from `package_info_plus`/`device_info_plus` and
/// `CorextraDevTools.instance`.
class InfoTab extends StatefulWidget {
  const InfoTab({super.key});

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  late final Future<_InfoData> _future = _load();

  Future<_InfoData> _load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceLabel = await _deviceLabel();
    return _InfoData(packageInfo: packageInfo, deviceLabel: deviceLabel);
  }

  Future<String> _deviceLabel() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        return '${info.browserName.name} on ${info.platform ?? 'web'}';
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          return '${info.manufacturer} ${info.model} '
              '(Android ${info.version.release})';
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          return '${info.name} (${info.systemName} ${info.systemVersion})';
        case TargetPlatform.macOS:
          final info = await plugin.macOsInfo;
          return '${info.model} (macOS ${info.osRelease})';
        case TargetPlatform.windows:
          final info = await plugin.windowsInfo;
          return info.productName;
        case TargetPlatform.linux:
          final info = await plugin.linuxInfo;
          return info.prettyName;
        case TargetPlatform.fuchsia:
          return 'Fuchsia device';
      }
    } catch (_) {
      return 'Unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InfoData>(
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
                  _row('App name', data.packageInfo.appName),
                  _row('Package', data.packageInfo.packageName),
                  _row(
                    'Version',
                    '${data.packageInfo.version} (${data.packageInfo.buildNumber})',
                  ),
                  _row('Device', data.deviceLabel),
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

class _InfoData {
  const _InfoData({required this.packageInfo, required this.deviceLabel});

  final PackageInfo packageInfo;
  final String deviceLabel;
}
