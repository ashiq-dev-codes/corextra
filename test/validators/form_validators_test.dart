import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormValidators.required', () {
    test('rejects null, empty and whitespace-only values', () {
      expect(FormValidators.required(null), isNotNull);
      expect(FormValidators.required(''), isNotNull);
      expect(FormValidators.required('   '), isNotNull);
    });

    test('accepts a non-empty value', () {
      expect(FormValidators.required('Ashiq'), isNull);
    });

    test('message overrides the default text', () {
      expect(
        FormValidators.required(null, message: 'Name is required'),
        equals('Name is required'),
      );
    });
  });

  group('FormValidators.email', () {
    test('rejects malformed addresses', () {
      expect(FormValidators.email('not-an-email'), isNotNull);
      expect(FormValidators.email('missing@domain'), isNotNull);
      expect(FormValidators.email('@no-local-part.com'), isNotNull);
      expect(FormValidators.email('double@@at.com'), isNotNull);
      expect(FormValidators.email('trailing-dot@example.com.'), isNotNull);
      expect(FormValidators.email('bad-host@-leadinghyphen.com'), isNotNull);
    });

    test('accepts well-formed addresses, including long TLDs', () {
      expect(FormValidators.email('user@example.com'), isNull);
      expect(FormValidators.email('user@sub.example.co.uk'), isNull);
      expect(FormValidators.email('user@example.technology'), isNull);
    });

    test('accepts a "+" tag in the local part (e.g. Gmail aliases)', () {
      expect(FormValidators.email('user+tag@gmail.com'), isNull);
    });
  });

  group('FormValidators.minLength / maxLength', () {
    test('minLength rejects values shorter than the limit', () {
      expect(FormValidators.minLength('ab', 3), isNotNull);
      expect(FormValidators.minLength('abc', 3), isNull);
    });

    test('maxLength rejects values longer than the limit', () {
      expect(FormValidators.maxLength('abcd', 3), isNotNull);
      expect(FormValidators.maxLength('abc', 3), isNull);
    });

    test('maxLength treats an empty value as valid (not required)', () {
      expect(FormValidators.maxLength(null, 3), isNull);
      expect(FormValidators.maxLength('', 3), isNull);
    });
  });

  group('FormValidators.numeric', () {
    test('rejects non-digit characters', () {
      expect(FormValidators.numeric('12a3'), isNotNull);
    });

    test('accepts digits only', () {
      expect(FormValidators.numeric('12345'), isNull);
    });
  });

  group('FormValidators.url', () {
    test('rejects malformed or non-http(s) urls', () {
      expect(FormValidators.url('not a url'), isNotNull);
      expect(FormValidators.url('ftp://example.com'), isNotNull);
    });

    test('accepts http/https urls', () {
      expect(FormValidators.url('https://example.com'), isNull);
    });
  });

  group('FormValidators.pattern', () {
    test('validates the value against a custom regex', () {
      final lettersOnly = RegExp(r'^[a-zA-Z]+$');

      expect(
        FormValidators.pattern('abc123', lettersOnly, message: 'Letters only'),
        equals('Letters only'),
      );
      expect(FormValidators.pattern('abc', lettersOnly), isNull);
    });
  });

  group('FormValidators.compose', () {
    test('returns the first validator error found, in order', () {
      final validator = FormValidators.compose([
        FormValidators.required,
        FormValidators.email,
      ]);

      expect(validator(''), equals(FormValidators.required('')));
      expect(
        validator('not-an-email'),
        equals(FormValidators.email('not-an-email')),
      );
      expect(validator('user@example.com'), isNull);
    });
  });

  group('FormValidators.optional', () {
    test('skips the wrapped validator when the field is empty', () {
      final validator = FormValidators.optional(FormValidators.url);

      expect(validator(null), isNull);
      expect(validator(''), isNull);
    });

    test('still runs the wrapped validator when a value is present', () {
      final validator = FormValidators.optional(FormValidators.url);

      expect(validator('not a url'), isNotNull);
      expect(validator('https://example.com'), isNull);
    });
  });
}
