import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../devtools_controller.dart';
import '../models/frame_sample.dart';
import '../panel/devtools_panel.dart';
import '../util/devtools_theme.dart';
import '../util/memory_probe.dart';
import 'devtools_bubble.dart';
import 'devtools_pip_chip.dart';

/// The overlay's current visual state: a floating bubble, the full
/// panel, or a minimized floating status chip.
enum _DisplayMode { closed, open, pip }

/// Wraps an app (or a subtree of one) with a floating DevTools bubble
/// that opens an in-app inspector panel (Network / Logs / Performance /
/// Info tabs).
///
/// Typical usage — wrap via `MaterialApp.builder` so the panel sits
/// above the app's own Navigator/Directionality:
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
///   home: const HomeScreen(),
/// )
/// ```
/// Visibility defaults to [CorextraDevTools.instance.enabled] (which
/// itself defaults to `kDebugMode`), so this can never accidentally stay
/// active in a release build. Pass [enabled] to seed it explicitly, or
/// toggle at runtime via `CorextraDevTools.instance.enabled = false;`.
///
/// The bubble is a small, always-present widget with no ancestor
/// `Overlay` (see [DevToolsBubble] for why) — it only ever occupies its
/// own small hit-testable area, so it never interferes with the host
/// app underneath. The panel, by contrast, is only ever mounted while
/// it's open, inside its own self-contained `Overlay` sized explicitly
/// to the screen — giving Material widgets that need one (tooltips,
/// popup menus) somewhere to attach, and the panel's Row/Column/Expanded
/// layout a concrete, finite size to lay out against, regardless of
/// where this widget sits relative to the host app's own Navigator.
/// Individual tabs (see `NetworkTab`) adapt their own content to the
/// available width — e.g. a master/detail split on larger screens —
/// rather than the panel itself changing shape.
class CorextraDevToolsOverlay extends StatefulWidget {
  const CorextraDevToolsOverlay({super.key, required this.child, this.enabled});

  final Widget child;
  final bool? enabled;

  @override
  State<CorextraDevToolsOverlay> createState() =>
      _CorextraDevToolsOverlayState();
}

class _CorextraDevToolsOverlayState extends State<CorextraDevToolsOverlay> {
  _DisplayMode _mode = _DisplayMode.closed;
  bool _capturing = false;
  Timer? _memoryTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled != null) {
      CorextraDevTools.instance.enabled = widget.enabled!;
    }
    CorextraDevTools.instance.enabledNotifier.addListener(_onEnabledChanged);
    _syncCapture();
  }

  @override
  void dispose() {
    CorextraDevTools.instance.enabledNotifier.removeListener(
      _onEnabledChanged,
    );
    _stopCapture();
    super.dispose();
  }

  void _onEnabledChanged() {
    _syncCapture();
    setState(() {});
  }

  void _syncCapture() {
    if (CorextraDevTools.instance.enabled) {
      _startCapture();
    } else {
      _stopCapture();
    }
  }

  void _startCapture() {
    if (_capturing) return;
    _capturing = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _memoryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      CorextraDevTools.instance.performance.setRssBytes(currentRssBytes());
    });
  }

  void _stopCapture() {
    if (!_capturing) return;
    _capturing = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _memoryTimer?.cancel();
    _memoryTimer = null;
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    final store = CorextraDevTools.instance.performance;
    for (final timing in timings) {
      store.add(
        FrameSample(
          buildDuration: timing.buildDuration,
          rasterDuration: timing.rasterDuration,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _openPanel() => setState(() => _mode = _DisplayMode.open);

  void _closePanel() => setState(() => _mode = _DisplayMode.closed);

  void _minimizeToPip() => setState(() => _mode = _DisplayMode.pip);

  @override
  Widget build(BuildContext context) {
    if (!CorextraDevTools.instance.enabled) {
      return widget.child;
    }
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_mode == _DisplayMode.closed) DevToolsBubble(onTap: _openPanel),
          if (_mode == _DisplayMode.pip) DevToolsPipChip(onTap: _openPanel),
          if (_mode == _DisplayMode.open)
            _PanelHost(onClose: _closePanel, onMinimize: _minimizeToPip),
        ],
      ),
    );
  }
}

/// Hosts [DevToolsPanel] only while it's open.
///
/// Deliberately *not* kept mounted when closed: an `Overlay` claims
/// hit-testing across its entire bounds even where it paints nothing, so
/// an always-present, screen-sized `Overlay` here would silently absorb
/// every tap and scroll meant for the host app underneath, everywhere,
/// all the time — not just while the panel is actually visible.
class _PanelHost extends StatelessWidget {
  const _PanelHost({required this.onClose, required this.onMinimize});

  final VoidCallback onClose;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    // A concrete, finite size — not whatever loose/unbounded constraints
    // this widget happens to receive at its mount point — is what keeps
    // the panel's internal Row/Column/Expanded layout well-defined.
    final screenSize = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        // The DevTools panel gets its own theme — independent of the
        // host app's — via a Theme ancestor above the Overlay. Theme is
        // an InheritedWidget, so every Theme.of(context) call inside
        // re-subscribes to it directly and reacts live if the mode is
        // toggled.
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: CorextraDevTools.instance.themeModeNotifier,
          builder: (context, mode, _) => Theme(
            data: buildDevToolsTheme(
              mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
            ),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => DevToolsPanel(
                    onClose: onClose,
                    onMinimize: onMinimize,
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
