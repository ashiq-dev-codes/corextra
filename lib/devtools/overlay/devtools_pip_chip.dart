import 'package:corextra/logs/enum/log_level.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../devtools_controller.dart';
import 'draggable_floating_widget.dart';

/// A small, draggable floating status chip shown in place of
/// [DraggableFloatingWidget]'s usual bubble while the DevTools panel is
/// minimized — a compact, live-updating summary (FPS, request count,
/// outstanding issues) so a developer can keep an eye on what's
/// happening while still freely interacting with the app underneath.
/// Tapping it reopens the full panel.
class DevToolsPipChip extends StatelessWidget {
  const DevToolsPipChip({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _width = 172.0;
  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    return DraggableFloatingWidget(
      size: const Size(_width, _height),
      child: Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _PipStats(),
          ),
        ),
      ),
    );
  }
}

class _PipStats extends StatelessWidget {
  const _PipStats();

  @override
  Widget build(BuildContext context) {
    final devtools = CorextraDevTools.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        devtools.network,
        devtools.logs,
        devtools.performance,
      ]),
      builder: (context, _) {
        final fps = devtools.performance.currentFps;
        final fpsColor = fps >= 55
            ? Colors.greenAccent
            : (fps >= 30 ? Colors.orangeAccent : Colors.redAccent);
        final requestCount = devtools.network.events.length;
        final issues =
            devtools.network.events.where((e) => e.isError).length +
            devtools.logs.entries
                .where((e) => e.level != LogLevel.info)
                .length;

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.activity, size: 12, color: fpsColor),
              const SizedBox(width: 4),
              Text(
                fps.toStringAsFixed(0),
                style: TextStyle(
                  color: fpsColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const _Divider(),
              const Icon(LucideIcons.network, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '$requestCount',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (issues > 0) ...[
                const _Divider(),
                const Icon(
                  LucideIcons.triangleAlert,
                  size: 12,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  '$issues',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(width: 1, height: 12, child: ColoredBox(color: Colors.white24)),
    );
  }
}
