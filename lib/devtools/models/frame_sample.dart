/// One frame's build + raster timing, used to derive FPS/jank in the
/// DevTools Performance tab.
class FrameSample {
  const FrameSample({
    required this.buildDuration,
    required this.rasterDuration,
    required this.timestamp,
  });

  final Duration buildDuration;
  final Duration rasterDuration;
  final DateTime timestamp;

  static const _frameBudget = Duration(microseconds: 16700); // ~60fps

  Duration get totalDuration => buildDuration + rasterDuration;

  /// Approximate instantaneous FPS implied by this single frame's total
  /// duration, clamped to a sane display range.
  double get fps {
    final micros = totalDuration.inMicroseconds;
    if (micros <= 0) return 60;
    return (1000000 / micros).clamp(0, 120);
  }

  bool get isJanky => totalDuration > _frameBudget;
}
