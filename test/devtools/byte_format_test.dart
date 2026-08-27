import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats bytes below 1024 with no decimal', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(0), '0 B');
  });

  test('formats kilobytes, megabytes, and gigabytes with one decimal', () {
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(250183680), '238.6 MB');
    expect(formatBytes(2147483648), '2.0 GB');
  });

  test('respects a custom decimals count', () {
    expect(formatBytes(1536, decimals: 2), '1.50 KB');
  });
}
