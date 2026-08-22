import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  setUp(() => CorextraDevTools.instance.resetAll());

  tearDown(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.themeMode = ThemeMode.dark;
    CorextraDevTools.instance.resetAll();
  });

  testWidgets('enabled: false renders only the child, no bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CorextraDevToolsOverlay(enabled: false, child: Text('host app')),
      ),
    );

    expect(find.text('host app'), findsOneWidget);
    expect(find.byType(DevToolsBubble), findsNothing);
  });

  testWidgets(
    'enabled: true shows the bubble; tapping opens and closes the panel',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: Text('host app'),
          ),
        ),
      );

      expect(find.text('host app'), findsOneWidget);
      expect(find.byType(DevToolsBubble), findsOneWidget);
      expect(find.byType(DevToolsPanel), findsNothing);

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      expect(find.byType(DevToolsPanel), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DevToolsPanel), findsNothing);
    },
  );

  testWidgets('Logs tab renders a seeded log entry', (tester) async {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.logs.add(
      LogEntry(
        message: 'hello from test',
        level: LogLevel.info,
        timestamp: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CorextraDevToolsOverlay(
          enabled: true,
          child: SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byType(DevToolsBubble));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hello from test'), findsOneWidget);
  });

  testWidgets(
    'DevTools theme defaults to dark and toggles independently of the '
    "host app's own theme",
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(CorextraDevTools.instance.themeMode, ThemeMode.dark);

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();

      Brightness panelBrightness() =>
          Theme.of(tester.element(find.byType(DevToolsPanel))).brightness;

      expect(panelBrightness(), Brightness.dark);

      await tester.tap(find.byTooltip('Switch to light theme'));
      await tester.pumpAndSettle();

      expect(CorextraDevTools.instance.themeMode, ThemeMode.light);
      expect(panelBrightness(), Brightness.light);
    },
  );

  testWidgets(
    'works when mounted via MaterialApp.builder — the documented usage, '
    'where the host app has its own Navigator (and HeroController) '
    'alongside this widget, unlike the home: placement used above',
    (tester) async {
      var hostButtonTapped = false;
      // The Network tab's filter bar (and MenuAnchor dropdowns within
      // it, checked below) only renders once there's at least one
      // captured request — otherwise the tab shows its empty state.
      CorextraDevTools.instance.network.begin(
        method: 'GET',
        url: 'https://example.test',
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => hostButtonTapped = true,
              child: const Text('host button'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('host button'), findsOneWidget);
      expect(find.byType(DevToolsBubble), findsOneWidget);

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      expect(find.byType(DevToolsPanel), findsOneWidget);

      // The Network tab's filter dropdowns are built on MenuAnchor
      // specifically because it inserts into the nearest Overlay
      // directly, unlike showMenu/showDialog/PopupMenuButton, which all
      // require a Navigator — and this mounting style is exactly the
      // case where CorextraDevToolsOverlay sits with no Navigator above
      // it at all (only its own local Overlay). Confirm the dropdown
      // still opens here, not just when placed at `home:` directly
      // under a Navigator.
      expect(find.text('Method'), findsOneWidget);
      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();
      expect(find.text('GET'), findsWidgets);
      // Close it again (tapping the same trigger) before moving on.
      await tester.tap(find.text('Method'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DevToolsPanel), findsNothing);

      // The host app underneath must still be interactive after the
      // panel closes.
      await tester.tap(find.text('host button'));
      await tester.pump();
      expect(hostButtonTapped, isTrue);
    },
  );

  testWidgets(
    'Minimize shows a floating window with the same tab content as the '
    'full panel; Expand restores the panel; Close (not Minimize) goes '
    'back to the bubble',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      expect(find.byType(DevToolsPanel), findsOneWidget);

      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      expect(find.byType(DevToolsPanel), findsNothing);
      expect(find.byType(DevToolsBubble), findsNothing);
      expect(find.byType(DevToolsFloatingWindow), findsOneWidget);
      // Real tab content, not a stub — the same tabs the full panel has.
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);

      // Tapping Expand (inside the draggable header) restores the full
      // panel — proving the header's tap targets still work alongside
      // its drag gesture.
      await tester.tap(find.byTooltip('Expand'));
      await tester.pumpAndSettle();

      expect(find.byType(DevToolsFloatingWindow), findsNothing);
      expect(find.byType(DevToolsPanel), findsOneWidget);

      // Closing (as opposed to minimizing) goes back to the plain
      // bubble, not the floating window.
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(DevToolsPanel), findsNothing);
      expect(find.byType(DevToolsFloatingWindow), findsNothing);
      expect(find.byType(DevToolsBubble), findsOneWidget);
    },
  );

  testWidgets(
    'the floating window shows live, interactive tab content — e.g. a '
    'seeded log entry is visible after switching to its Logs tab',
    (tester) async {
      CorextraDevTools.instance.logs.add(
        LogEntry(
          message: 'hello from the floating window',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('hello from the floating window'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "the floating window's Clear all button clears captured data, same "
    'as the full panel',
    (tester) async {
      CorextraDevTools.instance.logs.add(
        LogEntry(
          message: 'will be cleared',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();
      expect(find.textContaining('will be cleared'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear all'));
      await tester.pumpAndSettle();

      expect(find.textContaining('will be cleared'), findsNothing);
      expect(CorextraDevTools.instance.logs.entries, isEmpty);
    },
  );

  testWidgets(
    "the floating window's Collapse all button collapses an expanded "
    'row in the Network tab, without clearing any captured data',
    (tester) async {
      final event = CorextraDevTools.instance.network.begin(
        method: 'GET',
        url: 'https://example.test/todos/1',
      );
      event.statusCode = 200;
      event.completedAt = DateTime.now();
      CorextraDevTools.instance.network.complete(event);

      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      // Network is the first tab, so it's already showing.
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.text('Request'), findsOneWidget);

      await tester.tap(find.byTooltip('Collapse all'));
      await tester.pumpAndSettle();

      expect(find.text('Request'), findsNothing);
      expect(CorextraDevTools.instance.network.events, hasLength(1));
    },
  );

  testWidgets(
    'dragging the bottom-right corner grip resizes the floating window, '
    'clamped between its min and max size',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      final initialSize = tester.getSize(find.byType(DevToolsFloatingWindow));

      // Grow it: the handle only starts resizing after a long press, so
      // a bare `tester.drag` (an instant tap-drag) no longer applies —
      // hold first, then move.
      await _longPressDrag(
        tester,
        find.byKey(const Key('devtools-resize-handle')),
        const Offset(60, 60),
      );
      final grownSize = tester.getSize(find.byType(DevToolsFloatingWindow));
      expect(grownSize.width, greaterThan(initialSize.width));
      expect(grownSize.height, greaterThan(initialSize.height));

      // Shrink it far past the minimum — it should clamp, not vanish.
      await _longPressDrag(
        tester,
        find.byKey(const Key('devtools-resize-handle')),
        const Offset(-1000, -1000),
      );
      final shrunkSize = tester.getSize(find.byType(DevToolsFloatingWindow));
      expect(shrunkSize.width, 280);
      expect(shrunkSize.height, 360);

      // Still fully functional at its minimum size.
      expect(find.text('Network'), findsOneWidget);
    },
  );

  testWidgets(
    'a bare tap-drag on the resize handle, without holding first, does '
    'not resize the floating window',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      final initialSize = tester.getSize(find.byType(DevToolsFloatingWindow));

      await tester.drag(
        find.byKey(const Key('devtools-resize-handle')),
        const Offset(60, 60),
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(DevToolsFloatingWindow)),
        initialSize,
      );
    },
  );

  testWidgets('dragging the floating window by its header moves it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CorextraDevToolsOverlay(
          enabled: true,
          child: SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byType(DevToolsBubble));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Minimize'));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.byType(DevToolsFloatingWindow));
    await tester.drag(find.text('DevTools'), const Offset(40, 30));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.byType(DevToolsFloatingWindow));

    expect(after, isNot(equals(before)));
  });

  testWidgets(
    'dragging the bubble to the screen edge docks and peeks it there; '
    'tapping the peek nub reveals it (without opening the panel), and '
    'it opens normally again once revealed',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.bug), findsOneWidget);

      // Drag it flush to the left edge — the snap threshold now scales
      // with the bubble's own (small) size, so it takes landing right
      // at the edge, not just somewhere generally near it, to trigger.
      await tester.drag(find.byType(DevToolsBubble), const Offset(-1000, 0));
      await tester.pumpAndSettle();

      // Peeked: the normal bubble icon is gone, replaced by a small
      // "tap to bring back" chevron pointing back onto the screen.
      expect(find.byIcon(LucideIcons.bug), findsNothing);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);

      // Tapping the peek nub reveals it — but doesn't itself open the
      // panel, since that risks firing by accident on the same tap
      // that was really just "bring this back into view".
      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bug), findsOneWidget);
      expect(find.byType(DevToolsPanel), findsNothing);

      // Once revealed, tapping it opens the panel normally.
      await tester.tap(find.byIcon(LucideIcons.bug));
      await tester.pumpAndSettle();
      expect(find.byType(DevToolsPanel), findsOneWidget);
    },
  );

  testWidgets(
    'landing merely "somewhere near" an edge no longer peeks the '
    "bubble — only landing within a quarter of its own (small) width "
    'does, so it does not hide overeagerly on a small screen',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      // Lands 20px from the left edge: well within the old fixed 80px
      // threshold, but outside the new one (25% of the 48px bubble's
      // own width = 12px) — should stay fully visible, not peek.
      await tester.drag(find.byType(DevToolsBubble), const Offset(-716, 0));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bug), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    },
  );

  testWidgets(
    'releasing a drag away from either screen edge leaves the bubble '
    'exactly where it was dropped, without peeking',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      // Move it toward the middle of the screen, away from both edges.
      await tester.drag(find.byType(DevToolsBubble), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bug), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronLeft), findsNothing);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    },
  );

  testWidgets(
    'dragging the floating window to the screen edge docks and peeks '
    'it there; tapping the peek nub reveals its tab content again',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      expect(find.text('Network'), findsOneWidget);

      // Drag the window (by its header) far to the right, past the edge.
      await tester.drag(find.text('DevTools'), const Offset(700, 0));
      await tester.pumpAndSettle();

      expect(find.text('Network'), findsNothing);
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();

      expect(find.text('Network'), findsOneWidget);
    },
  );

  testWidgets(
    'dragging the bubble past the edge without releasing visibly slides '
    'it off-screen in real time, not just once released',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      final bubbleFinder = find.byType(DevToolsBubble);
      final gesture = await tester.startGesture(
        tester.getCenter(bubbleFinder),
      );
      // The very first move that exceeds the pan recognizer's touch
      // slop is consumed entirely by gesture *acceptance* — it never
      // reaches onPanUpdate, regardless of its own size. Only moves
      // after that are reported as real position deltas, so a drag
      // needs at least two moveBy calls to reliably land anywhere in
      // particular: one throwaway "accepting" move, then the one that
      // actually counts.
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-800, 0));
      await tester.pump();

      // Still mid-drag — the finger hasn't lifted yet — but it's
      // already visibly past the true left edge (a negative x), not
      // invisibly clamped flush against it until release.
      expect(tester.getTopLeft(bubbleFinder).dx, lessThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'dragging the bubble past the edge but releasing before the commit '
    'threshold springs it back to flush-at-the-edge, fully visible — '
    'not peeked',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CorextraDevToolsOverlay(
            enabled: true,
            child: SizedBox.shrink(),
          ),
        ),
      );

      final bubbleFinder = find.byType(DevToolsBubble);
      final before = tester.getTopLeft(bubbleFinder);
      final gesture = await tester.startGesture(
        tester.getCenter(bubbleFinder),
      );
      // First move just triggers gesture acceptance (see the test
      // above) and is discarded — the bubble is still exactly where it
      // started until the *next* move.
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      // The bubble is 48px wide with a 28px peekExtent, so there's 20px
      // of peek travel past the edge; committing needs >= 50% of that
      // (10px). Land only 5px past the left edge — enough to visibly
      // cross it, not enough to commit.
      await gesture.moveBy(Offset(-5 - before.dx, 0));
      await tester.pump();
      expect(tester.getTopLeft(bubbleFinder).dx, -5);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bug), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
      expect(tester.getTopLeft(bubbleFinder).dx, 0);
    },
  );

  testWidgets(
    'dragging the bubble straight up on a device with a status bar / '
    'notch never lets it cross into the top safe area, so it can never '
    "end up stuck in the OS's own edge-gesture zone",
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: const CorextraDevToolsOverlay(
              enabled: true,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      final bubbleFinder = find.byType(DevToolsBubble);
      final gesture = await tester.startGesture(
        tester.getCenter(bubbleFinder),
      );
      await gesture.moveBy(const Offset(0, -50)); // accepting move, discarded
      await tester.pump();
      await gesture.moveBy(const Offset(0, -800)); // drag far past the top
      await tester.pump();

      // Still mid-drag, and already clamped well clear of the 47px status
      // bar inset (47 + the 12px safety margin) rather than flush at 0.
      expect(tester.getTopLeft(bubbleFinder).dy, 59);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(bubbleFinder).dy, 59);
    },
  );

  testWidgets(
    'dragging the floating window straight up on a device with a status '
    'bar / notch never lets it cross into the top safe area either',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: const CorextraDevToolsOverlay(
              enabled: true,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DevToolsBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pumpAndSettle();

      final headerFinder = find.text('DevTools');
      final gesture = await tester.startGesture(
        tester.getCenter(headerFinder),
      );
      await gesture.moveBy(const Offset(0, -50));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -800));
      await tester.pump();

      final windowFinder = find.byType(DevToolsFloatingWindow);
      expect(tester.getTopLeft(windowFinder).dy, 59);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(windowFinder).dy, 59);
    },
  );
}

/// Simulates the resize handle's required gesture: press and hold long
/// enough for `onLongPressStart` to fire, then drag by [offset] before
/// releasing — a bare `tester.drag` only performs the up-front move and
/// never triggers the long press in the first place.
Future<void> _longPressDrag(
  WidgetTester tester,
  Finder finder,
  Offset offset,
) async {
  final gesture = await tester.startGesture(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 600));
  await gesture.moveBy(offset);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}
