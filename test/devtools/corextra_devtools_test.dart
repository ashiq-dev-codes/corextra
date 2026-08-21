import 'package:corextra/corextra.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CorextraDevTools enabled gating', () {
    setUp(() => CorextraDevTools.instance.resetAll());

    tearDown(() {
      CorextraDevTools.instance.enabled = true;
      CorextraDevTools.instance.resetAll();
    });

    test('defaults to kDebugMode', () {
      expect(CorextraDevTools.instance.enabled, kDebugMode);
    });

    test('debugLog captures into the Logs store only when enabled', () {
      CorextraDevTools.instance.enabled = true;
      debugLog('captured message');
      expect(CorextraDevTools.instance.logs.entries, hasLength(1));
      expect(
        CorextraDevTools.instance.logs.entries.first.message,
        'captured message',
      );

      CorextraDevTools.instance.resetAll();
      CorextraDevTools.instance.enabled = false;
      debugLog('not captured');
      expect(CorextraDevTools.instance.logs.entries, isEmpty);
    });
  });
}
