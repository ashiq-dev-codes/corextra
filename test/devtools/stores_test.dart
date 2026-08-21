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
}
