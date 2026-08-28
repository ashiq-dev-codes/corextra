import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
class DevToolsTabs extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _primaryTabs.length + _secondaryTabs.length,
      child: const Column(
        children: [
          _TabStrip(),
          Divider(height: 1),
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                NetworkTab(),
                LogsTab(),
                InfoTab(),
                PerformanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The fixed row: one button per primary tab, plus a trailing "more" button for the secondary ones.
class _TabStrip extends StatelessWidget {
  const _TabStrip();

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: controller,
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
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              _MoreTabButton(
                controller: controller,
                startIndex: DevToolsTabs._primaryTabs.length,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: selected
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
              Icon(spec.icon, size: 18, color: color),
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
  const _MoreTabButton({required this.controller, required this.startIndex});

  final TabController controller;
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
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    // Swap to the active secondary tab's own icon so it's never ambiguous which page is showing.
    final icon = selected
        ? DevToolsTabs._secondaryTabs[activeIndex].icon
        : LucideIcons.ellipsisVertical;

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
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => menuController.isOpen
                  ? menuController.close()
                  : menuController.open(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Icon(icon, size: 20, color: color),
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
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
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
          ],
        ),
      ),
    );
  }
}
