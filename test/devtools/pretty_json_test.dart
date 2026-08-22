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

    test('leaves a Map unchanged (and still fully pretty-printable) when '
        "its pretty form fits within maxLength", () {
      final small = {'name': 'corextra', 'feature': 'DevTools'};
      final result = truncateBody(small, 1000);

      expect(result, same(small));
      expect(prettyFormatBody(result), contains('\n  "name": "corextra"'));
    });

    test('truncates a large Map against its *pretty* (indented) form, not '
        'Object.toString — so the visible prefix is still real, indented '
        'JSON instead of a single unreadable Dart-syntax line', () {
      final big = {
        'items': List.generate(50, (i) => 'Item #$i'),
      };
      final result = truncateBody(big, 200) as String;

      // Dart's Map.toString() renders keys unquoted with `key: value` —
      // confirms the truncated text is JSON syntax, not that fallback.
      expect(result, contains('"items"'));
      expect(result, isNot(contains('items:')));
      expect(prettyFormatBody(result), contains('\n  "items"'));
      expect(prettyFormatBody(result), contains('\n    "Item #0"'));
    });
  });
}
