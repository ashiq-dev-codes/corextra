import 'package:corextra/corextra.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how often the logger turns it into JSON — i.e. how often a body gets formatted.
class _Body {
  int formatted = 0;

  Map<String, Object?> toJson() {
    formatted++;
    return {'ok': true};
  }
}

void main() {
  test('formats the console block after the request has moved on, never '
      'while the request waits', () async {
    final body = _Body();

    const AppLoggerInterceptor().onRequest(
      RequestOptions(path: '/feed', data: body),
      RequestInterceptorHandler(),
    );
    expect(body.formatted, 0);

    await Future<void>.delayed(Duration.zero);
    expect(body.formatted, 1);
  });

  test('does no work at all when disabled', () async {
    final body = _Body();

    const AppLoggerInterceptor(enabled: false).onRequest(
      RequestOptions(path: '/feed', data: body),
      RequestInterceptorHandler(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(body.formatted, 0);
  });
}
