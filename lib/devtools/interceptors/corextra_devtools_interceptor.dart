import 'package:dio/dio.dart';

import '../corextra_devtools.dart';
import '../models/network_event.dart';
import '../util/pretty_json.dart';

/// A Dio interceptor that records every request for the DevTools Network tab, without changing any request, response or error.
///
/// Example:
/// ```dart
/// dio.interceptors.add(const CorextraDevToolsInterceptor());
///
/// // Add AppLoggerInterceptor too for console logs
/// dio.interceptors.add(const AppLoggerInterceptor());
/// ```
class CorextraDevToolsInterceptor extends Interceptor {
  /// Creates an interceptor that records into `CorextraDevTools.instance.network`.
  const CorextraDevToolsInterceptor({
    this.enabled,
    this.captureBody = true,
    this.maxBodyLength = 100000,
    this.hiddenHeaders = const {},
  });

  // ---------------- Settings ----------------

  /// Whether to record requests; null follows [CorextraDevTools.enabled].
  final bool? enabled;

  /// Whether to record request and response bodies; headers and status are always recorded.
  final bool captureBody;

  /// The most characters kept from a text body; JSON maps and lists are kept whole, since measuring them would mean formatting them.
  final int maxBodyLength;

  /// Header names, in any letter case, whose values the panel masks on screen; they're still recorded, so this isn't data scrubbing.
  ///
  /// Example:
  /// ```dart
  /// dio.interceptors.add(
  ///   const CorextraDevToolsInterceptor(hiddenHeaders: {'Authorization', 'Cookie'}),
  /// );
  /// ```
  final Set<String> hiddenHeaders;

  // ---------------- Private helpers ----------------

  // Carries the recorded event from onRequest to onResponse or onError of the same request.
  static const _extraKey = 'corextra_devtools_event';

  bool get _isEnabled => enabled ?? CorextraDevTools.instance.enabled;

  // ---------------- Recording ----------------

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isEnabled) {
      final event = CorextraDevTools.instance.network.begin(
        method: options.method,
        url: '${options.baseUrl}${options.path}',
        queryParameters: options.queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
        requestHeaders: options.headers.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
        requestBody:
            captureBody ? truncateBody(options.data, maxBodyLength) : null,
        hiddenHeaderKeys: hiddenHeaders.map((h) => h.toLowerCase()).toSet(),
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
      event.responseHeaders = response.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      );
      event.responseBody =
          captureBody ? truncateBody(response.data, maxBodyLength) : null;
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
        event.responseBody =
            captureBody ? truncateBody(responseData, maxBodyLength) : null;
      }
      event.completedAt = DateTime.now();
      CorextraDevTools.instance.network.complete(event);
    }
    handler.next(err);
  }
}
