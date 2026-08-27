import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkEventStore', () {
    test('caps at maxEntries, evicting oldest first', () {
      final store = NetworkEventStore(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        store.begin(method: 'GET', url: 'https://example.test/$i');
      }
      expect(store.events, hasLength(3));
      expect(store.events.first.url, 'https://example.test/2');
      expect(store.events.last.url, 'https://example.test/4');
    });

    test('clear empties the buffer', () {
      final store = NetworkEventStore();
      store.begin(method: 'GET', url: 'https://example.test');
      store.clear();
      expect(store.events, isEmpty);
    });
  });

  group('LogEntryStore', () {
    test('caps at maxEntries, evicting oldest first', () {
      final store = LogEntryStore(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        store.add(
          LogEntry(
            message: 'message $i',
            level: LogLevel.info,
            timestamp: DateTime.now(),
          ),
        );
      }
      expect(store.entries, hasLength(3));
      expect(store.entries.first.message, 'message 2');
      expect(store.entries.last.message, 'message 4');
    });
  });

  group('FrameSampleStore', () {
    test('caps at maxEntries, evicting oldest first', () {
      final store = FrameSampleStore(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        store.add(
          FrameSample(
            buildDuration: Duration(milliseconds: i),
            rasterDuration: Duration.zero,
            timestamp: DateTime.now(),
          ),
        );
      }
      expect(store.samples, hasLength(3));
      expect(store.samples.first.buildDuration, const Duration(milliseconds: 2));
      expect(store.samples.last.buildDuration, const Duration(milliseconds: 4));
    });

    test('recentJankyCount counts only janky samples in the window', () {
      final store = FrameSampleStore();
      store.add(
        FrameSample(
          buildDuration: const Duration(milliseconds: 8),
          rasterDuration: const Duration(milliseconds: 8),
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      store.add(
        FrameSample(
          buildDuration: const Duration(milliseconds: 20),
          rasterDuration: const Duration(milliseconds: 20),
          timestamp: DateTime.fromMillisecondsSinceEpoch(16),
        ),
      );
      expect(store.recentJankyCount(), 1);
    });
  });

  group('AppSizeStore', () {
    const validJson =
        '{"n": "Root", "value": 100, "type": "ios", '
        '"children": [{"n": "Frameworks", "value": 100}]}';

    test('loadFromJson parses a valid analysis and clears any prior error', () {
      final store = AppSizeStore();
      store.loadFromJson('not json', fileName: 'bad.json');
      expect(store.errorMessage, isNotNull);

      store.loadFromJson(validJson, fileName: 'ios-code-size-analysis_1.json');

      expect(store.errorMessage, isNull);
      expect(store.root?.name, 'Root');
      expect(store.root?.children.single.name, 'Frameworks');
      expect(store.platform, 'ios');
      expect(store.fileName, 'ios-code-size-analysis_1.json');
      expect(store.loadedAt, isNotNull);
      expect(store.isLive, isFalse);
    });

    test('loadFromJson on invalid input keeps any previously loaded analysis', () {
      final store = AppSizeStore();
      store.loadFromJson(validJson, fileName: 'good.json');

      store.loadFromJson('{not valid', fileName: 'bad.json');

      expect(store.errorMessage, contains('bad.json'));
      expect(store.root?.name, 'Root');
      expect(store.fileName, 'good.json');
    });

    test('clear resets everything', () {
      final store = AppSizeStore();
      store.loadFromJson(validJson, fileName: 'good.json');

      store.clear();

      expect(store.root, isNull);
      expect(store.fileName, isNull);
      expect(store.loadedAt, isNull);
      expect(store.platform, isNull);
      expect(store.errorMessage, isNull);
      expect(store.isLive, isFalse);
    });

    test('runQuickScan applies a successful scan and marks it live', () async {
      final store = AppSizeStore();
      const bundleRoot = SizeAnalysisNode(
        name: 'MyApp.app',
        sizeBytes: 0,
        children: [SizeAnalysisNode(name: 'Frameworks', sizeBytes: 42)],
      );

      await store.runQuickScan(
        () async =>
            const BundleScanResult(root: bundleRoot, platformLabel: 'macos'),
      );

      expect(store.root?.name, 'MyApp.app');
      expect(store.platform, 'macos');
      expect(store.fileName, 'Installed app bundle');
      expect(store.isLive, isTrue);
      expect(store.errorMessage, isNull);
    });

    test('runQuickScan on an unsupported platform sets an error and keeps prior data', () async {
      final store = AppSizeStore();
      store.loadFromJson(validJson, fileName: 'good.json');

      await store.runQuickScan(() async => null);

      expect(store.errorMessage, isNotNull);
      expect(store.root?.name, 'Root');
      expect(store.isLive, isFalse);
    });
  });
}
