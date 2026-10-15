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
  return const MaterialApp(home: Scaffold(body: LogsTab()));
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

  testWidgets('a burst of new entries all show up, refreshed in batches '
      'rather than once per entry', (tester) async {
    _seedThreeEntries();
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final store = CorextraDevTools.instance.logs;
    for (var i = 0; i < 100; i++) {
      store.add(
        LogEntry(
          message: 'burst #$i',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Newest first: the last entry of the burst is at the top.
    expect(find.text('burst #99'), findsOneWidget);
  });

  testWidgets('a long list gets an edge scrollbar that scrolls it when '
      'dragged; a short one shows none', (tester) async {
    _seedThreeEntries();
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    final thumb = find.byKey(const ValueKey('list-scrollbar-thumb-vertical'));
    expect(thumb, findsNothing);

    final store = CorextraDevTools.instance.logs;
    for (var i = 0; i < 200; i++) {
      store.add(
        LogEntry(
          message: 'entry #$i',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(thumb, findsOneWidget);

    final list = tester.getRect(find.byType(ListView));
    await tester.dragFrom(
      list.topRight + const Offset(-8, 40),
      const Offset(0, 200),
    );
    await tester.pumpAndSettle();

    final position =
        tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              ),
            )
            .position;
    expect(position.pixels, greaterThan(0));
  });

  testWidgets('deselecting a level chip hides entries at that level', (
    tester,
  ) async {
    _seedThreeEntries();

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Error'));
    await tester.pumpAndSettle();

    expect(find.text('failed to load avatar'), findsNothing);
    expect(find.text('user signed in'), findsOneWidget);
    expect(find.text('cache miss for profile'), findsOneWidget);
  });

  testWidgets('deselecting every level shows an empty state instead of an '
      'empty list', (tester) async {
    _seedThreeEntries();

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    for (final level in ['Info', 'Warning', 'Error']) {
      await tester.tap(find.widgetWithText(FilterChip, level));
      await tester.pumpAndSettle();
    }

    expect(find.text('user signed in'), findsNothing);
    expect(find.text('No logs match the selected levels'), findsOneWidget);
  });

  testWidgets('with a long list, scrolling down reveals a scroll-to-top button '
      'that jumps back to the first entry', (tester) async {
    final store = CorextraDevTools.instance.logs;
    for (var i = 0; i < 60; i++) {
      store.add(
        LogEntry(
          message: 'entry #$i',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        ),
      );
    }

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Newest-first: entry #59 (added last) starts at the top.
    expect(find.text('entry #59'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('entry #59'), findsNothing);

    await tester.tap(find.byTooltip('Scroll to top'));
    await tester.pumpAndSettle();

    expect(find.text('entry #59'), findsOneWidget);
  });
}
