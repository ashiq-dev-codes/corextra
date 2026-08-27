import 'dart:convert';

import 'package:corextra/corextra.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _validJson = '''
{
  "n": "Root",
  "value": 1000,
  "type": "ios",
  "children": [
    {
      "n": "Frameworks",
      "value": 700,
      "children": [
        {"n": "App.framework", "value": 500},
        {"n": "Flutter.framework", "value": 200}
      ]
    },
    {"n": "Runner", "value": 300}
  ]
}
''';

// Defaults scanBundle to a no-op so the auto-run-on-open quick scan never touches this test run's own real filesystem.
Widget _wrap({
  Future<XFile?> Function()? pickFile,
  Future<BundleScanResult?> Function()? scanBundle,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AppSizeTab(
        pickFile: pickFile ?? () async => null,
        scanBundle: scanBundle ?? () async => null,
      ),
    ),
  );
}

Future<XFile?> Function() _fakePicker(
  String content, {
  String name = 'analysis.json',
}) {
  // `path`, not `name`: XFile.fromData's `name` param is inert on the VM — `.name` is derived from `path`.
  return () async => XFile.fromData(
    utf8.encode(content),
    path: name,
    mimeType: 'application/json',
  );
}

Future<BundleScanResult?> Function() _fakeScan(
  SizeAnalysisNode root, {
  String platformLabel = 'macos',
}) {
  return () async =>
      BundleScanResult(root: root, platformLabel: platformLabel);
}

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  testWidgets('shows an empty state with an Import file button when quick scan finds nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('No size data loaded yet'), findsOneWidget);
    expect(find.text('Import file'), findsOneWidget);
  });

  testWidgets('quick scan runs automatically on open and shows the live badge', (
    tester,
  ) async {
    const bundle = SizeAnalysisNode(
      name: 'MyApp.app',
      sizeBytes: 0,
      children: [
        SizeAnalysisNode(name: 'Frameworks', sizeBytes: 700),
        SizeAnalysisNode(name: 'Runner', sizeBytes: 300),
      ],
    );

    await tester.pumpWidget(_wrap(scanBundle: _fakeScan(bundle)));
    await tester.pumpAndSettle();

    expect(find.text('1000 B'), findsOneWidget);
    expect(find.text('Live scan'), findsOneWidget);
    expect(find.textContaining('Installed app bundle'), findsOneWidget);
  });

  testWidgets('opening a valid analysis file shows the total size and breadcrumb', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(pickFile: _fakePicker(_validJson, name: 'ios-code-size-analysis_1.json')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import file'));
    await tester.pumpAndSettle();

    expect(find.text('1000 B'), findsOneWidget);
    expect(find.textContaining('ios-code-size-analysis_1.json'), findsOneWidget);
    expect(find.text('Root (1000 B)'), findsOneWidget);
    expect(find.text('Imported'), findsOneWidget);
  });

  testWidgets('tapping a breakdown row with children drills in, breadcrumb tap drills back out', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(pickFile: _fakePicker(_validJson)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import file'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Frameworks'));
    await tester.pumpAndSettle();

    expect(find.text('App.framework'), findsOneWidget);
    expect(find.text('Frameworks (700 B)'), findsOneWidget);

    await tester.tap(find.text('Root'));
    await tester.pumpAndSettle();

    expect(find.text('Frameworks'), findsOneWidget);
    expect(find.text('Runner'), findsOneWidget);
  });

  testWidgets('Clear resets back to the empty state', (tester) async {
    await tester.pumpWidget(_wrap(pickFile: _fakePicker(_validJson)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import file'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No size data loaded yet'), findsOneWidget);
  });

  testWidgets('an unparsable file shows an error banner instead of crashing', (tester) async {
    await tester.pumpWidget(_wrap(pickFile: _fakePicker('not json', name: 'bad.json')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import file'));
    await tester.pumpAndSettle();

    expect(find.textContaining('bad.json'), findsOneWidget);
    expect(find.text('No size data loaded yet'), findsOneWidget);
  });

  testWidgets('the Rescan button re-runs the quick scan', (tester) async {
    const bundle = SizeAnalysisNode(
      name: 'MyApp.app',
      sizeBytes: 500,
      children: [
        SizeAnalysisNode(name: 'Frameworks', sizeBytes: 300),
        SizeAnalysisNode(name: 'Runner', sizeBytes: 200),
      ],
    );
    await tester.pumpWidget(
      _wrap(
        pickFile: _fakePicker(_validJson),
        scanBundle: _fakeScan(bundle),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('500 B'), findsOneWidget);

    await tester.tap(find.byTooltip('Import file'));
    await tester.pumpAndSettle();
    expect(find.text('1000 B'), findsOneWidget);
    expect(find.text('Imported'), findsOneWidget);

    await tester.tap(find.byTooltip('Rescan the installed app bundle'));
    await tester.pumpAndSettle();

    expect(find.text('500 B'), findsOneWidget);
    expect(find.text('Live scan'), findsOneWidget);
  });

  testWidgets('breakdown rows show a percentage of the parent alongside the size', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(pickFile: _fakePicker(_validJson)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import file'));
    await tester.pumpAndSettle();

    expect(find.text('70%'), findsOneWidget); // Frameworks: 700 / 1000
    expect(find.text('30%'), findsOneWidget); // Runner: 300 / 1000
  });

  testWidgets('drilling into a leaf during a live scan explains why it can\'t go deeper', (
    tester,
  ) async {
    const bundle = SizeAnalysisNode(
      name: 'MyApp.app',
      sizeBytes: 0,
      children: [
        SizeAnalysisNode(
          name: 'App.framework',
          sizeBytes: 0,
          children: [SizeAnalysisNode(name: 'App', sizeBytes: 500)],
        ),
      ],
    );
    await tester.pumpWidget(_wrap(scanBundle: _fakeScan(bundle)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('App.framework'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App'));
    await tester.pumpAndSettle();

    expect(find.textContaining('single file'), findsOneWidget);
    expect(find.textContaining('--analyze-size'), findsOneWidget);
  });

  testWidgets(
    "renders without overflowing at the PiP window's minimum size (280×360)",
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 360,
              child: AppSizeTab(
                pickFile: _fakePicker(_validJson),
                scanBundle: () async => null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Import file'));
      await tester.tap(find.text('Import file'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Breakdown'), findsOneWidget);
    },
  );
}
