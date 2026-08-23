import 'package:dio/dio.dart';
import 'package:corextra/corextra.dart';

import 'fake_scenario_interceptor.dart';

/// Network service that provides Dio instance configured with interceptors
class NetworkService {
  NetworkService() {
    _dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'));
    _dio.interceptors.add(const AppLoggerInterceptor());
    _dio.interceptors.add(
      const CorextraDevToolsInterceptor(hiddenHeaders: {'authorization'}),
    );
    // Added last so the interceptors above still observe the faked response/error.
    _dio.interceptors.add(const FakeScenarioInterceptor());
  }

  late final Dio _dio;

  Dio get dio => _dio;

  void close() => _dio.close();
}