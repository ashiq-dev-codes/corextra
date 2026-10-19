import 'package:flutter/foundation.dart';

import 'find_target.dart';

/// A tab's searchable text, read from its data rather than its widgets, so off-screen rows, closed details and other tabs all count.
class FindSource {
  const FindSource({required this.targets, this.changes});

  /// Every text the tab can show, in on-screen order.
  final Iterable<FindTarget> Function() targets;

  /// Fires when the tab's data changes, so the search can refresh.
  final Listenable? changes;
}
