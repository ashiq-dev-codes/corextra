import 'package:dio/dio.dart';

import '../devtools_controller.dart';
import '../models/network_event.dart';
import '../util/pretty_json.dart';

/// A purely-observational Dio interceptor that feeds the DevTools Network
/// tab. It never mutates the request/response/error — always calls
/// `handler.next(...)` unchanged.
///
/// Additive to `AppLoggerInterceptor` — add both if you want pretty
/// console logs *and* the in-app panel:
/// ```dart
/// dio.interceptors.add(const AppLoggerInterceptor());
/// dio.interceptors.add(const CorextraDevToolsInterceptor());
/// ```
class CorextraDevToolsInterceptor extends Interceptor {
  const CorextraDevToolsInterceptor({
    this.enabled,
    this.captureBody = true,
    this.maxBodyLength = 20000,
    this.hiddenHeaders = const {},
  });

  /// When `null`, defers to [CorextraDevTools.instance.enabled].
  final bool? enabled;
  final bool captureBody;
  final int maxBodyLength;

  /// Header names (case-insensitive) redacted before being stored.
  final Set<String> hiddenHeaders;

  static const _extraKey = 'corextra_devtools_event';
  static const _redacted = '***';

  bool get _isEnabled => enabled ?? CorextraDevTools.instance.enabled;

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    if (hiddenHeaders.isEmpty) return headers;
    final hidden = hiddenHeaders.map((h) => h.toLowerCase()).toSet();
    return headers.map(
      (key, value) => MapEntry(
        key,
        hidden.contains(key.toLowerCase()) ? _redacted : value,
      ),
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isEnabled) {
      final event = CorextraDevTools.instance.network.begin(
        method: options.method,
        url: '${options.baseUrl}${options.path}',
        queryParameters: options.queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
        requestHeaders: _redactHeaders(
          options.headers.map((key, value) => MapEntry(key, value.toString())),
        ),
        requestBody: captureBody
            ? truncateBody(options.data, maxBodyLength)
            : null,
      );
      options.extra[_extraKey] = event;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final event = response.requestOptions.extra[_extraKey] as NetworkEvent?;
    if (event != null) {
      event.statusCode = response.statusCode;
      event.statusMessage = response.statusMessage;
      event.responseHeaders = _redactHeaders(
        response.headers.map.map(
          (key, value) => MapEntry(key, value.join(', ')),
        ),
      );
      event.responseBody = captureBody
          ? truncateBody(response.data, maxBodyLength)
          : null;
      event.completedAt = DateTime.now();
      CorextraDevTools.instance.network.complete(event);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final event = err.requestOptions.extra[_extraKey] as NetworkEvent?;
    if (event != null) {
      event.statusCode = err.response?.statusCode;
      event.statusMessage = err.response?.statusMessage;
      event.errorType = err.type.name;
      event.errorMessage = err.message ?? 'Unknown error';
      final responseData = err.response?.data;
      if (responseData != null) {
        event.responseBody = captureBody
            ? truncateBody(responseData, maxBodyLength)
            : null;
      }
      event.completedAt = DateTime.now();
      CorextraDevTools.instance.network.complete(event);
    }
    handler.next(err);
  }
}
