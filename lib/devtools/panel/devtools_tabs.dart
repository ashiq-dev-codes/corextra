import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../find/find.dart';
import 'tabs/info/info_tab.dart';
import 'tabs/logs/logs_tab.dart';
import 'tabs/network/network_tab.dart';

// ---------------- Tab spec ----------------

/// One entry in the tab strip.
class _TabSpec {
  const _TabSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

// ---------------- Tabs ----------------

/// The Network, Logs and Info tabs under one find bar that searches all of them; the body of `DevToolsPanel`.
///
/// Use it on its own when you want the tabs inside your own layout, without the panel's header.
///
/// Example:
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: const Text('Debug')),
///   body: const DevToolsTabs(),
/// )
/// ```
class DevToolsTabs extends StatefulWidget {
  /// Creates the tabs with the Network tab selected.
  const DevToolsTabs({super.key});

  // Must match the order of the TabBarView children and the find sources below.
  static const _tabs = [
    _TabSpec(icon: LucideIcons.network, label: 'Network'),
    _TabSpec(icon: LucideIcons.fileText, label: 'Logs'),
    _TabSpec(icon: LucideIcons.info, label: 'Info'),
  ];

  @override
  State<DevToolsTabs> createState() => _DevToolsTabsState();
}

// ---------------- State ----------------

class _DevToolsTabsState extends State<DevToolsTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Same order as the tabs themselves.
  final _find = DevToolsFind([
    NetworkTab.findSource,
    LogsTab.findSource,
    InfoTab.findSource,
  ]);
  final _findFocus = FocusNode();

  // The find reveal last acted on, so the same match never switches tabs twice.
  int _shownVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: DevToolsTabs._tabs.length, vsync: this)
      ..addListener(() => _find.currentTab = _tabs.index);
    _find.addListener(_showCurrentTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _find.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  void _showCurrentTab() {
    final hit = _find.current;
    if (hit == null || _find.revealVersion == _shownVersion) return;
    _shownVersion = _find.revealVersion;
    // Instant, not animated: scrolling the match into view mid-slide would drag the sliding page along with it.
    if (_tabs.index != hit.tab) _tabs.index = hit.tab;
  }

  @override
  Widget build(BuildContext context) {
    return DevToolsFindScope(
      find: _find,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
              _findFocus.requestFocus,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              _findFocus.requestFocus,
        },
        child: Column(
          children: [
            DevToolsFindBar(find: _find, focusNode: _findFocus),
            _TabStrip(controller: _tabs, find: _find),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: const [NetworkTab(), LogsTab(), InfoTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Private widgets ----------------

/// The fixed row: one button per tab.
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller, required this.find});

  final TabController controller;
  final DevToolsFind find;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, find]),
      builder: (context, _) {
        final index = controller.index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < DevToolsTabs._tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    spec: DevToolsTabs._tabs[i],
                    selected: index == i,
                    matchCount: find.countIn(i),
                    onTap: () => controller.animateTo(i),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A tab icon wearing its find-match count, so it's obvious at a glance which tabs hold matches.
class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      backgroundColor: findMatchColor,
      textColor: findMatchTextColor,
      child: child,
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.matchCount,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final int matchCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
    return Material(
      color:
          selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MatchBadge(
                count: matchCount,
                child: Icon(spec.icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
