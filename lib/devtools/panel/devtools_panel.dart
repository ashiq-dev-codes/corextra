import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../devtools_controller.dart';
import 'tabs/info_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/performance_tab.dart';

/// The DevTools inspector panel: Network / Logs / Performance / Info
/// tabs, plus a header with theme, minimize, "Clear all", and close
/// controls.
class DevToolsPanel extends StatelessWidget {
  const DevToolsPanel({
    super.key,
    required this.onClose,
    required this.onMinimize,
  });

  final VoidCallback onClose;

  /// Minimizes the panel to a small floating status chip instead of
  /// closing it outright — see `DevToolsPipChip`.
  final VoidCallback onMinimize;

  static const _tabs = [
    Tab(icon: Icon(LucideIcons.network), text: 'Network'),
    Tab(icon: Icon(LucideIcons.fileText), text: 'Logs'),
    Tab(icon: Icon(LucideIcons.gauge), text: 'Performance'),
    Tab(icon: Icon(LucideIcons.info), text: 'Info'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: DefaultTabController(
          length: _tabs.length,
          child: Column(
            children: [
              _Header(onClose: onClose, onMinimize: onMinimize),
              const Divider(height: 1),
              const TabBar(tabs: _tabs),
              const Divider(height: 1),
              const Expanded(
                child: TabBarView(
                  children: [
                    NetworkTab(),
                    LogsTab(),
                    PerformanceTab(),
                    InfoTab(),
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

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onMinimize});

  final VoidCallback onClose;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(LucideIcons.bug, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'DevTools',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const _ThemeToggleButton(),
          IconButton(
            tooltip: 'Minimize',
            icon: const Icon(LucideIcons.pictureInPicture2),
            onPressed: onMinimize,
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(LucideIcons.trash),
            onPressed: () => CorextraDevTools.instance.resetAll(),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: CorextraDevTools.instance.themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
          icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
          onPressed: () => CorextraDevTools.instance.themeMode =
              isDark ? ThemeMode.light : ThemeMode.dark,
        );
      },
    );
  }
}
