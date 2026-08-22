import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/network_event.dart';
import '../../util/pretty_json.dart';
import '../empty_state.dart';
import '../search_field.dart';

/// Lists captured HTTP exchanges from `CorextraDevTools.instance.network`.
///
/// Below [_splitBreakpoint] this is a single-column, expandable list (the
/// only way to fit both the list and its detail on a phone). Above it,
/// it switches to a master/detail split — a compact list on the left,
/// the selected request's full detail on the right — the same layout
/// Flutter's own DevTools Network view uses once there's room for it.
class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  static const double _splitBreakpoint = 700;

  final _searchController = TextEditingController();
  String _query = '';
  NetworkEvent? _selected;
  final Set<_MethodFilter> _activeMethods = Set.of(_MethodFilter.values);
  final Set<_StatusFilter> _activeStatuses = Set.of(_StatusFilter.values);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Matches against the active method/status filter chips, then — if
  /// there's search text — against method, URL, status code, and error
  /// message, the fields already visible in each row, so a match is
  /// never a surprise.
  bool _matches(NetworkEvent event, String query) {
    if (!_activeMethods.contains(_methodFilterFor(event.method))) {
      return false;
    }
    if (!_activeStatuses.contains(_statusFilterFor(event))) return false;
    if (query.isEmpty) return true;
    return event.method.toLowerCase().contains(query) ||
        event.url.toLowerCase().contains(query) ||
        event.statusCode?.toString() == query ||
        (event.errorMessage?.toLowerCase().contains(query) ?? false);
  }

  void _toggleMethod(_MethodFilter filter, bool active) {
    setState(() {
      if (active) {
        _activeMethods.add(filter);
      } else {
        _activeMethods.remove(filter);
      }
    });
  }

  void _toggleStatus(_StatusFilter filter, bool active) {
    setState(() {
      if (active) {
        _activeStatuses.add(filter);
      } else {
        _activeStatuses.remove(filter);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _activeMethods
        ..clear()
        ..addAll(_MethodFilter.values);
      _activeStatuses
        ..clear()
        ..addAll(_StatusFilter.values);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = CorextraDevTools.instance.network;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final events = store.events.reversed.toList();
        if (events.isEmpty) {
          return const DevToolsEmptyState(
            icon: LucideIcons.network,
            message: 'No requests captured yet',
            hint:
                'Add CorextraDevToolsInterceptor to a Dio instance to see '
                'requests here.',
          );
        }

        final query = _query.trim().toLowerCase();
        final filtered = events.where((e) => _matches(e, query)).toList();

        // The selected event may have scrolled out of the ring buffer,
        // or been filtered out by the search box or filters; treat
        // either as "nothing selected" rather than pointing the detail
        // pane at something no longer in view.
        final selected = (_selected != null && filtered.contains(_selected))
            ? _selected
            : null;

        final filtersActive =
            query.isNotEmpty ||
            _activeMethods.length != _MethodFilter.values.length ||
            _activeStatuses.length != _StatusFilter.values.length;

        return Column(
          children: [
            DevToolsSearchField(
              controller: _searchController,
              hintText: 'Search by method, URL, or status',
              onChanged: (value) => setState(() => _query = value),
            ),
            _NetworkFilterBar(
              activeMethods: _activeMethods,
              activeStatuses: _activeStatuses,
              onMethodChanged: _toggleMethod,
              onStatusChanged: _toggleStatus,
              onReset: filtersActive ? _resetFilters : null,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? DevToolsEmptyState(
                      icon: LucideIcons.searchX,
                      message: query.isEmpty
                          ? 'No requests match the selected filters'
                          : 'No requests match "${_query.trim()}"',
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= _splitBreakpoint) {
                          return _MasterDetailView(
                            events: filtered,
                            selected: selected,
                            onSelect: (event) =>
                                setState(() => _selected = event),
                          );
                        }
                        return ValueListenableBuilder<int>(
                          valueListenable:
                              CorextraDevTools.instance.networkCollapseSignal,
                          builder: (context, collapseGeneration, _) =>
                              ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) => _NetworkEventTile(
                              // Re-keying on the collapse generation forces
                              // every tile to remount collapsed — an
                              // ExpansionTile only reads `initiallyExpanded`
                              // once, in initState, so changing it on an
                              // already-mounted tile of the same key
                              // wouldn't otherwise close it.
                              key: ValueKey(
                                '${filtered[index].id}-$collapseGeneration',
                              ),
                              event: filtered[index],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The wide-screen layout: a compact request list on the left, the
/// selected request's full detail on the right.
class _MasterDetailView extends StatelessWidget {
  const _MasterDetailView({
    required this.events,
    required this.selected,
    required this.onSelect,
  });

  final List<NetworkEvent> events;
  final NetworkEvent? selected;
  final ValueChanged<NetworkEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedEvent = selected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Text(
                      'Requests',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${events.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _CompactNetworkRow(
                      event: event,
                      selected: identical(event, selected),
                      onTap: () => onSelect(event),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedEvent == null
              ? const DevToolsEmptyState(
                  icon: LucideIcons.mousePointerClick,
                  message: 'Select a request to see its details',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _NetworkEventDetail(
                    event: selectedEvent,
                    showSummary: true,
                  ),
                ),
        ),
      ],
    );
  }
}

/// A single-line row for the master/detail list: status dot, method
/// pill, path, and a duration/time caption — enough to scan quickly
/// without needing to expand it, since the detail pane already shows
/// everything else.
class _CompactNetworkRow extends StatelessWidget {
  const _CompactNetworkRow({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final NetworkEvent event;
  final bool selected;
  final VoidCallback onTap;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = Uri.tryParse(event.url);
    final path = (uri != null && uri.path.isNotEmpty) ? uri.path : event.url;
    final durationMs = event.duration?.inMilliseconds;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColorFor(event),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              _Pill(
                text: event.method.toUpperCase(),
                color: _methodColor(event.method),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      durationMs != null
                          ? '${durationMs}ms  ·  ${_timeFormat.format(event.startedAt)}'
                          : 'pending…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
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

Color _methodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return Colors.blue;
    case 'POST':
      return Colors.green;
    case 'PUT':
      return Colors.orange;
    case 'PATCH':
      return Colors.purple;
    case 'DELETE':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

Color _statusColorFor(NetworkEvent event) {
  if (event.isPending) return Colors.grey;
  if (event.isError && event.statusCode == null) return Colors.red;
  final code = event.statusCode ?? 0;
  if (code >= 200 && code < 300) return Colors.green;
  if (code >= 300 && code < 400) return Colors.blue;
  if (code >= 400 && code < 500) return Colors.orange;
  return Colors.red;
}

String _statusLabelFor(NetworkEvent event) {
  if (event.isPending) return '···';
  if (event.isError && event.statusCode == null) return 'ERR';
  return '${event.statusCode}';
}

/// A fixed set of HTTP method buckets to filter by — matches the
/// coloring [_methodColor] already gives each method elsewhere in this
/// tab, plus a catch-all for anything less common (HEAD, OPTIONS, …).
enum _MethodFilter { get, post, put, patch, delete, other }

extension on _MethodFilter {
  String get label => switch (this) {
    _MethodFilter.get => 'GET',
    _MethodFilter.post => 'POST',
    _MethodFilter.put => 'PUT',
    _MethodFilter.patch => 'PATCH',
    _MethodFilter.delete => 'DELETE',
    _MethodFilter.other => 'Other',
  };
}

_MethodFilter _methodFilterFor(String method) {
  switch (method.toUpperCase()) {
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

/// A fixed set of status buckets to filter by — the same categories
/// [_statusColorFor] already color-codes, split into distinct filters
/// rather than left as one color, so e.g. "only server errors" is a
/// single tap.
enum _StatusFilter { success, redirect, clientError, serverError, pending, failed }

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
  final code = event.statusCode ?? 0;
  if (code >= 200 && code < 300) return _StatusFilter.success;
  if (code >= 300 && code < 400) return _StatusFilter.redirect;
  if (code >= 400 && code < 500) return _StatusFilter.clientError;
  return _StatusFilter.serverError;
}

/// A single, compact row below the search box: one dropdown button for
/// HTTP method, one for status category, and a "Reset" action that only
/// appears once some filter is actually narrowing the list. Replaces an
/// earlier design that laid every option out as always-visible chips —
/// tidy with a handful of options, but with two filter dimensions and
/// six options each, it read as a wall of tiny buttons rather than
/// something scannable at a glance.
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
    // A horizontally-scrolling row rather than one that relies on a
    // Spacer to fit: the smallest supported width (the PiP window's
    // 280px minimum) can't always fit two dropdown buttons plus a
    // conditional "Reset" without either wrapping badly or overflowing.
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

/// A small pill button (e.g. "Method  All") that opens an anchored
/// checklist popup on tap — deliberately built on [MenuAnchor] rather
/// than `showMenu`/`showModalBottomSheet`/`PopupMenuButton` (which all
/// push a route onto the nearest `Navigator`): this tab can be hosted
/// with no `Navigator` above it at all — only a local `Overlay` — when
/// `CorextraDevToolsOverlay` is mounted the recommended way, via
/// `MaterialApp.builder`. `MenuAnchor` inserts into that `Overlay`
/// directly and never touches routing.
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
    final summary = allActive
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
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
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
                  // A label-derived key (rather than relying on tree
                  // order) lets tests target a specific option
                  // unambiguously — its label can otherwise also
                  // appear elsewhere, e.g. as a method pill on an
                  // already-visible row underneath this open popup.
                  key: ValueKey('filter-option-${widget.label}-${widget.labelOf(value)}'),
                  label: widget.labelOf(value),
                  color: widget.colorOf(value),
                  active: widget.active.contains(value),
                  onTap: () => widget.onChanged(
                    value,
                    !widget.active.contains(value),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
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
          color: allActive
              ? theme.colorScheme.surfaceContainerHighest
              : tintColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.listFilter,
                    size: 13,
                    color: allActive
                        ? theme.colorScheme.onSurfaceVariant
                        : tintColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: allActive
                          ? theme.colorScheme.onSurface
                          : tintColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: allActive
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
                    color: allActive
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

/// One checkable row inside a [_FilterMenuButton]'s popup — deliberately
/// a plain [InkWell], not a `MenuItemButton`, since the latter closes
/// the menu on every press; this needs to stay open across several taps
/// so multiple options can be toggled in one go. A real [Checkbox] plus
/// a colored dot (matching this option's color elsewhere in the tab —
/// the method pill, the status dot) make the current selection easy to
/// scan at a glance instead of relying on text alone.
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
                  color: active
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

/// The narrow-screen (phone) row: an expandable tile showing the same
/// detail inline, since there's no room for a separate detail pane.
class _NetworkEventTile extends StatelessWidget {
  const _NetworkEventTile({super.key, required this.event});

  final NetworkEvent event;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final uri = Uri.tryParse(event.url);
    final path = (uri != null && uri.path.isNotEmpty) ? uri.path : event.url;
    final query = (uri != null && uri.query.isNotEmpty) ? '?${uri.query}' : '';
    final host = uri?.host ?? '';
    final durationMs = event.duration?.inMilliseconds;
    final statusColor = _statusColorFor(event);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(13, 4, 16, 4),
        title: Row(
          children: [
            _Pill(text: event.method.toUpperCase(), color: _methodColor(event.method)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$path$query',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                _statusLabelFor(event),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                durationMs != null ? '${durationMs}ms' : 'pending…',
                style: mutedStyle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  host.isNotEmpty
                      ? '$host  ·  ${_timeFormat.format(event.startedAt)}'
                      : _timeFormat.format(event.startedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _NetworkEventDetail(event: event),
          ),
        ],
      ),
    );
  }
}

/// The headers/body detail shared by the phone-sized expandable tile and
/// the wide-screen detail pane.
class _NetworkEventDetail extends StatelessWidget {
  const _NetworkEventDetail({required this.event, this.showSummary = false});

  final NetworkEvent event;

  /// Whether to show a method/URL/status header above the detail —
  /// needed in the master/detail pane, where (unlike the expandable
  /// tile) there's no title row already showing that information.
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSummary) ...[
          _DetailSummary(event: event),
          const SizedBox(height: 16),
        ],
        if (event.errorMessage != null) ...[
          _ErrorBanner(message: event.errorMessage!),
          const SizedBox(height: 16),
        ],
        const _GroupHeader(icon: LucideIcons.arrowUpRight, label: 'Request'),
        const SizedBox(height: 8),
        if (event.queryParameters.isNotEmpty) ...[
          const _SubsectionLabel('QUERY PARAMETERS'),
          const SizedBox(height: 4),
          _CodeBlock(content: prettyFormatBody(event.queryParameters)),
          const SizedBox(height: 12),
        ],
        _KeyValueList(data: event.requestHeaders),
        const SizedBox(height: 8),
        _CodeBlock(content: prettyFormatBody(event.requestBody)),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        const _GroupHeader(icon: LucideIcons.arrowDownLeft, label: 'Response'),
        const SizedBox(height: 8),
        _KeyValueList(data: event.responseHeaders),
        const SizedBox(height: 8),
        _CodeBlock(content: prettyFormatBody(event.responseBody)),
      ],
    );
  }
}

/// Method + full URL + status/duration/time — the summary header shown
/// above the detail pane in master/detail mode.
class _DetailSummary extends StatelessWidget {
  const _DetailSummary({required this.event});

  final NetworkEvent event;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColorFor(event);
    final durationMs = event.duration?.inMilliseconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pill(
              text: event.method.toUpperCase(),
              color: _methodColor(event.method),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                event.url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _statusLabelFor(event),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              durationMs != null ? '${durationMs}ms' : 'pending…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeFormat.format(event.startedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small colored pill, used for the HTTP method badge.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

/// A small "Request" / "Response" group header with a leading icon.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// A small muted small-caps label distinguishing sub-parts of a group
/// (e.g. "QUERY PARAMETERS" vs. "HEADERS" within "Request") — lighter
/// weight than [_GroupHeader], which is reserved for the top-level
/// Request/Response split.
class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A clean key/value list, used for headers — instead of a raw
/// `Map.toString()` dump.
class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return Text(
        'No headers',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      entry.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// A monospace "code block" used for request/response bodies, with a
/// one-tap copy button.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
          _CopyIconButton(text: content),
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatefulWidget {
  const _CopyIconButton({required this.text});

  final String text;

  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy),
      onPressed: _copy,
    );
  }
}

/// A small callout banner for connection/network errors.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
