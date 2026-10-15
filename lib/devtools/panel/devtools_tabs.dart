import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../find/devtools_find.dart';
import '../find/find_bar.dart';
import '../find/find_text.dart';
import 'tabs/info_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/performance_tab.dart';

/// One entry in the fixed tab strip or the overflow menu.
class _TabSpec {
  const _TabSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Network / Logs / Info are day-to-day checks and stay on the strip; Performance is occasional, so it lives behind the trailing "more" button instead.
class DevToolsTabs extends StatefulWidget {
  const DevToolsTabs({super.key});

  static const _primaryTabs = [
    _TabSpec(icon: LucideIcons.network, label: 'Network'),
    _TabSpec(icon: LucideIcons.fileText, label: 'Logs'),
    _TabSpec(icon: LucideIcons.info, label: 'Info'),
  ];

  static const _secondaryTabs = [
    _TabSpec(icon: LucideIcons.gauge, label: 'Performance'),
  ];

  @override
  State<DevToolsTabs> createState() => _DevToolsTabsState();
}

class _DevToolsTabsState extends State<DevToolsTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Same order as the tabs themselves.
  final _find = DevToolsFind([
    NetworkTab.findSource,
    LogsTab.findSource,
    InfoTab.findSource,
    PerformanceTab.findSource,
  ]);
  final _findFocus = FocusNode();
  int _shownVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length:
          DevToolsTabs._primaryTabs.length + DevToolsTabs._secondaryTabs.length,
      vsync: this,
    )..addListener(() => _find.currentTab = _tabs.index);
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
                children: const [
                  NetworkTab(),
                  LogsTab(),
                  InfoTab(),
                  PerformanceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The fixed row: one button per primary tab, plus a trailing "more" button for the secondary ones.
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
              for (var i = 0; i < DevToolsTabs._primaryTabs.length; i++)
                Expanded(
                  child: _TabButton(
                    spec: DevToolsTabs._primaryTabs[i],
                    selected: index == i,
                    matchCount: find.countIn(i),
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              _MoreTabButton(
                controller: controller,
                find: find,
                startIndex: DevToolsTabs._primaryTabs.length,
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

/// Uses MenuAnchor, not PopupMenuButton/showMenu, since the panel can be hosted with only a local Overlay and no Navigator above it.
class _MoreTabButton extends StatefulWidget {
  const _MoreTabButton({
    required this.controller,
    required this.find,
    required this.startIndex,
  });

  final TabController controller;
  final DevToolsFind find;
  final int startIndex;

  @override
  State<_MoreTabButton> createState() => _MoreTabButtonState();
}

class _MoreTabButtonState extends State<_MoreTabButton> {
  final _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawIndex = widget.controller.index - widget.startIndex;
    final activeIndex =
        (rawIndex >= 0 && rawIndex < DevToolsTabs._secondaryTabs.length)
            ? rawIndex
            : null;
    final selected = activeIndex != null;
    final color =
        selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
    // Swap to the active secondary tab's own icon so it's never ambiguous which page is showing.
    final icon =
        selected
            ? DevToolsTabs._secondaryTabs[activeIndex].icon
            : LucideIcons.ellipsisVertical;
    final matchCount = [
      for (var i = 0; i < DevToolsTabs._secondaryTabs.length; i++)
        widget.find.countIn(widget.startIndex + i),
    ].fold(0, (sum, count) => sum + count);

    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 4),
        ),
      ),
      menuChildren: [
        for (var i = 0; i < DevToolsTabs._secondaryTabs.length; i++)
          _MoreMenuItem(
            spec: DevToolsTabs._secondaryTabs[i],
            selected: activeIndex == i,
            matchCount: widget.find.countIn(widget.startIndex + i),
            onTap: () {
              widget.controller.animateTo(widget.startIndex + i);
              _menuController.close();
            },
          ),
      ],
      builder: (context, menuController, child) {
        return Tooltip(
          message: 'More',
          child: Material(
            color:
                selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap:
                  () =>
                      menuController.isOpen
                          ? menuController.close()
                          : menuController.open(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: _MatchBadge(
                  count: matchCount,
                  child: Icon(icon, size: 20, color: color),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
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
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        color:
            selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (matchCount > 0) ...[
              const SizedBox(width: 10),
              Badge.count(
                count: matchCount,
                backgroundColor: findMatchColor,
                textColor: findMatchTextColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
