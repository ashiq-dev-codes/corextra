import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/frame_sample.dart';
import '../empty_state.dart';
import '../scroll_to_top_fab.dart';

const _uiColor = Colors.blue;
const _rasterColor = Colors.deepPurpleAccent;

/// Live FPS/jank monitor built from `CorextraDevTools.instance.performance`
/// — modeled on Flutter DevTools' own Performance view (a scrolling frame
/// timeline split into UI/build time vs Raster/GPU time, with a 60 FPS
/// budget line and jank highlighted), scaled down to what's derivable
/// without a VM Service connection: per-frame build/raster durations from
/// `SchedulerBinding`, nothing from the engine's own trace events.
class PerformanceTab extends StatefulWidget {
  const PerformanceTab({super.key});

  @override
  State<PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends State<PerformanceTab> {
  int? _selectedIndex;

  void _selectAt(Offset localPosition, double width, int sampleCount) {
    if (sampleCount == 0) return;
    final barWidth = width / sampleCount;
    final index = (localPosition.dx / barWidth).floor().clamp(
      0,
      sampleCount - 1,
    );
    if (index != _selectedIndex) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CorextraDevTools.instance.performance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final samples = store.samples;
        if (samples.isEmpty) {
          return const DevToolsEmptyState(
            icon: LucideIcons.gauge,
            message: 'Waiting for frames…',
            hint: 'Interact with the app to generate frame timing data.',
          );
        }

        final visible =
            samples.length > 100
                ? samples.sublist(samples.length - 100)
                : samples;
        final fps = store.currentFps;
        final jankyCount = store.recentJankyCount();
        final rss = store.lastRssBytes;
        final avgBuildMs = _averageMs(visible.map((s) => s.buildDuration));
        final avgRasterMs = _averageMs(visible.map((s) => s.rasterDuration));

        final selectedIndex =
            (_selectedIndex != null && _selectedIndex! < visible.length)
                ? _selectedIndex!
                : visible.length - 1;
        final selected = visible[selectedIndex];

        // The PiP window's minimum size (280×360, most of it taken by
        // its header and tab bar) leaves too little height for every
        // section below plus a fixed-size chart to fit without
        // scrolling — so the whole tab scrolls, and the chart's height
        // scales with whatever room is actually available rather than
        // assuming a full-screen panel's worth of space.
        return LayoutBuilder(
          builder: (context, viewport) {
            final chartHeight = (viewport.maxHeight * 0.4).clamp(120.0, 260.0);
            return DevToolsScrollToTop(
              builder:
                  (context, controller) => SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatCard(
                              icon: LucideIcons.gauge,
                              label: 'FPS',
                              value: fps.toStringAsFixed(0),
                              valueColor: _fpsColor(fps),
                              caption: _fpsLabel(fps),
                            ),
                            _StatCard(
                              icon: LucideIcons.timer,
                              label: 'Frame time',
                              value:
                                  '${(avgBuildMs + avgRasterMs).toStringAsFixed(1)} ms',
                            ),
                            _StatCard(
                              icon: LucideIcons.triangleAlert,
                              label: 'Janky frames',
                              value: '$jankyCount / ${visible.length}',
                              valueColor:
                                  jankyCount == 0 ? Colors.green : Colors.red,
                            ),
                            if (rss != null)
                              _StatCard(
                                icon: LucideIcons.memoryStick,
                                label: 'Memory (RSS)',
                                value:
                                    '${(rss / (1024 * 1024)).toStringAsFixed(1)} MB',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ThreadSplitBar(
                          buildMs: avgBuildMs,
                          rasterMs: avgRasterMs,
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Frame times',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const _Legend(color: _uiColor, label: 'UI'),
                            const _Legend(color: _rasterColor, label: 'Raster'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap or drag the chart to inspect a frame. Frames past '
                          'the dashed 16.7 ms (60 FPS) line are janky.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: chartHeight,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                              void handle(Offset local) =>
                                  _selectAt(local, size.width, visible.length);
                              return GestureDetector(
                                onTapDown:
                                    (details) => handle(details.localPosition),
                                onPanUpdate:
                                    (details) => handle(details.localPosition),
                                child: CustomPaint(
                                  key: const Key('performance-frame-chart'),
                                  size: size,
                                  painter: _FrameTimelinePainter(
                                    samples: visible,
                                    selectedIndex: selectedIndex,
                                    gridColor: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SelectedFrameDetail(
                          sample: selected,
                          isPinned: _selectedIndex != null,
                        ),
                      ],
                    ),
                  ),
            );
          },
        );
      },
    );
  }
}

double _averageMs(Iterable<Duration> durations) {
  var totalMicros = 0;
  var count = 0;
  for (final d in durations) {
    totalMicros += d.inMicroseconds;
    count++;
  }
  if (count == 0) return 0;
  return (totalMicros / count) / 1000;
}

Color _fpsColor(double fps) {
  if (fps >= 55) return Colors.green;
  if (fps >= 30) return Colors.orange;
  return Colors.red;
}

String _fpsLabel(double fps) {
  if (fps >= 55) return 'Smooth';
  if (fps >= 30) return 'Some jank';
  return 'Frequent jank';
}

/// A small stat tile — icon, big value (optionally colored), label, and
/// an optional qualitative caption (e.g. "Smooth") below the value.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: mutedColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(width: 6),
                Text(
                  caption!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: valueColor ?? mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A thin two-segment bar showing, on average over the visible window,
/// how much of each frame's time goes to UI (build) work versus Raster
/// (GPU) work — a quick way to tell whether jank is more likely coming
/// from app logic or from rendering, without needing a CPU profiler.
class _ThreadSplitBar extends StatelessWidget {
  const _ThreadSplitBar({required this.buildMs, required this.rasterMs});

  final double buildMs;
  final double rasterMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = buildMs + rasterMs;
    final buildFraction = total <= 0 ? 0.5 : buildMs / total;
    final buildPercent = (buildFraction * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (buildFraction * 1000).round().clamp(1, 999),
                  child: Container(color: _uiColor),
                ),
                Expanded(
                  flex: ((1 - buildFraction) * 1000).round().clamp(1, 999),
                  child: Container(color: _rasterColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'On average, UI work takes $buildPercent% of each frame, '
          'Raster the rest.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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

/// The frame currently under the user's finger/cursor (or the latest
/// frame, if none has been picked yet) — build/raster/total broken out
/// individually, matching what selecting a frame shows in Flutter
/// DevTools' own Performance view.
class _SelectedFrameDetail extends StatelessWidget {
  const _SelectedFrameDetail({required this.sample, required this.isPinned});

  final FrameSample sample;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final buildMs = sample.buildDuration.inMicroseconds / 1000;
    final rasterMs = sample.rasterDuration.inMicroseconds / 1000;
    final totalMs = buildMs + rasterMs;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          sample.isJanky ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
          size: 14,
          color: sample.isJanky ? Colors.red : Colors.green,
        ),
        Text(
          isPinned ? 'Selected frame' : 'Latest frame',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: mutedColor,
          ),
        ),
        Text(
          'UI ${buildMs.toStringAsFixed(1)} ms',
          style: const TextStyle(color: _uiColor, fontSize: 12.5),
        ),
        Text(
          'Raster ${rasterMs.toStringAsFixed(1)} ms',
          style: const TextStyle(color: _rasterColor, fontSize: 12.5),
        ),
        Text(
          'Total ${totalMs.toStringAsFixed(1)} ms',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Draws each visible frame as a stacked bar (UI time, then Raster time
/// on top of it) against a dashed 60 FPS budget line, capped at 2x that
/// budget so a single outlier can't flatten the rest of the chart.
/// Janky frames get a small red cap; the selected frame gets a subtle
/// highlight column behind it.
class _FrameTimelinePainter extends CustomPainter {
  _FrameTimelinePainter({
    required this.samples,
    required this.selectedIndex,
    required this.gridColor,
  });

  final List<FrameSample> samples;
  final int selectedIndex;
  final Color gridColor;

  static const _chartBudgetMicros = 33400; // 2x the 60fps budget
  static const _targetBudgetMicros = 16700;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final barWidth = size.width / samples.length;

    final budgetY =
        size.height - size.height * (_targetBudgetMicros / _chartBudgetMicros);
    _drawDashedLine(
      canvas,
      budgetY,
      size.width,
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );

    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final x = i * barWidth;
      final barW = barWidth * 0.72;
      final totalMicros = sample.totalDuration.inMicroseconds;
      if (totalMicros <= 0) continue;

      final totalFraction = (totalMicros / _chartBudgetMicros).clamp(0.05, 1.0);
      final totalBarHeight = size.height * totalFraction;
      final buildShare = sample.buildDuration.inMicroseconds / totalMicros;
      final buildHeight = totalBarHeight * buildShare;
      final rasterHeight = totalBarHeight - buildHeight;

      if (i == selectedIndex) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          Paint()..color = Colors.white.withValues(alpha: 0.08),
        );
      }

      canvas.drawRect(
        Rect.fromLTWH(x, size.height - buildHeight, barW, buildHeight),
        Paint()..color = _uiColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - totalBarHeight, barW, rasterHeight),
        Paint()..color = _rasterColor,
      );

      if (sample.isJanky) {
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - totalBarHeight - 3, barW, 3),
          Paint()..color = Colors.red,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, double y, double width, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _FrameTimelinePainter oldDelegate) => true;
}
