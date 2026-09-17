import 'package:flutter/widgets.dart';

import '../devtools_controller.dart';

/// Makes [onBack] the target of Android's hardware back button for as long as this widget stays mounted, so it undoes just this nested view instead of closing the whole panel or reaching the host app underneath.
class BackHandlerScope extends StatefulWidget {
  const BackHandlerScope({super.key, required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  State<BackHandlerScope> createState() => _BackHandlerScopeState();
}

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
