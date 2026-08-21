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
}
