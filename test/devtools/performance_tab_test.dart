import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap() {
  return const MaterialApp(home: Scaffold(body: PerformanceTab()));
}

void _seedTwoSamples() {
  final store = CorextraDevTools.instance.performance;
  // Not janky: 5ms build + 3ms raster = 8ms, under the 16.7ms budget.
  store.add(
    FrameSample(
      buildDuration: const Duration(milliseconds: 5),
      rasterDuration: const Duration(milliseconds: 3),
      timestamp: DateTime.now(),
    ),
  );
  // Janky: 20ms build + 10ms raster = 30ms, over budget. Added last, so
  // it's the "latest frame" shown by default.
  store.add(
    FrameSample(
      buildDuration: const Duration(milliseconds: 20),
      rasterDuration: const Duration(milliseconds: 10),
      timestamp: DateTime.now(),
    ),
  );
}

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  testWidgets('shows an empty state when no frames have been captured', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Waiting for frames…'), findsOneWidget);
  });

  testWidgets(
    "shows FPS/frame-time/jank stats and the latest frame's detail once "
    'frames arrive',
    (tester) async {
      _seedTwoSamples();

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('FPS'), findsOneWidget);
      expect(find.text('Frame time'), findsOneWidget);
      expect(find.text('Janky frames'), findsOneWidget);
      // One of the two seeded frames is janky.
      expect(find.text('1 / 2'), findsOneWidget);

      // The latest frame (the janky 30ms one) is shown by default.
      expect(find.text('Latest frame'), findsOneWidget);
      expect(find.text('UI 20.0 ms'), findsOneWidget);
      expect(find.text('Raster 10.0 ms'), findsOneWidget);
      expect(find.text('Total 30.0 ms'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the frame chart selects a specific frame and updates the '
    'detail line to match it',
    (tester) async {
      _seedTwoSamples();

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final chartFinder = find.byKey(const Key('performance-frame-chart'));
      final topLeft = tester.getTopLeft(chartFinder);
      final size = tester.getSize(chartFinder);
      // The leftmost bar is the first (non-janky) seeded frame.
      await tester.tapAt(topLeft + Offset(2, size.height / 2));
      await tester.pumpAndSettle();

      expect(find.text('Selected frame'), findsOneWidget);
      expect(find.text('UI 5.0 ms'), findsOneWidget);
      expect(find.text('Raster 3.0 ms'), findsOneWidget);
      expect(find.text('Total 8.0 ms'), findsOneWidget);
    },
  );

  testWidgets(
    'renders without overflowing at the PiP window\'s minimum tab-content '
    'area (280×239, after its header/tab bar), with memory shown too',
    (tester) async {
      _seedTwoSamples();
      CorextraDevTools.instance.performance.setRssBytes(52428800);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 239,
              child: PerformanceTab(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Memory (RSS)'), findsOneWidget);
    },
  );
}
