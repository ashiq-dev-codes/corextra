import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoubleExtensions', () {
    test('toZeroIfNegative returns 0.0 for negative values', () {
      expect((-3.5).toZeroIfNegative(), equals(0.0));
    });

    test('toZeroIfNegative returns same value for positive values', () {
      expect(5.2.toZeroIfNegative(), equals(5.2));
    });
  });

  group('IntExtensions', () {
    test('toZeroIfNegative returns 0 for negative values', () {
      expect((-10).toZeroIfNegative(), equals(0));
    });

    test('toZeroIfNegative returns same value for positive values', () {
      expect(42.toZeroIfNegative(), equals(42));
    });
  });

  group('ListExtensions', () {
    test('isNullOrEmpty returns true for null list', () {
      List<int>? list;
      expect(list.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns true for empty list', () {
      List<int>? list = [];
      expect(list.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns false for non-empty list', () {
      List<int>? list = [1, 2];
      expect(list.isNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty returns false for null list', () {
      List<int>? list;
      expect(list.isNotNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty returns false for empty list', () {
      List<int>? list = [];
      expect(list.isNotNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty returns true for non-empty list', () {
      List<int>? list = [3];
      expect(list.isNotNullOrEmpty, isTrue);
    });
  });

  group('NonNullableStringExtensions', () {
    test('toTryInt parses valid integers', () {
      expect('123'.toTryInt(), equals(123));
    });

    test('toTryInt returns null for invalid integers', () {
      expect('abc'.toTryInt(), isNull);
    });

    test('toTryDouble parses valid doubles', () {
      expect('3.14'.toTryDouble(), equals(3.14));
    });

    test('toTryDouble returns null for invalid input', () {
      expect('pi'.toTryDouble(), isNull);
    });

    test('toTryBool parses "true" and "1" as true', () {
      expect('true'.toTryBool(), isTrue);
      expect('1'.toTryBool(), isTrue);
    });

    test('toTryBool parses "false", "0" and "no" as false', () {
      expect('false'.toTryBool(), isFalse);
      expect('0'.toTryBool(), isFalse);
      expect('No'.toTryBool(), isFalse);
    });

    test('toTryBool returns null for anything else', () {
      expect('nope'.toTryBool(), isNull);
      expect('2'.toTryBool(), isNull);
      expect(''.toTryBool(), isNull);
    });

    test('toTryBool accepts any letter case and surrounding spaces', () {
      expect(' TRUE '.toTryBool(), isTrue);
      expect('Yes'.toTryBool(), isTrue);
    });

    test('number and date parsing ignore surrounding spaces', () {
      expect(' 7 '.toTryInt(), equals(7));
      expect(' 7.5 '.toTryDouble(), equals(7.5));
      expect(' 2026-01-15 '.toTryDateTime(), equals(DateTime(2026, 1, 15)));
    });

    test('capitalize works correctly', () {
      expect('hello WORLD'.capitalize(), equals('Hello World'));
      expect('  hello   world  '.trim().capitalize(), equals('Hello World'));
    });
  });

  group('NullableStringExtensions', () {
    test('isNullOrEmpty returns true for null', () {
      String? value;
      expect(value.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns true for empty string', () {
      String? value = '';
      expect(value.isNullOrEmpty, isTrue);
    });

    test('isNullOrEmpty returns false for non-empty string', () {
      String? value = 'test';
      expect(value.isNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty returns false for null', () {
      String? value;
      expect(value.isNotNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty returns true for non-empty string', () {
      String? value = 'dart';
      expect(value.isNotNullOrEmpty, isTrue);
    });
  });

  group('Utility functions', () {
    test('isStringEmpty returns true for null or empty', () {
      expect(isStringEmpty(null), isTrue);
      expect(isStringEmpty(''), isTrue);
    });

    test('isStringEmpty returns false for non-empty', () {
      expect(isStringEmpty('data'), isFalse);
    });

    test('isListEmpty returns true for null or empty', () {
      expect(isListEmpty(null), isTrue);
      expect(isListEmpty([]), isTrue);
    });

    test('isListEmpty returns false for non-empty', () {
      expect(isListEmpty([1, 2]), isFalse);
    });
  });
}
