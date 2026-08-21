import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrameSample', () {
    test('a 16ms frame is within budget and close to 60fps', () {
      final sample = FrameSample(
        buildDuration: const Duration(milliseconds: 8),
        rasterDuration: const Duration(milliseconds: 8),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(sample.isJanky, isFalse);
      expect(sample.fps, closeTo(60, 5));
    });

    test('a 33ms frame is janky and close to 30fps', () {
      final sample = FrameSample(
        buildDuration: const Duration(milliseconds: 20),
        rasterDuration: const Duration(milliseconds: 13),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(sample.isJanky, isTrue);
      expect(sample.fps, closeTo(30, 3));
    });
  });
}
