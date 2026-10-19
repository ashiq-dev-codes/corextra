import 'package:corextra/corextra.dart';
import 'package:corextra/devtools/find/find.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _currentMatchColor = Color(0xFFFF9632);

Widget _wrap({double width = 400, double height = 700}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: const DevToolsTabs()),
    ),
  );
}

void _log(String message, {LogLevel level = LogLevel.info}) {
  CorextraDevTools.instance.logs.add(
    LogEntry(message: message, level: level, timestamp: DateTime.now()),
  );
}

NetworkEvent _request(
  String url, {
  String method = 'GET',
  Object? responseBody,
  Map<String, String> requestHeaders = const {},
  Set<String> hiddenHeaderKeys = const {},
}) {
  final store = CorextraDevTools.instance.network;
  final event = store.begin(
    method: method,
    url: url,
    requestHeaders: requestHeaders,
    hiddenHeaderKeys: hiddenHeaderKeys,
  );
  event.statusCode = 200;
  event.responseBody = responseBody;
  event.completedAt = DateTime.now();
  store.complete(event);
  return event;
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  // Past the find bar's typing debounce.
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

String _counter(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('devtools-find-counter'))).data!;

/// How many highlighted pieces of plain [Text] are on screen in [color].
int _highlights(WidgetTester tester, Color color) {
  var count = 0;
  for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
    text.text.visitChildren((span) {
      if (span is TextSpan &&
          span.style?.backgroundColor == color &&
          (span.text?.isNotEmpty ?? false)) {
        count++;
      }
      return true;
    });
  }
  return count;
}

int _selectedTab(WidgetTester tester) =>
    tester.widget<TabBarView>(find.byType(TabBarView).first).controller!.index;

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  group('findMatches', () {
    test('is case-insensitive and does not overlap', () {
      expect(findMatches('Token token TOKEN', 'token'), [0, 6, 12]);
      expect(findMatches('aaaa', 'aa'), [0, 2]);
      expect(findMatches('nothing here', 'zzz'), isEmpty);
    });
  });

  group('DevToolsFind', () {
    late DevToolsFind find;

    setUp(() {
      find = DevToolsFind([
        FindSource(
          targets:
              () => const [FindTarget('a', 'apple pie'), FindTarget('b', 'x')],
        ),
        FindSource(targets: () => const [FindTarget('c', 'apple, apple')]),
      ]);
    });

    tearDown(() => find.dispose());

    test('counts every match in every tab, and steps through them in order, '
        'wrapping around', () async {
      find.search('apple');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(find.hits.length, 3);
      expect(find.countIn(0), 1);
      expect(find.countIn(1), 2);
      expect(find.position, 1);

      find.next();
      expect((find.current!.target.id, find.current!.occurrence), ('c', 0));
      find.next();
      expect((find.current!.target.id, find.current!.occurrence), ('c', 1));
      find.next();
      expect(find.position, 1);
      find.previous();
      expect(find.position, 3);
    });

    test('a fresh search starts from the tab on screen', () async {
      find.currentTab = 1;
      find.search('apple');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(find.current!.target.id, 'c');
    });

    test('clearing applies at once and drops every match', () async {
      find.search('apple');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      find.search('');

      expect(find.isActive, isFalse);
      expect(find.hits, isEmpty);
      expect(find.current, isNull);
    });
  });

  testWidgets('typing highlights every match like a browser, with a counter, '
      'and the first match in orange', (tester) async {
    _log('cache miss for avatar');
    _log('avatar uploaded');
    _log('unrelated');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();

    await _search(tester, 'avatar');

    expect(_counter(tester), '1/2');
    expect(_highlights(tester, findMatchColor), 1);
    expect(_highlights(tester, _currentMatchColor), 1);
  });

  testWidgets('Enter and the arrows step through matches across tabs, '
      'switching to whichever tab holds the current one', (tester) async {
    _request('https://example.test/profile');
    _log('loaded profile');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // The row's path, the full URL inside its detail, and the log.
    await _search(tester, 'profile');
    expect(_counter(tester), '1/3');
    expect(_selectedTab(tester), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_counter(tester), '2/3');
    expect(find.text('Request detail'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_counter(tester), '3/3');
    expect(_selectedTab(tester), 1);
    expect(find.text('loaded profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
    expect(_counter(tester), '1/3');
    expect(_selectedTab(tester), 0);

    await tester.tap(find.byTooltip('Previous match'));
    await tester.pumpAndSettle();
    expect(_counter(tester), '3/3');
    expect(_selectedTab(tester), 1);
  });

  testWidgets('each tab shows how many matches it holds', (tester) async {
    _request('https://example.test/token');
    _log('token refreshed');
    _log('token expired');
    _log('token revoked');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _search(tester, 'token');

    // Network: the row's path and the full URL. Logs: three entries.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('a match inside an unopened response body opens that request '
      'on its Response tab', (tester) async {
    _request(
      'https://example.test/user',
      responseBody: {'name': 'Ada', 'city': 'Needleton'},
    );
    _request('https://example.test/other', responseBody: {'x': 1});

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _search(tester, 'needleton');

    expect(_counter(tester), '1/1');
    expect(find.text('Request detail'), findsOneWidget);
    final detailTabs = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(detailTabs.index, 2);
    expect(find.textContaining('"Needleton"'), findsOneWidget);
  });

  testWidgets('a match folded away inside a collapsed JSON node unfolds it', (
    tester,
  ) async {
    _request(
      'https://example.test/user',
      responseBody: {
        'profile': {'nickname': 'zebra'},
      },
    );

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('/user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pumpAndSettle();
    expect(find.textContaining('"zebra"'), findsNothing);

    await _search(tester, 'zebra');

    expect(find.textContaining('"zebra"'), findsOneWidget);
  });

  testWidgets('a masked header is searched as shown, never by its real value', (
    tester,
  ) async {
    _request(
      'https://example.test/me',
      requestHeaders: {'Authorization': 'Bearer secret-value-1234'},
      hiddenHeaderKeys: {'authorization'},
    );

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _search(tester, 'secret');
    expect(_counter(tester), 'No results');

    await _search(tester, '1234');
    expect(_counter(tester), '1/1');
  });

  testWidgets('a match hidden by a level filter brings that level back', (
    tester,
  ) async {
    _log('failed to load avatar', level: LogLevel.error);
    _log('all good');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Error'));
    await tester.pumpAndSettle();
    expect(find.text('failed to load avatar'), findsNothing);

    await _search(tester, 'avatar');

    expect(find.text('failed to load avatar'), findsOneWidget);
  });

  testWidgets('a match far down a long list scrolls its row into view', (
    tester,
  ) async {
    for (var i = 0; i < 200; i++) {
      _log(i == 3 ? 'the needle entry' : 'entry #$i');
    }

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    // Newest first, so this one starts near the very bottom — far past what's built.
    expect(find.text('the needle entry'), findsNothing);

    await _search(tester, 'needle');

    expect(find.text('the needle entry').hitTestable(), findsOneWidget);
  });

  testWidgets('static text counts too, e.g. the Info tab\'s labels', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await _search(tester, 'capture buffers');

    expect(_counter(tester), '1/1');
    expect(_selectedTab(tester), 2);
  });

  testWidgets('the on-screen keyboard\'s search key jumps to the next match '
      'and closes the keyboard, so the match is visible', (tester) async {
    _log('avatar one');
    _log('avatar two');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _search(tester, 'avatar');
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(_counter(tester), '2/2');
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a hardware Enter steps but keeps typing focus, so repeated '
      'Enter keeps stepping', (tester) async {
    _log('avatar one');
    _log('avatar two');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _search(tester, 'avatar');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(_counter(tester), '2/2');
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('tapping anywhere outside the find bar closes the keyboard, '
      'while its own arrows don\'t', (tester) async {
    _log('avatar one');
    _log('avatar two');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _search(tester, 'avatar');

    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('avatar two'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    // Closing the keyboard keeps the search and its highlights.
    expect(_counter(tester), '2/2');
  });

  testWidgets('Escape clears the search and every highlight', (tester) async {
    _log('avatar uploaded');

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _search(tester, 'avatar');
    expect(_highlights(tester, _currentMatchColor), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('devtools-find-counter')), findsNothing);
    expect(_highlights(tester, findMatchColor), 0);
    expect(_highlights(tester, _currentMatchColor), 0);
  });
}
