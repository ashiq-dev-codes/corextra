import 'dart:convert';

import 'package:corextra/corextra.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = utf8.encode(jsonEncode({'ok': true}));
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  test(
    'captures method, url, status and duration for a successful request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _FakeAdapter()
        ..interceptors.add(const CorextraDevToolsInterceptor());

      await dio.get('/ping');

      final events = CorextraDevTools.instance.network.events;
      expect(events, hasLength(1));

      final event = events.first;
      expect(event.method, 'GET');
      expect(event.url, 'https://example.test/ping');
      expect(event.statusCode, 200);
      expect(event.isPending, isFalse);
      expect(event.duration, isNotNull);
    },
  );

  test('captures query parameters separately from the url', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter()
      ..interceptors.add(const CorextraDevToolsInterceptor());

    await dio.get('/search', queryParameters: {'q': 'flutter', 'page': 2});

    final event = CorextraDevTools.instance.network.events.single;
    expect(event.url, 'https://example.test/search');
    expect(event.queryParameters, {'q': 'flutter', 'page': '2'});
  });

  test('does not capture when disabled', () async {
    CorextraDevTools.instance.enabled = false;

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter()
      ..interceptors.add(const CorextraDevToolsInterceptor());

    await dio.get('/ping');

    expect(CorextraDevTools.instance.network.events, isEmpty);
  });

  test('redacts hidden headers case-insensitively', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeAdapter()
      ..interceptors.add(
        const CorextraDevToolsInterceptor(hiddenHeaders: {'x-api-key'}),
      );

    await dio.get('/ping', options: Options(headers: {'X-Api-Key': 'secret'}));

    final event = CorextraDevTools.instance.network.events.single;
    expect(event.requestHeaders['X-Api-Key'], '***');
  });
}
