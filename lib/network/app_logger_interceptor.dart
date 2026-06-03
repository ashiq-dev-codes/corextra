import 'dart:convert';
import 'dart:developer' as dev;

import 'package:corextra/logs/enum/log_color.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A Dio interceptor that logs requests, responses, and errors in a
/// pretty, bordered format — one consolidated block per event.
///
/// Add it to your Dio instance:
/// ```dart
/// dio.interceptors.add(AppLoggerInterceptor());
/// ```
/// Pass `enabled: false` to silence all logs:
/// ```dart
/// dio.interceptors.add(AppLoggerInterceptor(enabled: false));
/// ```
class AppLoggerInterceptor extends Interceptor {
  const AppLoggerInterceptor({this.enabled = true});
  final bool enabled;

  static const _divider =
      '├─────────────────────────────────────────────────────────────';
  static const _top =
      '┌─────────────────────────────────────────────────────────────';
  static const _bottom =
      '└─────────────────────────────────────────────────────────────';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) _logRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) _logResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) _logError(err);
    handler.next(err);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    final c = LogColor.blue.getValue;
    final r = LogColor.reset.getValue;
    final method = options.method.toUpperCase();
    final url = '${options.baseUrl}${options.path}';

    final b = StringBuffer();
    b.writeln('$c$_top Request ───────────────');
    b.writeln('│  ➡  $method  $url');
    b.writeln('│  ⏱  ${DateTime.now().toIso8601String()}');

    final query = options.queryParameters;
    if (query.isNotEmpty) {
      b.writeln(_divider);
      b.writeln('│  Query');
      for (final e in query.entries) {
        b.writeln('│    ${e.key}: ${e.value}');
      }
    }

    final data = options.data;
    if (data != null) {
      b.writeln(_divider);
      b.writeln('│  Body');
      for (final line in _formatBody(data).split('\n')) {
        b.writeln('│    $line');
      }
    }

    b.write('$_bottom$r');
    dev.log(b.toString(), name: 'HTTP');
  }

  void _logResponse(Response response) {
    if (!kDebugMode) return;

    final c = LogColor.green.getValue;
    final r = LogColor.reset.getValue;
    final req = response.requestOptions;
    final method = req.method.toUpperCase();
    final url = '${req.baseUrl}${req.path}';
    final status = response.statusCode ?? 0;
    final statusMsg = response.statusMessage ?? '';

    final b = StringBuffer();
    b.writeln('$c$_top Response ──────────────');
    b.writeln('│  ✔  $status $statusMsg  $method  $url');
    b.writeln('│  ⏱  ${DateTime.now().toIso8601String()}');
    b.writeln(_divider);
    b.writeln('│  Body');
    for (final line in _formatBody(response.data).split('\n')) {
      b.writeln('│    $line');
    }
    b.write('$_bottom$r');
    dev.log(b.toString(), name: 'HTTP');
  }

  void _logError(DioException err) {
    if (!kDebugMode) return;

    final c = LogColor.red.getValue;
    final r = LogColor.reset.getValue;
    final req = err.requestOptions;
    final method = req.method.toUpperCase();
    final url = '${req.baseUrl}${req.path}';
    final status = err.response?.statusCode;

    final b = StringBuffer();
    b.writeln('$c$_top Error ─────────────────');
    b.writeln('│  ✘  ${status ?? err.type.name}  $method  $url');
    b.writeln('│  ⏱  ${DateTime.now().toIso8601String()}');
    b.writeln('│  Message: ${err.message ?? 'none'}');

    final resData = err.response?.data;
    if (resData != null) {
      b.writeln(_divider);
      b.writeln('│  Response');
      for (final line in _formatBody(resData).split('\n')) {
        b.writeln('│    $line');
      }
    }

    b.write('$_bottom$r');
    dev.log(b.toString(), name: 'HTTP');
  }

  String _formatBody(dynamic data) {
    if (data == null) return 'none';
    try {
      final value = data is String ? jsonDecode(data) : data;
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return data.toString();
    }
  }
}
