import 'dart:async';
import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../util/throttle.dart';

/// One piece of text a DevTools tab can show, as handed to the find bar.
class FindTarget {
  const FindTarget(this.id, this.text, [this.meta]);

  /// The [FindText.id] that renders [text] — how a match is found on screen again once it's built.
  final String id;
  final String text;

  /// Whatever the owning view needs to bring [text] on screen, e.g. which request and section it lives in.
  final Object? meta;
}

/// One occurrence of the query.
class FindHit {
  const FindHit({
    required this.tab,
    required this.target,
    required this.occurrence,
  });

  final int tab;
  final FindTarget target;

  /// Which match inside [target]'s text this is, counting from 0.
  final int occurrence;
}

/// Searched from a tab's data rather than its widgets, so off-screen rows, unopened details and other tabs all count.
class FindSource {
  const FindSource({required this.targets, this.changes});

  /// Every text the tab can show, in on-screen order.
  final Iterable<FindTarget> Function() targets;

  final Listenable? changes;
}

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

/// Only picks the [current] match — views bring it on screen themselves via [FindAware] and [FindText].
class DevToolsFind extends ChangeNotifier {
  DevToolsFind(this.sources) : _hits = List.filled(sources.length, const []) {
    for (var tab = 0; tab < sources.length; tab++) {
      // A busy app changes its data constantly; re-searching on every change would keep the panel busy too.
      final refresh = Throttle(_refreshInterval, () => _refresh(tab));
      _refreshers.add(refresh);
      sources[tab].changes?.addListener(refresh.call);
    }
  }

  static const _debounce = Duration(milliseconds: 150);
  static const _refreshInterval = Duration(milliseconds: 250);
  static const _maxCachedCounts = 100000;

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

  /// Bumped on every step, so views can tell a step apart from a mere data refresh.
  int revealVersion = 0;

  /// The [revealVersion] whose match is already scrolled into view.
  int revealedVersion = 0;

  /// The applied query, lowercased — empty while there's nothing to find.
  String get needle => _needle;

  bool get isActive => _needle.isNotEmpty;

  List<FindHit> get hits => _flatHits ??= [for (final tab in _hits) ...tab];

  int countIn(int tab) => _hits[tab].length;

  FindHit? get current => _index == null ? null : hits[_index!];

  /// 1-based position of [current], or 0 when there's none.
  int get position => _index == null ? 0 : _index! + 1;

  bool get revealPending => revealVersion != revealedVersion;

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

  void next() => _step(1);

  void previous() => _step(-1);

  /// Called by the [FindText] that brought [current] on screen.
  void markRevealed() => revealedVersion = revealVersion;

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

  /// Keeps [current] on the same match when data changes, and never bumps [revealVersion] — new data mustn't yank the screen.
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
      _index = same >= 0 ? same : _index!.clamp(0, all.length - 1);
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

  /// Null outside a panel, where everything simply renders without highlights.
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
}

class DevToolsFindScope extends InheritedNotifier<DevToolsFind> {
  const DevToolsFindScope({
    super.key,
    required DevToolsFind find,
    required super.child,
  }) : super(notifier: find);
}

/// For a view that can hide content (a tab, a drill-in detail, a folded JSON node): [onFindReveal] must open it when the current match is inside, ignore other matches, and be safe to repeat.
mixin FindAware<T extends StatefulWidget> on State<T> {
  DevToolsFind? _find;
  int _handledVersion = 0;
  bool _checkScheduled = false;

  void onFindReveal(FindHit hit);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final find = DevToolsFind.maybeOf(context, listen: false);
    if (find == _find) return;
    _find?.removeListener(_scheduleCheck);
    _find = find?..addListener(_scheduleCheck);
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New content (another request, a re-filtered list) — the pending match may live here now.
    _handledVersion = 0;
    _scheduleCheck();
  }

  @override
  void dispose() {
    _find?.removeListener(_scheduleCheck);
    super.dispose();
  }

  // After the frame, so a parent that just opened this view has finished rebuilding it first.
  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      final find = _find;
      if (!mounted || find == null) return;
      final hit = find.current;
      if (hit == null || !find.revealPending) return;
      if (_handledVersion == find.revealVersion) return;
      _handledVersion = find.revealVersion;
      onFindReveal(hit);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }
}

/// A separated, lazily-built list that scrolls to the row holding the current match, even one it hasn't built yet.
class FindListView extends StatefulWidget {
  const FindListView({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.indexOfHit,
    this.itemKey,
    this.padding,
  });

  final ScrollController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final EdgeInsetsGeometry? padding;

  /// A stable identity per row, so when new data arrives at the top the existing rows are moved rather than rebuilt with different content.
  final Object Function(int index)? itemKey;

  /// The row [hit] lives in, or null if it isn't in this list.
  final int? Function(FindHit hit) indexOfHit;

  @override
  State<FindListView> createState() => _FindListViewState();
}

class _FindListViewState extends State<FindListView>
    with FindAware<FindListView> {
  @override
  void onFindReveal(FindHit hit) {
    final index = widget.indexOfHit(hit);
    final find = DevToolsFind.maybeOf(context, listen: false);
    if (index == null || index < 0 || find == null) return;
    revealListRow(
      find,
      widget.controller,
      index: index,
      count: widget.itemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemKey = widget.itemKey;
    Map<Object, int>? indexByKey;
    // A builder with each separator under its row, not ListView.separated, whose key-lookup API differs across supported Flutter versions.
    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      itemCount: widget.itemCount,
      findChildIndexCallback:
          itemKey == null
              ? null
              : (key) {
                indexByKey ??= {
                  for (var i = 0; i < widget.itemCount; i++) itemKey(i): i,
                };
                return key is ValueKey ? indexByKey![key.value] : null;
              },
      itemBuilder: (context, index) {
        final row = widget.itemBuilder(context, index);
        final child =
            index == widget.itemCount - 1
                ? row
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [row, widget.separatorBuilder(context, index)],
                );
        return itemKey == null
            ? child
            : KeyedSubtree(key: ValueKey(itemKey(index)), child: child);
      },
    );
  }
}

/// A lazy list can't jump to a row it hasn't laid out, so this homes in over a few frames until the row's [FindText] has built and revealed itself.
Future<void> revealListRow(
  DevToolsFind find,
  ScrollController controller, {
  required int index,
  required int count,
}) async {
  final version = find.revealVersion;
  for (var attempt = 0; attempt < 8; attempt++) {
    await SchedulerBinding.instance.endOfFrame;
    if (!find.revealPending || find.revealVersion != version) return;
    if (!controller.hasClients || count == 0) return;
    final position = controller.position;
    final extent = position.maxScrollExtent + position.viewportDimension;
    final estimate = extent * index / count - position.viewportDimension / 2;
    position.jumpTo(
      estimate.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }
}
