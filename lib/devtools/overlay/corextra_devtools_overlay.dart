import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../devtools_controller.dart';
import '../models/frame_sample.dart';
import '../panel/devtools_panel.dart';
import '../util/devtools_theme.dart';
import '../util/memory_probe.dart';
import 'devtools_bubble.dart';

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
/// The bubble and panel run inside their own, self-contained [Navigator]
/// sized explicitly to the screen. That gives Material widgets that need
/// an ancestor `Overlay` (tooltips, popup menus) somewhere to attach, and
/// guarantees the panel always lays out against a concrete, finite size
/// — regardless of where this widget sits relative to the host app's own
/// Navigator (mounting it *above* that Navigator, as `MaterialApp.builder`
/// does, otherwise leaves it with neither).
class CorextraDevToolsOverlay extends StatefulWidget {
  const CorextraDevToolsOverlay({super.key, required this.child, this.enabled});

  final Widget child;
  final bool? enabled;

  @override
  State<CorextraDevToolsOverlay> createState() =>
      _CorextraDevToolsOverlayState();
}

class _CorextraDevToolsOverlayState extends State<CorextraDevToolsOverlay> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
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

  void _openPanel() {
    _navigatorKey.currentState?.push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => DevToolsPanel(onClose: _closePanel),
      ),
    );
  }

  void _closePanel() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!CorextraDevTools.instance.enabled) {
      return widget.child;
    }
    // A concrete, finite size — not whatever loose/unbounded constraints
    // this widget happens to receive at its mount point — is what keeps
    // the panel's internal Row/Column/Expanded layout well-defined.
    final screenSize = MediaQuery.sizeOf(context);
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            // The DevTools panel gets its own theme — independent of the
            // host app's — via a Theme ancestor sitting above the whole
            // Navigator. That way it applies to every route (bubble and
            // panel alike) and reacts live if the mode is toggled, since
            // Theme is an InheritedWidget that every Theme.of(context)
            // call inside re-subscribes to regardless of Navigator route
            // boundaries.
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: CorextraDevTools.instance.themeModeNotifier,
              builder: (context, mode, _) => Theme(
                data: buildDevToolsTheme(
                  mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                ),
                // A small, self-contained Navigator: gives tooltips/popup
                // menus an Overlay to attach to, and drives "open"/"close"
                // via real route push/pop instead of a rebuilt closure, so
                // Flutter's normal navigation machinery guarantees the
                // panel actually updates when its state changes.
                child: Navigator(
                  key: _navigatorKey,
                  onGenerateRoute: (_) => PageRouteBuilder<void>(
                    opaque: false,
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (context, _, _) =>
                        Stack(children: [DevToolsBubble(onTap: _openPanel)]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
