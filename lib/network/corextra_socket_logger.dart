import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../devtools/devtools_controller.dart';
import '../devtools/models/network_event.dart';
import '../devtools/util/pretty_json.dart';
import '../logs/enum/log_color.dart';

/// Logs socket traffic the way `AppLoggerInterceptor` + `CorextraDevToolsInterceptor` log Dio: console blocks plus DevTools Network rows (filter "Socket").
class CorextraSocketLogger {
  const CorextraSocketLogger({
    required this.url,
    this.consoleEnabled = true,
    this.devToolsEnabled,
    this.captureBody = true,
    this.maxBodyLength = 100000,
  });

  /// The socket server's URL, shown on every captured row.
  final String url;

  /// Pretty console logs, in debug builds only — like `AppLoggerInterceptor.enabled`.
  final bool consoleEnabled;

  /// When `null`, defers to [CorextraDevTools.instance.enabled] — like `CorextraDevToolsInterceptor.enabled`.
  final bool? devToolsEnabled;
  final bool captureBody;

  /// Caps raw string bodies only, same as `CorextraDevToolsInterceptor.maxBodyLength`.
  final int maxBodyLength;

  static const _divider =
      '├─────────────────────────────────────────────────────────────';
  static const _top =
      '┌─────────────────────────────────────────────────────────────';
  static const _bottom =
      '└─────────────────────────────────────────────────────────────';

  bool get _captureEnabled =>
      devToolsEnabled ?? CorextraDevTools.instance.enabled;

  /// Logs a message the app sent without waiting for an ack.
  void emit(String event, Object? data) {
    final payload = _stripCallbacks(data);
    _log(LogColor.blue, 'Emit', '↑  $event', payload);
    final captured = _begin('EMIT', event, requestBody: payload);
    if (captured != null) _complete(captured);
  }

  /// Logs a sent message and its ack; [send] does the real emit and resolves with the ack (or throws on timeout).
  Future<T> emitWithAck<T>(
    String event,
    Object? data,
    Future<T> Function() send,
  ) async {
    final payload = _stripCallbacks(data);
    _log(LogColor.blue, 'Emit', '↑  $event  (awaiting ack)', payload);
    final captured = _begin('EMIT', event, requestBody: payload);
    final startedAt = DateTime.now();

    try {
      final ack = await send();
      final ms = DateTime.now().difference(startedAt).inMilliseconds;
      _log(LogColor.green, 'Ack', '↩  $event  ${ms}ms', ack);
      if (captured != null) _complete(captured, responseBody: ack);
      return ack;
    } catch (e) {
      _log(LogColor.red, 'Ack Error', '✘  $event', e.toString());
      if (captured != null) _complete(captured, error: e);
      rethrow;
    }
  }

  /// Logs a message the server pushed; pass [isError] for failures such as `connect_error`.
  void receive(String event, Object? data, {bool isError = false}) {
    final payload = _stripCallbacks(data);
    _log(
      isError ? LogColor.red : LogColor.green,
      isError ? 'Error' : 'Receive',
      '↓  $event',
      payload,
    );
    final captured = _begin('ON', event);
    if (captured != null) {
      _complete(
        captured,
        responseBody: payload,
        error: isError ? (payload ?? event) : null,
      );
    }
  }

  NetworkEvent? _begin(String method, String event, {Object? requestBody}) {
    if (!_captureEnabled) return null;
    return CorextraDevTools.instance.network.begin(
      method: method,
      url: url,
      socketEvent: event,
      requestBody:
          captureBody ? truncateBody(requestBody, maxBodyLength) : null,
    );
  }

  void _complete(
    NetworkEvent captured, {
    Object? responseBody,
    Object? error,
  }) {
    if (captureBody && responseBody != null) {
      captured.responseBody = truncateBody(responseBody, maxBodyLength);
    }
    if (error != null) {
      captured.errorType = 'socket';
      captured.errorMessage = error.toString();
    }
    captured.completedAt = DateTime.now();
    CorextraDevTools.instance.network.complete(captured);
  }

  void _log(LogColor color, String title, String headline, Object? data) {
    if (!consoleEnabled || !kDebugMode) return;

    final c = color.getValue;
    final r = LogColor.reset.getValue;

    final b = StringBuffer();
    b.writeln('$c$_top Socket $title ───────────────');
    b.writeln('│  $headline');
    b.writeln('│  ⏱  ${DateTime.now().toIso8601String()}');

    if (data != null) {
      b.writeln(_divider);
      b.writeln('│  Data');
      for (final line in boundedPrettyFormatBody(data).split('\n')) {
        b.writeln('│    $line');
      }
    }

    b.write('$_bottom$r');
    dev.log(b.toString(), name: 'SOCKET');
  }

  /// Socket.IO passes the server's ack callback alongside an event's data; it isn't data, so it's dropped before logging.
  static Object? _stripCallbacks(Object? data) {
    if (data is Function) return null;
    if (data is! List || !data.any((e) => e is Function)) return data;
    final args = data.where((e) => e is! Function).toList();
    return args.length == 1 ? args.first : args;
  }
}
