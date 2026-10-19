part of 'network_tab.dart';

// ---------------- Filter options ----------------

/// The method groups to filter by, matching [_methodColor], plus a catch-all for rarer methods like HEAD and OPTIONS.
enum _MethodFilter { get, post, put, patch, delete, socket, other }

extension on _MethodFilter {
  String get label => switch (this) {
    _MethodFilter.get => 'GET',
    _MethodFilter.post => 'POST',
    _MethodFilter.put => 'PUT',
    _MethodFilter.patch => 'PATCH',
    _MethodFilter.delete => 'DELETE',
    _MethodFilter.socket => 'Socket',
    _MethodFilter.other => 'Other',
  };
}

_MethodFilter _methodFilterFor(NetworkEvent event) {
  if (event.isSocket) return _MethodFilter.socket;
  switch (event.method.toUpperCase()) {
    case 'GET':
      return _MethodFilter.get;
    case 'POST':
      return _MethodFilter.post;
    case 'PUT':
      return _MethodFilter.put;
    case 'PATCH':
      return _MethodFilter.patch;
    case 'DELETE':
      return _MethodFilter.delete;
    default:
      return _MethodFilter.other;
  }
}

/// The status groups [_statusColorFor] colors, each its own filter so "only server errors" is a single tap.
enum _StatusFilter {
  success,
  redirect,
  clientError,
  serverError,
  pending,
  failed,
}

extension on _StatusFilter {
  String get label => switch (this) {
    _StatusFilter.success => 'Success',
    _StatusFilter.redirect => 'Redirect',
    _StatusFilter.clientError => 'Client Error',
    _StatusFilter.serverError => 'Server Error',
    _StatusFilter.pending => 'Pending',
    _StatusFilter.failed => 'Failed',
  };

  Color get color => switch (this) {
    _StatusFilter.success => Colors.green,
    _StatusFilter.redirect => Colors.blue,
    _StatusFilter.clientError => Colors.orange,
    _StatusFilter.serverError => Colors.red,
    _StatusFilter.pending => Colors.grey,
    _StatusFilter.failed => Colors.red,
  };
}

_StatusFilter _statusFilterFor(NetworkEvent event) {
  if (event.isPending) return _StatusFilter.pending;
  if (event.isError && event.statusCode == null) return _StatusFilter.failed;
  if (event.isSocket) return _StatusFilter.success;
  final code = event.statusCode ?? 0;
  if (code >= 200 && code < 300) return _StatusFilter.success;
  if (code >= 300 && code < 400) return _StatusFilter.redirect;
  if (code >= 400 && code < 500) return _StatusFilter.clientError;
  return _StatusFilter.serverError;
}

// ---------------- Filter bar ----------------

/// One dropdown each for method and status, plus Reset once a filter is on; always-visible chips read as a wall of tiny buttons.
class _NetworkFilterBar extends StatelessWidget {
  const _NetworkFilterBar({
    required this.activeMethods,
    required this.activeStatuses,
    required this.onMethodChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  final Set<_MethodFilter> activeMethods;
  final Set<_StatusFilter> activeStatuses;
  final void Function(_MethodFilter, bool) onMethodChanged;
  final void Function(_StatusFilter, bool) onStatusChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrolls sideways because the smallest floating window can't always fit both buttons and Reset without overflowing.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterMenuButton<_MethodFilter>(
              label: 'Method',
              values: _MethodFilter.values,
              active: activeMethods,
              labelOf: (filter) => filter.label,
              colorOf: (filter) => _methodColor(filter.label),
              onChanged: onMethodChanged,
            ),
            const SizedBox(width: 8),
            _FilterMenuButton<_StatusFilter>(
              label: 'Status',
              values: _StatusFilter.values,
              active: activeStatuses,
              labelOf: (filter) => filter.label,
              colorOf: (filter) => filter.color,
              onChanged: onStatusChanged,
            ),
            if (onReset != null) ...[
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(LucideIcons.rotateCcw, size: 13),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- Filter menu ----------------

/// A pill button that opens a checklist; uses [MenuAnchor], not `showMenu` or `PopupMenuButton`, since the panel may have no `Navigator` above it.
class _FilterMenuButton<T> extends StatefulWidget {
  const _FilterMenuButton({
    required this.label,
    required this.values,
    required this.active,
    required this.labelOf,
    required this.colorOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final Set<T> active;
  final String Function(T) labelOf;
  final Color Function(T) colorOf;
  final void Function(T, bool) onChanged;

  @override
  State<_FilterMenuButton<T>> createState() => _FilterMenuButtonState<T>();
}

class _FilterMenuButtonState<T> extends State<_FilterMenuButton<T>> {
  final _controller = MenuController();

  void _setAll(bool active) {
    for (final value in widget.values) {
      widget.onChanged(value, active);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allActive = widget.active.length == widget.values.length;
    final noneActive = widget.active.isEmpty;
    final summary =
        allActive
            ? 'All'
            : noneActive
            ? 'None'
            : '${widget.active.length} selected';
    final tintColor = theme.colorScheme.primary;

    return MenuAnchor(
      controller: _controller,
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const WidgetStatePropertyAll(4),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 210,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final value in widget.values)
                _FilterOptionRow(
                  // A label-based key lets tests find this option, since the same label can show as a method pill on a row below.
                  key: ValueKey(
                    'filter-option-${widget.label}-${widget.labelOf(value)}',
                  ),
                  label: widget.labelOf(value),
                  color: widget.colorOf(value),
                  active: widget.active.contains(value),
                  onTap:
                      () => widget.onChanged(
                        value,
                        !widget.active.contains(value),
                      ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _setAll(true),
                        icon: const Icon(LucideIcons.checkCheck, size: 14),
                        label: const Text(
                          'Select all',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _setAll(false),
                        icon: const Icon(LucideIcons.x, size: 14),
                        label: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) {
        return Material(
          color:
              allActive
                  ? theme.colorScheme.surfaceContainerHighest
                  : tintColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap:
                () =>
                    controller.isOpen ? controller.close() : controller.open(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.listFilter,
                    size: 13,
                    color:
                        allActive
                            ? theme.colorScheme.onSurfaceVariant
                            : tintColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          allActive ? theme.colorScheme.onSurface : tintColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          allActive
                              ? theme.colorScheme.onSurfaceVariant
                              : tintColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    controller.isOpen
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color:
                        allActive
                            ? theme.colorScheme.onSurfaceVariant
                            : tintColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One option in the filter menu; a plain [InkWell], not a `MenuItemButton`, so the menu stays open while several options are toggled.
class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    super.key,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: active ? color.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
        child: Row(
          children: [
            // A real checkbox plus the option's color dot makes the selection easy to scan, not just its text.
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: active,
                onChanged: (_) => onTap(),
                visualDensity: VisualDensity.compact,
                activeColor: color,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color:
                      active
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
