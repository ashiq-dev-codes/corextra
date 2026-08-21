import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _seedTwoEvents() {
  final store = CorextraDevTools.instance.network;

  final first = store.begin(method: 'GET', url: 'https://example.test/todos/1');
  first.statusCode = 200;
  first.responseBody = '{"id":1}';
  first.completedAt = DateTime.now();
  store.complete(first);

  final second = store.begin(method: 'POST', url: 'https://example.test/todos');
  second.statusCode = 500;
  second.errorType = 'badResponse';
  second.errorMessage = 'Internal Server Error';
  second.completedAt = DateTime.now();
  store.complete(second);
}

Widget _wrap(double width) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: 600, child: const NetworkTab()),
    ),
  );
}

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  testWidgets(
    'on a narrow width, renders a single expandable list (no split)',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsNWidgets(2));
      expect(find.text('Requests'), findsNothing);
    },
  );

  testWidgets(
    'on a wide width, splits into a list and a detail pane; tapping a '
    'row shows its detail on the right',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(900));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('(2)'), findsOneWidget);
      expect(find.text('Select a request to see its details'), findsOneWidget);

      await tester.tap(find.text('/todos/1'));
      await tester.pumpAndSettle();

      expect(find.text('Select a request to see its details'), findsNothing);
      expect(find.textContaining('https://example.test/todos/1'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      expect(find.text('Response'), findsOneWidget);

      // Switching selection updates the detail pane.
      await tester.tap(find.text('/todos'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('https://example.test/todos/1'),
        findsNothing,
      );
      expect(find.text('Internal Server Error'), findsOneWidget);
    },
  );
}
