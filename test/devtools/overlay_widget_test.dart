import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
