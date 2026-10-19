import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'devtools_find.dart';
import 'models/find_hit.dart';

/// For a view that can hide content (a tab, a detail screen, a folded JSON node): [onFindReveal] opens it when the current match is inside.
mixin FindAware<T extends StatefulWidget> on State<T> {
  DevToolsFind? _find;
  int _handledVersion = 0;
  bool _checkScheduled = false;

  // ---------------- To implement ----------------

  /// Opens whatever hides [hit] when the match is in this view; ignore other matches, and stay safe to call twice.
  void onFindReveal(FindHit hit);

  // ---------------- Lifecycle ----------------

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
    // New content (another request, a re-filtered list): the pending match may live here now.
    _handledVersion = 0;
    _scheduleCheck();
  }

  @override
  void dispose() {
    _find?.removeListener(_scheduleCheck);
    super.dispose();
  }

  // ---------------- Private helpers ----------------

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
