import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _seedThreeEntries() {
  final store = CorextraDevTools.instance.logs;
  store.add(
    LogEntry(
      message: 'user signed in',
      level: LogLevel.info,
      timestamp: DateTime.now(),
    ),
  );
  store.add(
    LogEntry(
      message: 'cache miss for profile',
      level: LogLevel.warning,
      timestamp: DateTime.now(),
    ),
  );
  store.add(
    LogEntry(
      message: 'failed to load avatar',
      level: LogLevel.error,
      timestamp: DateTime.now(),
    ),
  );
}

Widget _wrap() {
  return const MaterialApp(
    home: Scaffold(body: LogsTab()),
  );
}

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  testWidgets('renders every captured entry by default', (tester) async {
    _seedThreeEntries();

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('user signed in'), findsOneWidget);
    expect(find.text('cache miss for profile'), findsOneWidget);
    expect(find.text('failed to load avatar'), findsOneWidget);
  });

  testWidgets(
    'the search box filters entries by message, and clearing it '
    'restores the full list',
    (tester) async {
      _seedThreeEntries();

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'avatar');
      await tester.pumpAndSettle();

      expect(find.text('user signed in'), findsNothing);
      expect(find.text('cache miss for profile'), findsNothing);
      expect(find.text('failed to load avatar'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('user signed in'), findsOneWidget);
      expect(find.text('cache miss for profile'), findsOneWidget);
      expect(find.text('failed to load avatar'), findsOneWidget);
    },
  );

  testWidgets(
    'deselecting a level chip hides entries at that level',
    (tester) async {
      _seedThreeEntries();

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Error'));
      await tester.pumpAndSettle();

      expect(find.text('failed to load avatar'), findsNothing);
      expect(find.text('user signed in'), findsOneWidget);
      expect(find.text('cache miss for profile'), findsOneWidget);
    },
  );

  testWidgets(
    'a search or filter combination with no matches shows an empty '
    'state instead of an empty list',
    (tester) async {
      _seedThreeEntries();

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nothing-matches-this');
      await tester.pumpAndSettle();

      expect(find.text('user signed in'), findsNothing);
      expect(find.textContaining('No logs match'), findsOneWidget);
    },
  );
}
