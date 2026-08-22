import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap() {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 400,
        child: DevToolsScrollToTop(
          builder: (context, controller) => ListView.builder(
            controller: controller,
            itemCount: 100,
            itemExtent: 50,
            itemBuilder: (context, index) => Text('Item $index'),
          ),
        ),
      ),
    ),
  );
}

double _opacityOf(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.byKey(const Key('devtools-scroll-to-top-opacity')),
    )
    .opacity;

bool _ignoringOf(WidgetTester tester) => tester
    .widget<IgnorePointer>(
      find.byKey(const Key('devtools-scroll-to-top-ignore-pointer')),
    )
    .ignoring;

void main() {
  testWidgets(
    'the button starts hidden and non-interactive before any scrolling',
    (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(_opacityOf(tester), 0);
      expect(_ignoringOf(tester), isTrue);
    },
  );

  testWidgets(
    'scrolling down past the threshold reveals the button, and '
    'scrolling back up hides it again',
    (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(_opacityOf(tester), 1);
      expect(_ignoringOf(tester), isFalse);

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(_opacityOf(tester), 0);
      expect(_ignoringOf(tester), isTrue);
    },
  );

  testWidgets('tapping the button animates the scroll position back to the top', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Item 0'), findsNothing);

    await tester.tap(find.byTooltip('Scroll to top'));
    await tester.pumpAndSettle();

    expect(find.text('Item 0'), findsOneWidget);
    expect(_opacityOf(tester), 0);
  });
}
