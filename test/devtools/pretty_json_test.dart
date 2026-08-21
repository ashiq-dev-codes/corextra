import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prettyFormatBody', () {
    test('indents valid JSON', () {
      expect(prettyFormatBody('{"a":1}'), contains('"a": 1'));
    });

    test('falls back to toString for invalid JSON', () {
      expect(prettyFormatBody('not json'), 'not json');
    });

    test('returns "null" for null', () {
      expect(prettyFormatBody(null), 'null');
    });
  });

  group('truncateBody', () {
    test('leaves short bodies unchanged', () {
      expect(truncateBody('short', 100), 'short');
    });

    test('truncates long bodies with a length marker', () {
      final long = 'a' * 50;
      final result = truncateBody(long, 10) as String;

      expect(result.startsWith('a' * 10), isTrue);
      expect(result, contains('truncated'));
      expect(result, contains('50 chars total'));
    });
  });
}
