import 'package:flutter/widgets.dart';

import '../util/throttle.dart';

/// A [ListenableBuilder] for live capture data: however fast [listenable] fires, it rebuilds at most every [interval], so a busy app never makes the panel busy too.
class DevToolsLiveBuilder extends StatefulWidget {
  const DevToolsLiveBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.interval = const Duration(milliseconds: 250),
  });

  final Listenable listenable;
  final WidgetBuilder builder;
  final Duration interval;

  @override
  State<DevToolsLiveBuilder> createState() => _DevToolsLiveBuilderState();
}

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
