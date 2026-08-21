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

/// Opens a filter dropdown (matched by its label, e.g. `'Method'`) and
/// leaves it open — closing and reopening the same popup between taps
/// proved flaky under the test harness (the popup's re-layout on reopen
/// could momentarily land a tap on the wrong element), so tests instead
/// open a dropdown once and make every toggle they need while it stays
/// open, closing it (via Escape, not by tapping the trigger again) only
/// if they also need to reach something outside the popup, like the
/// "Reset" button.
Future<void> _openFilterMenu(WidgetTester tester, String buttonLabel) async {
  await tester.tap(find.text(buttonLabel));
  await tester.pumpAndSettle();
}

/// Taps an option inside an already-open filter dropdown, found by its
/// label-derived `Key` — not by its text, which can also appear as a
/// method pill on an already-visible row underneath the open popup.
Future<void> _tapFilterOption(
  WidgetTester tester,
  String buttonLabel,
  String optionLabel,
) async {
  await tester.tap(find.byKey(ValueKey('filter-option-$buttonLabel-$optionLabel')));
  await tester.pumpAndSettle();
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

  testWidgets(
    'the search box filters requests by URL, hiding non-matching rows',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'todos/1');
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.textContaining('/todos/1'), findsOneWidget);
    },
  );

  testWidgets(
    'the search box also matches on status code, and clearing it '
    'restores the full list',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '500');
      await tester.pumpAndSettle();

      // The single remaining row should be the 500 one, not the 200 —
      // visible on its collapsed status label already, no need to
      // expand it.
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ExpansionTile),
          matching: find.text('500'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('/todos/1'), findsNothing);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsNWidgets(2));
    },
  );

  testWidgets(
    'a search with no matches shows an empty state instead of an empty '
    'list',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nothing-matches-this');
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.textContaining('No requests match'), findsOneWidget);
    },
  );

  testWidgets(
    'deselecting a method in the Method filter dropdown hides requests '
    'with that method, and re-selecting it restores the full list',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNWidgets(2));
      expect(find.text('Method'), findsOneWidget);
      // Both the Method and Status buttons show "All" by default.
      expect(find.text('All'), findsNWidgets(2));

      await _openFilterMenu(tester, 'Method');
      await _tapFilterOption(tester, 'Method', 'GET');

      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.textContaining('/todos/1'), findsNothing);
      expect(find.textContaining('/todos'), findsOneWidget);
      // The Method button's summary reflects the narrowed selection;
      // the Status button is untouched and still shows "All".
      expect(find.text('5 selected'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);

      // Re-selecting it (the dropdown is still open) restores the full
      // list.
      await _tapFilterOption(tester, 'Method', 'GET');

      expect(find.byType(ExpansionTile), findsNWidgets(2));
      expect(find.text('All'), findsNWidgets(2));
    },
  );

  testWidgets(
    'a "Reset" action appears once a filter narrows the list, and '
    'restores everything in one tap',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsNothing);

      // Search text alone is enough to make "Reset" appear — no need
      // to open a filter dropdown (and thus no risk of the popup still
      // being open, and absorbing the tap meant for "Reset" below) to
      // exercise the same onReset wiring the dropdowns also use.
      await tester.enterText(find.byType(TextField), 'todos/1');
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // The filter row scrolls horizontally at narrow widths, so
      // "Reset" (rightmost) may start out past the visible edge.
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsNWidgets(2));
      expect(find.text('Reset'), findsNothing);
      expect(find.text('All'), findsNWidgets(2));
    },
  );

  testWidgets(
    'deselecting a status in the Status filter dropdown hides requests '
    'in that category, and deselecting every active category shows '
    'the "no matches" empty state',
    (tester) async {
      _seedTwoEvents();

      await tester.pumpWidget(_wrap(400));
      await tester.pumpAndSettle();

      await _openFilterMenu(tester, 'Status');
      await _tapFilterOption(tester, 'Status', 'Success');

      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.textContaining('/todos/1'), findsNothing);

      // The dropdown is still open — deselect the remaining category
      // too, without reopening.
      await _tapFilterOption(tester, 'Status', 'Server Error');

      expect(find.byType(ExpansionTile), findsNothing);
      expect(
        find.text('No requests match the selected filters'),
        findsOneWidget,
      );
    },
  );
}
