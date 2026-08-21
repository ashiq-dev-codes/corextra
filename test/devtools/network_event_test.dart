import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkEvent', () {
    test('is pending until completedAt is set, then exposes duration', () {
      final event = NetworkEvent(
        id: '1',
        method: 'GET',
        url: 'https://example.test',
        startedAt: DateTime(2024, 1, 1, 0, 0, 0),
      );

      expect(event.isPending, isTrue);
      expect(event.duration, isNull);

      event.completedAt = DateTime(2024, 1, 1, 0, 0, 1, 500);

      expect(event.isPending, isFalse);
      expect(event.duration, const Duration(seconds: 1, milliseconds: 500));
    });

    test('isError is true only once errorMessage is set', () {
      final event = NetworkEvent(
        id: '1',
        method: 'GET',
        url: 'https://example.test',
        startedAt: DateTime.now(),
      );

      expect(event.isError, isFalse);
      event.errorMessage = 'boom';
      expect(event.isError, isTrue);
    });
  });
}
