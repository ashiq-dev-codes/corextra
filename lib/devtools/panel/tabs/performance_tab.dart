import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/frame_sample.dart';
import '../empty_state.dart';

/// Live FPS/jank monitor built from `CorextraDevTools.instance.performance`.
class PerformanceTab extends StatelessWidget {
  const PerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CorextraDevTools.instance.performance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final samples = store.samples;
        final fps = store.currentFps;
        final janky = store.recentJankyCount();
        final rss = store.lastRssBytes;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fps.toStringAsFixed(0)} FPS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: fps >= 55
                          ? Colors.green
                          : (fps >= 30 ? Colors.orange : Colors.red),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('$janky janky frames (last 60)'),
                ],
              ),
              const SizedBox(height: 4),
              if (rss != null)
                Text(
                  'Memory (RSS): ${(rss / (1024 * 1024)).toStringAsFixed(1)} MB',
                ),
              const SizedBox(height: 16),
              Expanded(
                child: samples.isEmpty
                    ? const DevToolsEmptyState(
                        icon: LucideIcons.gauge,
                        message: 'Waiting for frames…',
                        hint: 'Interact with the app to generate frame '
                            'timing data.',
                      )
                    : CustomPaint(
                        size: Size.infinite,
                        painter: _FrameBarsPainter(samples: samples),
                      ),
              ),
              if (samples.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _Legend(color: Colors.green, label: 'Smooth frame'),
                    SizedBox(width: 16),
                    _Legend(color: Colors.red, label: 'Janky frame'),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FrameBarsPainter extends CustomPainter {
  _FrameBarsPainter({required this.samples});

  final List<FrameSample> samples;

  static const _budgetMicros = 33400; // ~2x 60fps budget, for scaling bars

  @override
  void paint(Canvas canvas, Size size) {
    final visible = samples.length > 100
        ? samples.sublist(samples.length - 100)
        : samples;
    if (visible.isEmpty) return;
    final barWidth = size.width / visible.length;
    for (var i = 0; i < visible.length; i++) {
      final sample = visible[i];
      final heightFraction = (sample.totalDuration.inMicroseconds /
              _budgetMicros)
          .clamp(0.05, 1.0);
      final barHeight = size.height * heightFraction;
      final paint = Paint()
        ..color = sample.isJanky ? Colors.red : Colors.green;
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - barHeight,
          barWidth * 0.8,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrameBarsPainter oldDelegate) => true;
}
