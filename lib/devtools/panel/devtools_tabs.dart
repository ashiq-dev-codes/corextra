import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tabs/app_size_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/performance_tab.dart';

/// The DevTools tab bar and content — Network / Logs / Performance /
/// App Size / Info — shared by the full-screen `DevToolsPanel` and the
/// floating `DevToolsFloatingWindow`. Everything except each surface's
/// own header lives here, so both show identical, fully-featured
/// content; only the window they're framed in differs.
class DevToolsTabs extends StatelessWidget {
  const DevToolsTabs({super.key});

  static const _tabs = [
    Tab(icon: Icon(LucideIcons.network), text: 'Network'),
    Tab(icon: Icon(LucideIcons.fileText), text: 'Logs'),
    Tab(icon: Icon(LucideIcons.gauge), text: 'Performance'),
    Tab(icon: Icon(LucideIcons.hardDrive), text: 'App Size'),
    Tab(icon: Icon(LucideIcons.info), text: 'Info'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          const TabBar(tabs: _tabs),
          const Divider(height: 1),
          const Expanded(
            child: TabBarView(
              children: [
                NetworkTab(),
                LogsTab(),
                PerformanceTab(),
                AppSizeTab(),
                InfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
