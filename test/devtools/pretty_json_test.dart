import 'dart:typed_data';

import 'package:corextra/corextra.dart';
import 'package:dio/dio.dart';
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

    test('shows non-JSON text (plain text, HTML, XML, ...) as-is', () {
      expect(
        prettyFormatBody('<html><body>hi</body></html>'),
        '<html><body>hi</body></html>',
      );
    });

    test('summarizes raw bytes (e.g. ResponseType.bytes) as a length + '
        'hex preview, not a JSON array of every byte value', () {
      final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
      final result = prettyFormatBody(bytes);

      expect(result, contains('8 bytes'));
      expect(result, contains('89 50 4e 47 0d 0a 1a 0a'));
      expect(result, isNot(contains('137,')));
    });

    test('does not mistake an ordinary JSON int array for binary data — '
        'only a real Uint8List gets the bytes summary', () {
      expect(prettyFormatBody([1, 2, 3]), '''
[
  1,
  2,
  3
]''');
    });

    test('shows FormData\'s actual fields and file metadata instead of '
        "Object.toString's unhelpful \"Instance of 'FormData'\"", () {
      final form = FormData.fromMap({'name': 'corextra'});
      form.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes([1, 2, 3], filename: 'avatar.png'),
        ),
      );

      final result = prettyFormatBody(form);

      expect(result, contains('"name": "corextra"'));
      expect(result, contains('"filename": "avatar.png"'));
      expect(result, contains('"contentType": "image/png"'));
      expect(result, contains('"length": 3'));
      expect(result, isNot(contains('Instance of')));
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

    test('leaves a large Map raw and untruncated, even past maxLength — '
        'measuring its pretty-printed size would mean paying that cost '
        'eagerly on every request, which is exactly what this avoids', () {
      final big = {
        'items': List.generate(50, (i) => 'Item #$i'),
      };
      final result = truncateBody(big, 10);

      expect(result, same(big));
      expect(prettyFormatBody(result), contains('\n    "Item #0"'));
    });

    test('summarizes raw bytes unconditionally, before the length check '
        '— its display summary is compact regardless of the underlying '
        "payload's actual size, so measuring that against maxLength "
        'would never trip and a multi-megabyte download would sit in '
        'the capture buffer at full size forever', () {
      final huge = Uint8List(5 * 1024 * 1024);
      final result = truncateBody(huge, 20000);

      expect(result, isA<String>());
      expect((result as String).length, lessThan(200));
    });

    test('summarizes FormData unconditionally too — never retains the '
        'live FormData object (and its multipart file streams)', () {
      final form = FormData.fromMap({'name': 'corextra'});
      final result = truncateBody(form, 20000);

      expect(result, isA<String>());
      expect(result, isNot(isA<FormData>()));
    });
  });

  group('boundedPrettyFormatBody', () {
    test('formats a small body exactly like prettyFormatBody', () {
      final small = {'name': 'corextra', 'feature': 'DevTools'};

      expect(boundedPrettyFormatBody(small), prettyFormatBody(small));
    });

    test('bounds a huge top-level list', () {
      final big = List.generate(5000, (i) => 'Item #$i');

      final result = boundedPrettyFormatBody(big);

      expect(result, contains('"Item #0"'));
      expect(result, contains('more items'));
      expect(result.length, lessThan(10000));
    });

    test('bounds bulk nested several levels down, not just a top-level '
        'list — a shape a plain top-level-length check would miss '
        'entirely', () {
      final wrapped = {
        'meta': {'ok': true},
        'data': {
          'items': List.generate(5000, (i) => {'id': i, 'name': 'Item #$i'}),
        },
      };

      final result = boundedPrettyFormatBody(wrapped);

      expect(result, contains('"meta"'));
      expect(result.length, lessThan(10000));
    });

    test('caps total work via a node budget: the walk itself stops once '
        'spent, so a large nested value returns quickly rather than '
        'visiting every node and truncating only the output after', () {
      final large = {
        'data': {
          'items': List.generate(50000, (i) => {'id': i, 'name': 'Item #$i'}),
        },
      };

      final stopwatch = Stopwatch()..start();
      final result = boundedPrettyFormatBody(large, budget: 500);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(result.length, lessThan(5000));
    });
  });
}
