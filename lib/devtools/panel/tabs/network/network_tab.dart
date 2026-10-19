import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../corextra_devtools.dart';
import '../../../find/find.dart';
import '../../../models/network_event.dart';
import '../../../util/pretty_json.dart';
import '../../../util/platform_services.dart';
import '../../widgets/back_handler_scope.dart';
import '../../widgets/devtools_edge_scrollbar.dart';
import '../../widgets/devtools_empty_state.dart';
import '../../widgets/devtools_live_builder.dart';
import '../../widgets/devtools_scroll_to_top.dart';

part 'network_layout.dart';
part 'network_row.dart';
part 'network_filters.dart';
part 'network_detail.dart';
part 'network_headers.dart';
part 'network_body.dart';
part 'code_view.dart';
part 'code_lines.dart';
part 'network_shared_widgets.dart';

// ---------------- Network tab ----------------

/// Lists every captured HTTP request and socket message, with filters and a full detail view for each.
///
/// Wide screens show the list and the detail side by side; narrow screens open a request in its own screen instead of expanding it inline, so only one scrollable is on screen at a time.
///
/// Example:
/// ```dart
/// // Show captured requests inside your own debug screen
/// Scaffold(
///   appBar: AppBar(title: const Text('Requests')),
///   body: const NetworkTab(),
/// )
/// ```
class NetworkTab extends StatefulWidget {
  /// Creates the Network tab, which reads from `CorextraDevTools.instance.network`.
  const NetworkTab({super.key});

  /// Lets the find bar search this tab's data, including rows that are off screen.
  static final FindSource findSource = FindSource(
    changes: CorextraDevTools.instance.network,
    targets: _networkFindTargets,
  );

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

const _emptyMessage = 'No requests captured yet';
const _emptyHint = 'Add CorextraDevToolsInterceptor or CorextraSocketLogger.';

// ---------------- Find ----------------

/// Where a piece of a request's text lives, so the tab knows what to open to show it.
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

/// The request and section a find match belongs to.
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

/// The list index of the row a match is in, or null when the match is in a request's detail.
int? _rowIndexOf(List<NetworkEvent> events, FindHit hit) {
  final meta = hit.target.meta;
  if (meta is! _NetworkFindMeta || meta.section != _Section.row) return null;
  return events.indexWhere((event) => event.id == meta.eventId);
}

// ---------------- State ----------------

class _NetworkTabState extends State<NetworkTab> with FindAware<NetworkTab> {
  static const double _splitBreakpoint = 700;

  NetworkEvent? _selected;
  bool _isWide = false;
  final Set<_MethodFilter> _activeMethods = Set.of(_MethodFilter.values);
  final Set<_StatusFilter> _activeStatuses = Set.of(_StatusFilter.values);

  bool _passesFilters(NetworkEvent event) =>
      _activeMethods.contains(_methodFilterFor(event)) &&
      _activeStatuses.contains(_statusFilterFor(event));

  /// Opens the request a match is in and, like a browser opening a folded section, never leaves it hidden behind a filter.
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

        // The selected request may have left the capture buffer or been filtered out; either way, show nothing selected.
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
