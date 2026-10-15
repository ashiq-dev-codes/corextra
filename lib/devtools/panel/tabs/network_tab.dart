import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../find/devtools_find.dart';
import '../../find/find_text.dart';
import '../../models/network_event.dart';
import '../../util/pretty_json.dart';
import '../../util/platform_services.dart';
import '../back_handler_scope.dart';
import '../edge_scrollbar.dart';
import '../empty_state.dart';
import '../live_builder.dart';
import '../scroll_to_top_fab.dart';

/// Lists captured HTTP exchanges from `CorextraDevTools.instance.network`.
///
/// Above [_splitBreakpoint], this is a master/detail split — a compact
/// list on the left, the selected request's full detail on the right.
/// Below it, there's no room for both side by side, so tapping a row
/// instead drills into a full-screen detail view (with a back button
/// to return) rather than expanding inline in place. An inline
/// accordion was tried first, but it nests a scrollable request body
/// inside the same scroll region as the request list itself — on a
/// large response, that pits the list's scroll against the body's,
/// each capturing drags meant for the other. Drilling in, like the
/// wide layout's detail pane, keeps exactly one scrollable on screen
/// at a time.
class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  static final FindSource findSource = FindSource(
    changes: CorextraDevTools.instance.network,
    targets: _networkFindTargets,
  );

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

const _emptyMessage = 'No requests captured yet';
const _emptyHint = 'Add CorextraDevToolsInterceptor or CorextraSocketLogger.';

/// Where a piece of a request's text lives — tells the tab what to open to show it.
enum _Section {
  row,
  status,
  url,
  error,
  requestHeaders,
  responseHeaders,
  query,
  requestBody,
  responseBody;

  /// The detail tab (Headers / Payload / Response) showing this section, if any.
  int? get detailTab => switch (this) {
    row || status => null,
    url || error || requestHeaders || responseHeaders => 0,
    query || requestBody => 1,
    responseBody => 2,
  };
}

class _NetworkFindMeta {
  const _NetworkFindMeta(this.eventId, this.section);

  final String eventId;
  final _Section section;
}

String _findPrefix(NetworkEvent event, _Section section) =>
    '${event.id}/${section.name}';

/// Mirrors exactly what the list row and detail view render, in the same order, with headers as masked on screen.
Iterable<FindTarget> _networkFindTargets() sync* {
  final events = CorextraDevTools.instance.network.events;
  if (events.isEmpty) {
    yield const FindTarget('network/empty/message', _emptyMessage);
    yield const FindTarget('network/empty/hint', _emptyHint);
    return;
  }
  for (final event in events.reversed) {
    FindTarget target(_Section section, String key, String text) => FindTarget(
      '${_findPrefix(event, section)}/$key',
      text,
      _NetworkFindMeta(event.id, section),
    );

    yield target(_Section.row, 'method', event.method.toUpperCase());
    yield target(_Section.row, 'path', _displayPath(event));
    yield target(_Section.row, 'caption', _rowCaption(event));
    yield target(_Section.status, 'label', _statusLabelFor(event));
    yield target(_Section.url, 'text', event.url);
    if (event.errorMessage != null) {
      yield target(_Section.error, 'text', event.errorMessage!);
    }
    if (!event.isSocket) {
      for (final (section, headers) in [
        (_Section.requestHeaders, event.requestHeaders),
        (_Section.responseHeaders, event.responseHeaders),
      ]) {
        for (final entry in headers.entries) {
          yield target(section, 'k/${entry.key}', entry.key);
          yield target(
            section,
            'v/${entry.key}',
            _headerDisplayValue(entry, event.hiddenHeaderKeys),
          );
        }
      }
    }
    for (final section in [
      if (event.queryParameters.isNotEmpty) _Section.query,
      _Section.requestBody,
      _Section.responseBody,
    ]) {
      final lines = _bodyOf(event, section).plainLines;
      for (var i = 0; i < lines.length; i++) {
        yield target(section, '$i', lines[i]);
      }
    }
  }
}

int? _rowIndexOf(List<NetworkEvent> events, FindHit hit) {
  final meta = hit.target.meta;
  if (meta is! _NetworkFindMeta || meta.section != _Section.row) return null;
  return events.indexWhere((event) => event.id == meta.eventId);
}

class _NetworkTabState extends State<NetworkTab> with FindAware<NetworkTab> {
  static const double _splitBreakpoint = 700;

  NetworkEvent? _selected;
  bool _isWide = false;
  final Set<_MethodFilter> _activeMethods = Set.of(_MethodFilter.values);
  final Set<_StatusFilter> _activeStatuses = Set.of(_StatusFilter.values);

  bool _passesFilters(NetworkEvent event) =>
      _activeMethods.contains(_methodFilterFor(event)) &&
      _activeStatuses.contains(_statusFilterFor(event));

  /// Opens the request a match lives in — and, like a browser expanding a collapsed section, never leaves it hidden behind a filter.
  @override
  void onFindReveal(FindHit hit) {
    final meta = hit.target.meta;
    if (meta is! _NetworkFindMeta) return;
    final event =
        CorextraDevTools.instance.network.events
            .where((event) => event.id == meta.eventId)
            .firstOrNull;
    if (event == null) return;
    setState(() {
      if (!_passesFilters(event)) _resetFilterSets();
      if (meta.section != _Section.row) {
        _selected = event;
      } else if (!_isWide) {
        // A row match needs the list, which a phone-width detail screen replaces.
        _selected = null;
      }
    });
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

  void _resetFilterSets() {
    _activeMethods
      ..clear()
      ..addAll(_MethodFilter.values);
    _activeStatuses
      ..clear()
      ..addAll(_StatusFilter.values);
  }

  void _resetFilters() => setState(_resetFilterSets);

  @override
  Widget build(BuildContext context) {
    final store = CorextraDevTools.instance.network;
    return DevToolsLiveBuilder(
      listenable: store,
      builder: (context) {
        final events = store.events.reversed.toList();
        if (events.isEmpty) {
          return const DevToolsEmptyState(
            icon: LucideIcons.network,
            message: _emptyMessage,
            hint: _emptyHint,
            findId: 'network/empty',
          );
        }

        final filtered = events.where(_passesFilters).toList();

        // The selected event may have scrolled out of the ring buffer,
        // or been filtered out; treat either as "nothing selected"
        // rather than pointing the detail pane at something no longer
        // in view.
        final selected =
            (_selected != null && filtered.contains(_selected))
                ? _selected
                : null;

        final filtersActive =
            _activeMethods.length != _MethodFilter.values.length ||
            _activeStatuses.length != _StatusFilter.values.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _splitBreakpoint;
            _isWide = isWide;

            if (!isWide && selected != null) {
              return _NarrowDetailScreen(
                event: selected,
                onBack: () => setState(() => _selected = null),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 8),
                _NetworkFilterBar(
                  activeMethods: _activeMethods,
                  activeStatuses: _activeStatuses,
                  onMethodChanged: _toggleMethod,
                  onStatusChanged: _toggleStatus,
                  onReset: filtersActive ? _resetFilters : null,
                ),
                Expanded(
                  child:
                      filtered.isEmpty
                          ? const DevToolsEmptyState(
                            icon: LucideIcons.searchX,
                            message: 'No requests match the selected filters',
                          )
                          : isWide
                          ? _MasterDetailView(
                            events: filtered,
                            selected: selected,
                            onSelect:
                                (event) => setState(() => _selected = event),
                          )
                          : DevToolsScrollToTop(
                            scrollbar: true,
                            builder:
                                (context, controller) => FindListView(
                                  controller: controller,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  itemCount: filtered.length,
                                  itemKey: (index) => filtered[index].id,
                                  indexOfHit:
                                      (hit) => _rowIndexOf(filtered, hit),
                                  separatorBuilder:
                                      (context, index) => const Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                  itemBuilder: (context, index) {
                                    final event = filtered[index];
                                    return _CompactNetworkRow(
                                      event: event,
                                      selected: false,
                                      onTap:
                                          () =>
                                              setState(() => _selected = event),
                                    );
                                  },
                                ),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The narrow-screen (phone) detail view: a back button over the
/// selected request's full detail, filling the whole tab — the
/// narrow-width counterpart to [_MasterDetailView]'s right-hand pane.
class _NarrowDetailScreen extends StatelessWidget {
  const _NarrowDetailScreen({required this.event, required this.onBack});

  final NetworkEvent event;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BackHandlerScope(
      onBack: onBack,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to requests',
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: onBack,
                ),
                FindText(
                  'Request detail',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _NetworkEventDetail(event: event)),
        ],
      ),
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
                    FindText(
                      'Requests',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FindText(
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
                child: DevToolsScrollToTop(
                  scrollbar: true,
                  builder:
                      (context, controller) => FindListView(
                        controller: controller,
                        itemCount: events.length,
                        itemKey: (index) => events[index].id,
                        indexOfHit: (hit) => _rowIndexOf(events, hit),
                        separatorBuilder:
                            (context, index) => const Divider(
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
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              selectedEvent == null
                  ? const DevToolsEmptyState(
                    icon: LucideIcons.mousePointerClick,
                    message: 'Select a request to see its details',
                  )
                  : _NetworkEventDetail(event: selectedEvent),
        ),
      ],
    );
  }
}

/// A row for the master/detail list: status dot, method pill, path
/// (wraps up to 3 lines, not 1, since a cut-off single line often
/// loses the part that distinguishes it), and a duration/time caption.
class _CompactNetworkRow extends StatelessWidget {
  const _CompactNetworkRow({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final NetworkEvent event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = _findPrefix(event, _Section.row);

    return Material(
      color:
          selected
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
                findId: '$prefix/method',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FindText(
                      _displayPath(event),
                      id: '$prefix/path',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FindText(
                      _rowCaption(event),
                      id: '$prefix/caption',
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

final _rowTimeFormat = DateFormat('HH:mm:ss');

String _rowCaption(NetworkEvent event) {
  final durationMs = event.duration?.inMilliseconds;
  return durationMs != null
      ? '${durationMs}ms  ·  ${_rowTimeFormat.format(event.startedAt)}'
      : 'pending…';
}

/// The path for HTTP, or the event name for a socket message — whose name (e.g. `chat:open`) would otherwise parse as a URL scheme.
String _displayPath(NetworkEvent event) {
  if (event.isSocket) return event.socketEvent!;
  final uri = Uri.tryParse(event.url);
  return (uri != null && uri.path.isNotEmpty) ? uri.path : event.url;
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
    case 'EMIT':
    case 'SOCKET':
      return Colors.teal;
    case 'ON':
      return Colors.indigo;
    default:
      return Colors.blueGrey;
  }
}

Color _statusColorFor(NetworkEvent event) {
  if (event.isPending) return Colors.grey;
  if (event.isError && event.statusCode == null) return Colors.red;
  if (event.isSocket) return Colors.green;
  final code = event.statusCode ?? 0;
  if (code >= 200 && code < 300) return Colors.green;
  if (code >= 300 && code < 400) return Colors.blue;
  if (code >= 400 && code < 500) return Colors.orange;
  return Colors.red;
}

String _statusLabelFor(NetworkEvent event) {
  if (event.isPending) return '···';
  if (event.isError && event.statusCode == null) return 'ERR';
  if (event.isSocket) return 'OK';
  return '${event.statusCode}';
}

/// A fixed set of HTTP method buckets to filter by — matches the
/// coloring [_methodColor] already gives each method elsewhere in this
/// tab, plus a catch-all for anything less common (HEAD, OPTIONS, …).
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

/// A fixed set of status buckets to filter by — the same categories
/// [_statusColorFor] already color-codes, split into distinct filters
/// rather than left as one color, so e.g. "only server errors" is a
/// single tap.
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
                  // A label-derived key (rather than relying on tree
                  // order) lets tests target a specific option
                  // unambiguously — its label can otherwise also
                  // appear elsewhere, e.g. as a method pill on an
                  // already-visible row underneath this open popup.
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

/// The method/status summary, request/response detail shared by the
/// narrow-screen detail view and the wide-screen detail pane — laid
/// out browser-devtools-style: a fixed one-line summary up top, then
/// Headers / Payload / Response tabs below, each scrolling on its own.
///
/// Deliberately not one long stack of every section — the previous
/// design put query params, request headers+body, and response
/// headers+body all in one column, which meant a single huge response
/// pushed everything else minutes of scrolling away. Tabs isolate each
/// concern; only one tab's content occupies the screen at a time, so
/// it can scroll independently without competing with anything else
/// for the same drag.
///
/// The summary shows the method, path, status, duration, and time —
/// but the path, though it can be long, is capped to one line with
/// an ellipsis rather than left to wrap. That keeps this part of the
/// screen a small, fixed number of lines no matter the window size,
/// so it never needs (and never gets) a scrollbar of its own — two
/// scroll regions stacked on one screen (a tiny one up top, a real
/// one below) read as broken, not helpful. The full URL (base URL
/// included — no need to repeat it up here alongside the path) and a
/// long error message (if any) live inside the Headers tab instead,
/// alongside request/response headers, where it's already expected
/// to scroll.
class _NetworkEventDetail extends StatefulWidget {
  const _NetworkEventDetail({required this.event});

  final NetworkEvent event;

  @override
  State<_NetworkEventDetail> createState() => _NetworkEventDetailState();
}

/// How far past the top a tab has to scroll before an up/down swipe starts collapsing or restoring the summary — small enough to react promptly, large enough to ignore an idle bounce right at the top.
const _summaryCollapseThreshold = 24.0;

class _NetworkEventDetailState extends State<_NetworkEventDetail>
    with SingleTickerProviderStateMixin, FindAware<_NetworkEventDetail> {
  bool _summaryCollapsed = false;
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  void onFindReveal(FindHit hit) {
    final meta = hit.target.meta;
    if (meta is! _NetworkFindMeta || meta.eventId != widget.event.id) return;
    final tab = meta.section.detailTab;
    // Instant, so the match isn't scrolled into view on a page that's still sliding in.
    if (tab != null && tab != _tabs.index) _tabs.index = tab;
  }

  void _handleTabScroll(double offset, ScrollDirection direction) {
    final collapse =
        offset > _summaryCollapseThreshold &&
        direction == ScrollDirection.reverse;
    final expand =
        offset <= _summaryCollapseThreshold ||
        direction == ScrollDirection.forward;
    if (collapse && !_summaryCollapsed) {
      setState(() => _summaryCollapsed = true);
    } else if (expand && _summaryCollapsed) {
      setState(() => _summaryCollapsed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              _summaryCollapsed
                  ? Padding(
                    key: const ValueKey('compact-summary'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _DetailSummary(event: event, compact: true),
                  )
                  : Padding(
                    key: const ValueKey('full-summary'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _DetailSummary(event: event),
                  ),
        ),
        Expanded(
          child: Column(
            children: [
              const Divider(height: 1),
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: event.isSocket ? 'General' : 'Headers'),
                  const Tab(text: 'Payload'),
                  const Tab(text: 'Response'),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _HeadersTab(event: event, onScroll: _handleTabScroll),
                    _PayloadTab(event: event, onScroll: _handleTabScroll),
                    _ResponseTab(event: event, onScroll: _handleTabScroll),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The full URL, the error (if any), and request/response headers —
/// everything about *how* the exchange was framed, as opposed to what
/// was actually sent/received. The URL and error message live here,
/// not in the fixed summary above the tabs, because either can run
/// long (a verbose DioException message, an unusually long URL) and
/// this tab already scrolls to accommodate that.
class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.event, this.onScroll});

  final NetworkEvent event;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return DevToolsScrollToTop(
      onScroll: onScroll,
      builder:
          (context, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SubsectionLabel('URL'),
                const SizedBox(height: 4),
                FindText(
                  event.url,
                  id: '${_findPrefix(event, _Section.url)}/text',
                  selectable: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                  ),
                ),
                if (event.errorMessage != null) ...[
                  const SizedBox(height: 20),
                  const _SubsectionLabel('ERROR'),
                  const SizedBox(height: 4),
                  _ErrorBanner(
                    message: event.errorMessage!,
                    findId: '${_findPrefix(event, _Section.error)}/text',
                  ),
                ],
                if (!event.isSocket) ...[
                  const SizedBox(height: 20),
                  const _SubsectionLabel('REQUEST HEADERS'),
                  const SizedBox(height: 4),
                  _KeyValueList(
                    data: event.requestHeaders,
                    hiddenKeys: event.hiddenHeaderKeys,
                    findPrefix: _findPrefix(event, _Section.requestHeaders),
                  ),
                  const SizedBox(height: 20),
                  const _SubsectionLabel('RESPONSE HEADERS'),
                  const SizedBox(height: 4),
                  _KeyValueList(
                    data: event.responseHeaders,
                    hiddenKeys: event.hiddenHeaderKeys,
                    findPrefix: _findPrefix(event, _Section.responseHeaders),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}

/// Query parameters and the request body — everything that was sent
/// *to* the server.
class _PayloadTab extends StatelessWidget {
  const _PayloadTab({required this.event, this.onScroll});

  final NetworkEvent event;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = _maxBodyHeight(constraints);
        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.queryParameters.isNotEmpty) ...[
                const _SubsectionLabel('QUERY PARAMETERS'),
                const SizedBox(height: 4),
                _BodyView(
                  event: event,
                  section: _Section.query,
                  title: 'Query Parameters',
                  maxHeight: maxHeight,
                  onScroll: onScroll,
                ),
                const SizedBox(height: 20),
              ],
              const _SubsectionLabel('REQUEST BODY'),
              const SizedBox(height: 4),
              _BodyView(
                event: event,
                section: _Section.requestBody,
                title: 'Request Body',
                maxHeight: maxHeight,
                onScroll: onScroll,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The response body on its own — the thing most worth a full tab to
/// itself, since it's the one most likely to be large.
class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.event, this.onScroll});

  final NetworkEvent event;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.all(16),
            child: _BodyView(
              event: event,
              section: _Section.responseBody,
              title: 'Response',
              maxHeight: _maxBodyHeight(constraints),
              onScroll: onScroll,
            ),
          ),
    );
  }
}

/// Tall enough for a body block to fill its tab below the tab's padding, so a large body scrolls inside its own block — toolbar and both scrollbars in view — instead of stretching the tab; never shorter than a usable block in a tiny floating window, where the tab itself scrolls instead.
double _maxBodyHeight(BoxConstraints constraints) =>
    math.max(constraints.maxHeight - 32, 200);

/// Method + path + status/duration/time — a fixed-*height* block
/// shown above the detail pane's tabs, even though the path itself
/// can be long: it's capped to one line with an ellipsis rather than
/// left free to wrap, so this stays a small, constant number of
/// lines no matter the window size or how long the URL is. The full
/// URL (base URL included) — worth reading in full, not just
/// glancing at, and not worth repeating up here alongside the path —
/// lives in the Headers tab, where scrolling is already expected.
class _DetailSummary extends StatelessWidget {
  const _DetailSummary({required this.event, this.compact = false});

  final NetworkEvent event;

  /// A one-line method + path + status strip instead of the full block, used while [_NetworkEventDetail] has collapsed it to make room for the active tab's content.
  final bool compact;

  static final _timeFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColorFor(event);
    final durationMs = event.duration?.inMilliseconds;
    final path = _displayPath(event);
    final statusId = '${_findPrefix(event, _Section.status)}/label';

    if (compact) {
      return Row(
        children: [
          _Pill(
            text: event.method.toUpperCase(),
            color: _methodColor(event.method),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FindText(
              path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FindText(
            _statusLabelFor(event),
            id: statusId,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Pill(
              text: event.method.toUpperCase(),
              color: _methodColor(event.method),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FindText(
                path,
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
        const SizedBox(height: 6),
        Row(
          children: [
            FindText(
              _statusLabelFor(event),
              id: statusId,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            FindText(
              durationMs != null ? '${durationMs}ms' : 'pending…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            FindText(
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
  const _Pill({required this.text, required this.color, this.findId});

  final String text;
  final Color color;
  final String? findId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: FindText(
        text,
        id: findId,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// A small muted small-caps label distinguishing sub-parts of a tab
/// (e.g. "QUERY PARAMETERS" vs. "REQUEST BODY" within the Payload tab).
class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FindText(
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

/// Header names known to carry auth credentials — flags a row below with a badge + copy button.
const _sensitiveHeaderNames = {
  'authorization',
  'proxy-authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
  'api-key',
  'x-auth-token',
  'x-access-token',
  'access-token',
  'x-csrf-token',
  'x-xsrf-token',
  'x-session-token',
};

bool _isSensitiveHeader(String key) =>
    _sensitiveHeaderNames.contains(key.toLowerCase());

/// Masks a hidden header value for on-screen display, keeping the last few characters visible so a tester can tell tokens apart without exposing the whole value — full mask if that would reveal too much of a short value.
String _maskedPreview(String value) {
  const visibleTail = 4;
  const minMaskedChars = 3;
  if (value.length <= visibleTail + minMaskedChars) return '***';
  return '***${value.substring(value.length - visibleTail)}';
}

bool _isHiddenHeader(String key, Set<String> hiddenKeys) =>
    hiddenKeys.contains(key.toLowerCase());

/// What a header row shows — find searches this, never the real value of a masked header.
String _headerDisplayValue(
  MapEntry<String, String> entry,
  Set<String> hiddenKeys,
) =>
    _isHiddenHeader(entry.key, hiddenKeys)
        ? _maskedPreview(entry.value)
        : entry.value;

/// A clean key/value list, used for headers — instead of a raw
/// `Map.toString()` dump.
class _KeyValueList extends StatelessWidget {
  const _KeyValueList({
    required this.data,
    required this.findPrefix,
    this.hiddenKeys = const {},
  });

  final Map<String, String> data;
  final Set<String> hiddenKeys;
  final String findPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return FindText(
        'No headers',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          data.entries.map((entry) {
            final hidden = _isHiddenHeader(entry.key, hiddenKeys);
            final sensitive = _isSensitiveHeader(entry.key) || hidden;
            final displayValue = _headerDisplayValue(entry, hiddenKeys);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        FindText(
                          entry.key,
                          id: '$findPrefix/k/${entry.key}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sensitive) _TokenBadge(hidden: hidden),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FindText(
                      displayValue,
                      id: '$findPrefix/v/${entry.key}',
                      selectable: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontStyle: hidden ? FontStyle.italic : FontStyle.normal,
                        color:
                            hidden
                                ? theme.colorScheme.onSurfaceVariant
                                : sensitive
                                ? theme.colorScheme.primary
                                : null,
                      ),
                    ),
                  ),
                  if (sensitive) ...[
                    _CopyIconButton(text: () => entry.value),
                    _ShareIconButton(text: () => entry.value),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }
}

/// A small badge marking a header row flagged by [_isSensitiveHeader].
class _TokenBadge extends StatelessWidget {
  const _TokenBadge({required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          hidden
              ? 'Masked on screen by hiddenHeaders — Copy still copies the real value'
              : 'Looks like an auth token or credential',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.keyRound, size: 9, color: Colors.amber),
            SizedBox(width: 2),
            Text(
              'TOKEN',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A request body as the panel shows it — decoded and split into lines once per request, then shared by the view, find and Copy, so a busy app never pays to redo it.
class _Body {
  _Body._(this.data, this.lines, this._json);

  factory _Body.of(Object? data) {
    final json = _decodeJson(data);
    if (json != null) {
      try {
        return _Body._(data, _flattenJson(json), json);
      } catch (_) {
        // A value JSON can't encode — show it as plain text below.
      }
    }
    final text = prettyFormatBody(data);
    return _Body._(data, [
      for (final line in text.split('\n')) _CodeLine.text(line),
    ], null);
  }

  final Object? data;
  final List<_CodeLine> lines;
  final Object? _json;

  bool get isJson => _json != null;

  late final List<String> plainLines = [
    for (final line in lines) line.plainText,
  ];

  /// Encoded only when Copy or Share is tapped, never just to show the body.
  String copyText() {
    if (_json != null) {
      try {
        return const JsonEncoder.withIndent('  ').convert(_json);
      } catch (_) {
        // Falls through to the lines as shown.
      }
    }
    return plainLines.join('\n');
  }

  final Map<double, double> _widths = {};

  /// Monospace, so a line's width is its character count — wide characters (CJK, emoji) count double.
  double contentWidth(double charWidth) =>
      _widths[charWidth] ??= () {
        var widest = 0.0;
        for (final line in lines) {
          var units = line.plainText.length + line.collapsedExtraChars;
          for (final unit in line.plainText.codeUnits) {
            if (unit >= 0x1100) units++;
          }
          widest = math.max(widest, line.indent + units * charWidth);
        }
        return widest;
      }();
}

Object? _decodeJson(Object? data) {
  if (data is Map || data is List) return data;
  if (data is! String) return null;
  try {
    final value = jsonDecode(data);
    return value is Map || value is List ? value : null;
  } catch (_) {
    return null;
  }
}

final _bodyCache = Expando<Map<_Section, _Body>>();

/// Cached on the request itself, so it's freed along with it once the request leaves the capture buffer.
_Body _bodyOf(NetworkEvent event, _Section section) {
  final data = switch (section) {
    _Section.query => event.queryParameters,
    _Section.requestBody => event.requestBody,
    _ => event.responseBody,
  };
  final cache = _bodyCache[event] ??= {};
  final cached = cache[section];
  if (cached != null && identical(cached.data, data)) return cached;
  return cache[section] = _Body.of(data);
}

/// Shows a request body as a collapsible JSON tree when it decodes to an object or array, falling back to plain lines otherwise.
class _BodyView extends StatelessWidget {
  const _BodyView({
    required this.event,
    required this.section,
    required this.title,
    this.maxHeight = double.infinity,
    this.onScroll,
  });

  final NetworkEvent event;
  final _Section section;
  final String title;

  /// A body taller than this scrolls inside its own block rather than growing past it.
  final double maxHeight;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: _CodeView(
        body: _bodyOf(event, section),
        title: title,
        findPrefix: _findPrefix(event, section),
        onScroll: onScroll,
      ),
    );
  }
}

const _codeStyle = TextStyle(fontFamily: 'monospace', fontSize: 12.5);

/// One code line's height and one character's width at the current text scale — measured, so lines can be given exact heights up front.
({double charWidth, double lineHeight}) _codeMetrics(TextScaler scaler) {
  final painter = TextPainter(
    text: const TextSpan(text: '0000000000', style: _codeStyle),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final metrics = (charWidth: painter.width / 10, lineHeight: painter.height);
  painter.dispose();
  return metrics;
}

/// A monospace code block that builds only the lines on screen, so even a huge body opens instantly and costs nothing while the app keeps capturing.
class _CodeView extends StatefulWidget {
  const _CodeView({
    required this.body,
    required this.title,
    required this.findPrefix,
    this.standalone = true,
    this.onScroll,
  });

  final _Body body;
  final String title;

  /// Each line's find id is this plus its index — the same lines the find source lists.
  final String findPrefix;

  /// False for the fresh copy built for the fullscreen view itself, so it doesn't offer to open yet another fullscreen view on top of the one it's already in.
  final bool standalone;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  State<_CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<_CodeView> with FindAware<_CodeView> {
  final Set<String> _collapsedPaths = {};
  List<int>? _visible;
  ScrollController? _vertical;
  var _metrics = (charWidth: 7.5, lineHeight: 15.0);

  List<_CodeLine> get _lines => widget.body.lines;

  @override
  void didUpdateWidget(_CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.body, widget.body)) _visible = null;
  }

  /// Indices of the lines not folded away, in order.
  List<int> get _visibleLines =>
      _visible ??= () {
        final out = <int>[];
        for (var i = 0; i < _lines.length; i++) {
          out.add(i);
          final line = _lines[i];
          // Folded: its children and closing line are skipped; the toggle line shows them inline.
          if (line.isOpen && _collapsedPaths.contains(line.path)) {
            i = line.closeIndex!;
          }
        }
        return out;
      }();

  double _extentOf(_CodeLine line) {
    final text = _metrics.lineHeight;
    if (line.isOpen) return math.max(34, text + 4);
    return line.plain ? text + 4 : text + 10;
  }

  void _setCollapsed(void Function(Set<String> paths) change) {
    setState(() {
      change(_collapsedPaths);
      _visible = null;
    });
  }

  void _toggle(String path) => _setCollapsed((paths) {
    if (!paths.add(path)) paths.remove(path);
  });

  void _expandAll() => _setCollapsed((paths) => paths.clear());

  void _collapseAll() => _setCollapsed(
    (paths) =>
        paths
          ..clear()
          ..addAll([
            for (final line in _lines)
              if (line.isOpen) line.path,
          ]),
  );

  /// Unfolds whatever hides the current match, then scrolls its line into the built range so its [FindText] can show the exact words.
  @override
  void onFindReveal(FindHit hit) {
    final prefix = '${widget.findPrefix}/';
    if (!hit.target.id.startsWith(prefix)) return;
    final index = int.tryParse(hit.target.id.substring(prefix.length));
    if (index == null || index >= _lines.length) return;
    final hiding = [
      for (var i = 0; i < index; i++)
        if (_lines[i].isOpen &&
            index <= _lines[i].closeIndex! &&
            _collapsedPaths.contains(_lines[i].path))
          _lines[i].path,
    ];
    if (hiding.isNotEmpty) _setCollapsed((paths) => paths.removeAll(hiding));
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollTo(index));
  }

  void _scrollTo(int lineIndex) {
    final vertical = _vertical;
    if (!mounted || vertical == null || !vertical.hasClients) return;
    final rows = _visibleLines;
    final row = rows.indexOf(lineIndex);
    if (row < 0) return;
    var offset = _codeTopPadding;
    for (var i = 0; i < row; i++) {
      offset += _extentOf(_lines[rows[i]]);
    }
    final position = vertical.position;
    position.jumpTo(
      (offset - position.viewportDimension / 3).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _metrics = _codeMetrics(MediaQuery.textScalerOf(context));
    final rows = _visibleLines;
    var height = _codeTopPadding + _codeBottomPadding;
    for (final row in rows) {
      height += _extentOf(_lines[row]);
    }
    return _CodeBlockChrome(
      copyText: widget.body.copyText,
      title: widget.title,
      fullscreenBuilder:
          widget.standalone
              ? (context) => _CodeView(
                body: widget.body,
                title: widget.title,
                findPrefix: widget.findPrefix,
                standalone: false,
              )
              : null,
      actions: [
        if (widget.body.isJson) ...[
          IconButton(
            tooltip: 'Expand all',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.chevronsUpDown),
            onPressed: _expandAll,
          ),
          IconButton(
            tooltip: 'Collapse all',
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.chevronsDownUp),
            onPressed: _collapseAll,
          ),
        ],
      ],
      child: _ScrollableCode(
        onScroll: widget.onScroll,
        onVerticalController: (controller) => _vertical = controller,
        height: height,
        contentWidth: widget.body.contentWidth(_metrics.charWidth),
        itemCount: rows.length,
        itemExtent: (row) => _extentOf(_lines[rows[row]]),
        itemBuilder: (context, row) {
          final index = rows[row];
          final line = _lines[index];
          final findId = '${widget.findPrefix}/$index';
          return line.isOpen
              ? _CodeToggleLine(
                line: line,
                collapsed: _collapsedPaths.contains(line.path),
                findId: findId,
                theme: theme,
                onTap: () => _toggle(line.path),
              )
              : _CodeLeafLine(line: line, findId: findId, theme: theme);
        },
      ),
    );
  }
}

const _codeTopPadding = 8.0;
const _codeBottomPadding = 16.0;

/// The shared box and action buttons around a [_CodeView] — actions float over the top-right corner instead of narrowing every line's scroll width for a button only the top needs, and stay pinned there while the content scrolls underneath.
class _CodeBlockChrome extends StatelessWidget {
  const _CodeBlockChrome({
    required this.child,
    required this.copyText,
    required this.title,
    this.actions = const [],
    this.fullscreenBuilder,
  });

  final Widget child;
  final ValueGetter<String> copyText;
  final String title;
  final List<Widget> actions;

  /// Builds a fresh, independent copy of this block for the fullscreen view — not [child] itself, so interacting with it there (e.g. folding a JSON node) doesn't desync from the inline view's own state.
  final WidgetBuilder? fullscreenBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 4,
            right: 4,
            child: _CodeBlockActionBar(
              actions: [
                ...actions,
                if (fullscreenBuilder != null)
                  _FullscreenIconButton(
                    title: title,
                    builder: fullscreenBuilder!,
                  ),
                _ShareIconButton(text: copyText),
                _CopyIconButton(text: copyText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small floating pill of icon buttons, opaque enough to stay legible over scrolled-under code content.
class _CodeBlockActionBar extends StatelessWidget {
  const _CodeBlockActionBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
    );
  }
}

/// Opens [builder]'s content full-screen via the ambient [Overlay] — deliberately not [Navigator], since the panel is documented to work with no Navigator above it (only a local Overlay) when mounted the recommended way via `MaterialApp.builder`.
class _FullscreenIconButton extends StatefulWidget {
  const _FullscreenIconButton({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  State<_FullscreenIconButton> createState() => _FullscreenIconButtonState();
}

class _FullscreenIconButtonState extends State<_FullscreenIconButton> {
  OverlayEntry? _entry;

  void _open() {
    final entry = OverlayEntry(
      builder:
          (context) => _FullscreenContentView(
            title: widget.title,
            onClose: _close,
            child: widget.builder(context),
          ),
    );
    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'View fullscreen',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: const Icon(LucideIcons.maximize2),
      onPressed: _open,
    );
  }
}

/// The full-screen frame a [_FullscreenIconButton] shows its content in — a back button and title above the given [child], which gets the whole screen instead of sharing space with everything above the tab bar.
class _FullscreenContentView extends StatelessWidget {
  const _FullscreenContentView({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BackHandlerScope(
      onBack: onClose,
      child: Positioned.fill(
        child: Material(
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: onClose,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // The block scrolls itself, so here it just gets the whole screen as its limit.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(alignment: Alignment.topCenter, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The content inside a [_CodeBlockChrome], scrolling both ways within the block's own box — both scrollbars always show and can be dragged, pinned to the box's right and bottom edges, so neither ends up far below the fold on a large body the way a scrollbar under the last line would.
class _ScrollableCode extends StatefulWidget {
  const _ScrollableCode({
    required this.height,
    required this.contentWidth,
    required this.itemCount,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onVerticalController,
    this.onScroll,
  });

  /// The natural height of every line; the block shrinks to it when that's less than its limit.
  final double height;
  final double contentWidth;
  final int itemCount;
  final double Function(int index) itemExtent;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<ScrollController> onVerticalController;

  /// Reports vertical scrolling, e.g. so the detail view can collapse its summary.
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  State<_ScrollableCode> createState() => _ScrollableCodeState();
}

class _ScrollableCodeState extends State<_ScrollableCode> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Its own scroll-to-top button, sitting inside the box clear of both scrollbars.
    return DevToolsScrollToTop(
      onScroll: widget.onScroll,
      builder: (context, vertical) {
        widget.onVerticalController(vertical);
        return NotificationListener<ScrollMetricsNotification>(
          // Content or box size changed (e.g. a JSON node folded) — resize the thumbs to match.
          onNotification: (_) {
            setState(() {});
            return false;
          },
          child: SizedBox(
            height: widget.height,
            child: Stack(
              key: const ValueKey('code-block-scroll-area'),
              children: [
                LayoutBuilder(
                  builder:
                      (context, box) => SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 10, right: 16),
                        child: SizedBox(
                          width: math.max(
                            widget.contentWidth,
                            box.maxWidth - 26,
                          ),
                          // Lines are built only while on screen, each at a known height, so a huge body costs no more than a small one.
                          child: ListView.builder(
                            controller: vertical,
                            padding: const EdgeInsets.only(
                              top: _codeTopPadding,
                              bottom: _codeBottomPadding,
                            ),
                            itemCount: widget.itemCount,
                            itemExtentBuilder:
                                (index, _) =>
                                    index < widget.itemCount
                                        ? widget.itemExtent(index)
                                        : null,
                            itemBuilder:
                                (context, index) => OverflowBox(
                                  alignment: Alignment.centerLeft,
                                  maxWidth: double.infinity,
                                  // Never wraps: a line wider than the estimate just runs on, like an editor.
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: widget.itemBuilder(context, index),
                                  ),
                                ),
                          ),
                        ),
                      ),
                ),
                // Starts below the floating action bar, so the bar never covers the thumb.
                DevToolsEdgeScrollbar(
                  controller: vertical,
                  axis: Axis.vertical,
                  startInset: 48,
                  endInset: 16,
                  thumbKeyPrefix: 'code-scrollbar-thumb',
                ),
                DevToolsEdgeScrollbar(
                  controller: _horizontal,
                  axis: Axis.horizontal,
                  endInset: 16,
                  thumbKeyPrefix: 'code-scrollbar-thumb',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One line of a body — a JSON tree line or a plain text line; the view and find both read these, so they always agree on the text.
class _CodeLine {
  const _CodeLine({
    required this.path,
    required this.depth,
    required this.keyPrefix,
    required this.text,
    this.trailing = '',
    this.value,
    this.muted = false,
    this.closeIndex,
    this.closeBrace = '',
    this.comma = '',
    this.countLabel = '',
  }) : plain = false;

  const _CodeLine.text(this.text)
    : path = '',
      depth = 0,
      keyPrefix = '',
      trailing = '',
      value = null,
      muted = false,
      plain = true,
      closeIndex = null,
      closeBrace = '',
      comma = '',
      countLabel = '';

  final String path;
  final int depth;
  final String keyPrefix;

  /// The literal, a brace, or for a plain line the whole line.
  final String text;
  final String trailing;

  /// The primitive this line shows, for coloring.
  final Object? value;

  /// A brace or an empty `{}`/`[]` rather than a value.
  final bool muted;

  /// A plain text line, not part of a JSON tree.
  final bool plain;

  /// Set on a foldable container's opening line: the index of its closing line.
  final int? closeIndex;
  final String closeBrace;
  final String comma;
  final String countLabel;

  bool get isOpen => closeIndex != null;

  String get plainText => '$keyPrefix$text$trailing';

  /// Pixels before the text starts: the tree indent, plus the fold chevron on a toggle line.
  double get indent => depth * 16.0 + (isOpen ? 30 : 0);

  /// What a folded toggle line appends (` … }, 3 keys`), so the block is wide enough either way.
  int get collapsedExtraChars =>
      isOpen ? 6 + closeBrace.length + comma.length + countLabel.length : 0;
}

List<_CodeLine> _flattenJson(Object value) {
  final lines = <_CodeLine?>[];

  void visit(
    Object? node,
    String path,
    String keyPrefix,
    String comma,
    int depth,
  ) {
    final children =
        node is Map
            ? [
              for (final entry in node.entries)
                (
                  keyPrefix: '"${entry.key}": ',
                  value: entry.value,
                  path: '$path.${entry.key}',
                ),
            ]
            : node is List
            ? [
              for (var i = 0; i < node.length; i++)
                (keyPrefix: '', value: node[i], path: '$path[$i]'),
            ]
            : null;
    if (children == null) {
      lines.add(
        _CodeLine(
          path: path,
          depth: depth,
          keyPrefix: keyPrefix,
          text: jsonEncode(node),
          trailing: comma,
          value: node,
        ),
      );
      return;
    }

    final (openBrace, closeBrace) = node is Map ? ('{', '}') : ('[', ']');
    if (children.isEmpty) {
      lines.add(
        _CodeLine(
          path: path,
          depth: depth,
          keyPrefix: keyPrefix,
          text: '$openBrace$closeBrace',
          trailing: comma,
          muted: true,
        ),
      );
      return;
    }

    // Reserved now, filled once the closing line's index is known.
    final openIndex = lines.length;
    lines.add(null);
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      visit(
        child.value,
        child.path,
        child.keyPrefix,
        i == children.length - 1 ? '' : ',',
        depth + 1,
      );
    }
    lines.add(
      _CodeLine(
        path: '$path/close',
        depth: depth,
        keyPrefix: '',
        text: closeBrace,
        trailing: comma,
        muted: true,
      ),
    );
    final noun = node is Map ? 'key' : 'item';
    lines[openIndex] = _CodeLine(
      path: path,
      depth: depth,
      keyPrefix: keyPrefix,
      text: openBrace,
      closeIndex: lines.length - 1,
      closeBrace: closeBrace,
      comma: comma,
      countLabel:
          children.length == 1 ? '1 $noun' : '${children.length} ${noun}s',
    );
  }

  visit(value, 'root', '', '', 0);
  return [for (final line in lines) line!];
}

/// Value colors from the DevTools theme's seeded [ColorScheme] — light mode uses the `on*Container` roles (M3's own choice for legible text) since the bare accent roles used in dark mode read pale on a light surface.
Color _literalColor(Object? value, ThemeData theme) {
  final colors = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  if (value is String) {
    return isDark ? colors.tertiary : colors.onTertiaryContainer;
  }
  if (value is num) {
    return isDark ? colors.secondary : colors.onSecondaryContainer;
  }
  if (value is bool) {
    return isDark ? colors.primary : colors.onPrimaryContainer;
  }
  return colors.onSurfaceVariant;
}

/// One non-collapsible line — a plain text line, a JSON primitive, an empty `{}`/`[]`, or a container's closing brace.
class _CodeLeafLine extends StatelessWidget {
  const _CodeLeafLine({
    required this.line,
    required this.findId,
    required this.theme,
  });

  final _CodeLine line;
  final String findId;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (line.plain) {
      return FindText(
        line.text,
        id: findId,
        selectable: true,
        style: _codeStyle,
      );
    }
    final valueColor =
        line.muted
            ? theme.colorScheme.onSurfaceVariant
            : _literalColor(line.value, theme);
    final italicValue = !line.muted && line.value == null;
    return Padding(
      padding: EdgeInsets.only(left: line.depth * 16.0),
      child: FindText.rich(
        TextSpan(
          style: _codeStyle,
          children: [
            if (line.keyPrefix.isNotEmpty)
              TextSpan(
                text: line.keyPrefix,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            TextSpan(
              text: line.text,
              style: TextStyle(
                color: valueColor,
                fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            TextSpan(
              text: line.trailing,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        id: findId,
        selectable: true,
      ),
    );
  }
}

/// A collapsible object/array's opening line — its chevron/`{`/`[` toggles [onTap]; collapsed, it also shows the closing brace and an item count inline.
class _CodeToggleLine extends StatelessWidget {
  const _CodeToggleLine({
    required this.line,
    required this.collapsed,
    required this.findId,
    required this.theme,
    required this.onTap,
  });

  final _CodeLine line;
  final bool collapsed;
  final String findId;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final punctStyle = _codeStyle.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: EdgeInsets.only(left: line.depth * 16.0, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: Icon(
                    collapsed
                        ? LucideIcons.chevronRight
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          FindText.rich(
            TextSpan(
              style: punctStyle,
              children: [
                if (line.keyPrefix.isNotEmpty)
                  TextSpan(
                    text: line.keyPrefix,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                TextSpan(text: line.text),
                if (collapsed)
                  TextSpan(text: ' … ${line.closeBrace}${line.comma}'),
                if (collapsed)
                  TextSpan(
                    text: '  ${line.countLabel}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
            id: findId,
            selectable: true,
          ),
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatefulWidget {
  const _CopyIconButton({required this.text});

  final ValueGetter<String> text;

  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text()));
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

/// Opens the platform share sheet for [text], anchored to this button's own position so it doesn't crash iPad's popover-based presentation.
class _ShareIconButton extends StatelessWidget {
  const _ShareIconButton({required this.text});

  final ValueGetter<String> text;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      await shareText(text(), origin: origin);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Share',
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: const Icon(LucideIcons.share2),
      onPressed: () => _share(context),
    );
  }
}

/// A small callout banner for connection/network errors.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.findId});

  final String message;
  final String findId;

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
            child: FindText(
              message,
              id: findId,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
