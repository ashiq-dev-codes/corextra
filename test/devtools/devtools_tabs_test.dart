import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrap() {
  return const MaterialApp(home: Scaffold(body: DevToolsTabs()));
}

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  testWidgets('tapping a tab label switches to that tab\'s content', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('No requests captured yet'), findsOneWidget);

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();

    expect(find.text('No requests captured yet'), findsNothing);
    expect(find.textContaining('No log'), findsOneWidget);
  });

  testWidgets(
    "dragging horizontally across a tab's content does not switch tabs — "
    'only tapping a tab label does, so scrolling a list diagonally can '
    "never accidentally swipe to a different tab",
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('No requests captured yet'), findsOneWidget);

      await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('No requests captured yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Performance is hidden behind the "More" button, not shown as a '
    'primary tab',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Performance'), findsNothing);
      expect(find.byTooltip('More'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping "More" then a secondary item switches to that tab and shows '
    'its icon on the More button in place of the generic ellipsis',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.text('Performance'), findsOneWidget);

      await tester.tap(find.text('Performance'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    },
  );
}
