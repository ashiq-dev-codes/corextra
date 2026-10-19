import 'package:flutter/widgets.dart';

import '../../util/throttle.dart';

/// A [ListenableBuilder] that rebuilds at most every [interval] however fast [listenable] fires, so a busy app never makes the panel busy.
class DevToolsLiveBuilder extends StatefulWidget {
  const DevToolsLiveBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.interval = const Duration(milliseconds: 250),
  });

  // ---------------- Settings ----------------

  /// The capture data to watch, usually a store on `CorextraDevTools.instance`.
  final Listenable listenable;

  /// Builds the content from the latest data.
  final WidgetBuilder builder;

  /// The shortest time between two rebuilds.
  final Duration interval;

  @override
  State<DevToolsLiveBuilder> createState() => _DevToolsLiveBuilderState();
}

// ---------------- State ----------------

class _DevToolsLiveBuilderState extends State<DevToolsLiveBuilder> {
  late Throttle _throttle = Throttle(widget.interval, _rebuild);

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_onChange);
  }

  @override
  void didUpdateWidget(DevToolsLiveBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable == widget.listenable &&
        oldWidget.interval == widget.interval) {
      return;
    }
    oldWidget.listenable.removeListener(_onChange);
    widget.listenable.addListener(_onChange);
    _throttle.dispose();
    _throttle = Throttle(widget.interval, _rebuild);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChange);
    _throttle.dispose();
    super.dispose();
  }

  void _onChange() => _throttle();

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
