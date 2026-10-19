import 'package:flutter/widgets.dart';

import '../../corextra_devtools.dart';

/// Makes Android's back button call [onBack] while mounted, so it closes just this nested view, not the whole panel or the host app.
class BackHandlerScope extends StatefulWidget {
  const BackHandlerScope({
    super.key,
    required this.onBack,
    required this.child,
  });

  /// Closes this nested view.
  final VoidCallback onBack;

  /// The nested view itself.
  final Widget child;

  @override
  State<BackHandlerScope> createState() => _BackHandlerScopeState();
}

// ---------------- State ----------------

class _BackHandlerScopeState extends State<BackHandlerScope> {
  VoidCallback? _unregister;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(BackHandlerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-register so back never calls a stale closure from an old build.
    if (oldWidget.onBack != widget.onBack) {
      _unregister?.call();
      _register();
    }
  }

  void _register() {
    _unregister = CorextraDevTools.instance.pushBackHandler(widget.onBack);
  }

  @override
  void dispose() {
    _unregister?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
