import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../util/throttle.dart';
import 'devtools_find_scope.dart';
import 'models/find_hit.dart';
import 'models/find_source.dart';

/// Start offsets of every case-insensitive, non-overlapping match of [needle] (already lowercase) in [text].
List<int> findMatches(String text, String needle) {
  if (needle.isEmpty) return const [];
  final haystack = text.toLowerCase();
  final starts = <int>[];
  var from = 0;
  while (true) {
    final index = haystack.indexOf(needle, from);
    if (index < 0) return starts;
    starts.add(index);
    from = index + needle.length;
  }
}

/// Searches every tab and picks the [current] match; views bring it on screen themselves through `FindAware` and `FindText`.
class DevToolsFind extends ChangeNotifier {
  DevToolsFind(this.sources) : _hits = List.filled(sources.length, const []) {
    for (var tab = 0; tab < sources.length; tab++) {
      // A busy app changes its data constantly; re-searching on every change would keep the panel busy too.
      final refresh = Throttle(_refreshInterval, () => _refresh(tab));
      _refreshers.add(refresh);
      sources[tab].changes?.addListener(refresh.call);
    }
  }

  // ---------------- Settings ----------------

  static const _debounce = Duration(milliseconds: 150);
  static const _refreshInterval = Duration(milliseconds: 250);
  static const _maxCachedCounts = 100000;

  // ---------------- State ----------------

  /// One per tab, in tab order.
  final List<FindSource> sources;
  final List<Throttle> _refreshers = [];

  // Captured text never changes, so each string is counted once per query, not on every refresh.
  final _counts = HashMap<String, int>.identity();

  List<List<FindHit>> _hits;
  List<FindHit>? _flatHits;
  Timer? _debounceTimer;
  String _needle = '';
  int? _index;

  /// The tab on screen, so a fresh search starts there instead of jumping elsewhere.
  int currentTab = 0;

  /// Bumped on every step, so views can tell a step apart from a data refresh.
  int revealVersion = 0;

  /// The [revealVersion] whose match is already scrolled into view.
  int revealedVersion = 0;

  // ---------------- Results ----------------

  /// The applied search text, lowercased; empty while there's nothing to find.
  String get needle => _needle;

  /// Whether a search is running.
  bool get isActive => _needle.isNotEmpty;

  /// Every match across all tabs, in order.
  List<FindHit> get hits => _flatHits ??= [for (final tab in _hits) ...tab];

  /// How many matches [tab] has.
  int countIn(int tab) => _hits[tab].length;

  /// The selected match, or null when there's none.
  FindHit? get current {
    final index = _index;
    return index == null ? null : hits[index];
  }

  /// The 1-based position of [current], or 0 when there's none.
  int get position {
    final index = _index;
    return index == null ? 0 : index + 1;
  }

  /// Whether [current] still has to be scrolled into view.
  bool get revealPending => revealVersion != revealedVersion;

  // ---------------- Actions ----------------

  /// Waits for a short pause in typing so each keystroke doesn't re-search every body; clearing applies at once.
  void search(String value) {
    _debounceTimer?.cancel();
    final needle = value.trim().isEmpty ? '' : value.toLowerCase();
    if (needle.isEmpty) {
      _apply('');
    } else {
      _debounceTimer = Timer(_debounce, () => _apply(needle));
    }
  }

  /// Selects the next match, wrapping around.
  void next() => _step(1);

  /// Selects the previous match, wrapping around.
  void previous() => _step(-1);

  /// Called by the `FindText` that brought [current] on screen.
  void markRevealed() => revealedVersion = revealVersion;

  /// The find controller of the nearest panel, or null outside one, where text renders without highlights.
  static DevToolsFind? maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<DevToolsFindScope>()
          ?.notifier;
    }
    return context.getInheritedWidgetOfExactType<DevToolsFindScope>()?.notifier;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (var tab = 0; tab < sources.length; tab++) {
      sources[tab].changes?.removeListener(_refreshers[tab].call);
      _refreshers[tab].dispose();
    }
    super.dispose();
  }

  // ---------------- Private helpers ----------------

  void _apply(String needle) {
    if (needle == _needle) return;
    _needle = needle;
    _counts.clear();
    _hits = [for (var tab = 0; tab < sources.length; tab++) _search(tab)];
    _flatHits = null;
    _index = null;
    final all = hits;
    if (all.isNotEmpty) {
      // Like a browser: the first match from where you are, not from the very top.
      final fromHere = all.indexWhere((hit) => hit.tab >= currentTab);
      _index = fromHere < 0 ? 0 : fromHere;
      revealVersion++;
    }
    notifyListeners();
  }

  void _step(int delta) {
    final count = hits.length;
    if (count == 0) return;
    final from = _index ?? (delta > 0 ? -1 : 0);
    _index = (from + delta) % count;
    revealVersion++;
    notifyListeners();
  }

  List<FindHit> _search(int tab) {
    if (_needle.isEmpty) return const [];
    final out = <FindHit>[];
    if (_counts.length > _maxCachedCounts) _counts.clear();
    for (final target in sources[tab].targets()) {
      final count =
          _counts[target.text] ??= findMatches(target.text, _needle).length;
      for (var i = 0; i < count; i++) {
        out.add(FindHit(tab: tab, target: target, occurrence: i));
      }
    }
    return out;
  }

  // Keeps current on the same match when data changes, and never bumps revealVersion: new data mustn't yank the screen.
  void _refresh(int tab) {
    if (_needle.isEmpty) return;
    final fresh = _search(tab);
    final unchanged = _sameHits(_hits[tab], fresh);
    final keep = current;
    _hits[tab] = fresh;
    _flatHits = null;
    if (unchanged) return;
    final all = hits;
    if (all.isEmpty) {
      _index = null;
    } else if (keep == null) {
      _index = 0;
    } else {
      final same = all.indexWhere(
        (hit) =>
            hit.target.id == keep.target.id &&
            hit.occurrence == keep.occurrence,
      );
      _index = same >= 0 ? same : (_index ?? 0).clamp(0, all.length - 1);
    }
    notifyListeners();
  }

  static bool _sameHits(List<FindHit> a, List<FindHit> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].target.id != b[i].target.id ||
          a[i].occurrence != b[i].occurrence) {
        return false;
      }
    }
    return true;
  }
}
