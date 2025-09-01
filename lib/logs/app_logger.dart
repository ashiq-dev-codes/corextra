import 'package:dio/dio.dart';

import 'debug_log.dart'; // Import debugLog for internal logging

/// AppLogger provides structured logging for app events, Dio requests, responses, and errors.
class AppLogger {
  /// Logs a generic error with optional type
  static Future<void> logError(String message, {String? type}) async {
    final logType = type ?? 'Error';
    final timestamp = DateTime.now().toIso8601String();

    debugLog('------ $logType ------', level: LogLevel.error);
    debugLog('Timestamp: $timestamp', level: LogLevel.error);
    debugLog('Message: $message', level: LogLevel.error);
    debugLog('------ End $logType ------', level: LogLevel.error);
  }

  /// Logs a Dio request
  static Future<void> logRequest(
    String baseUrl,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    debugLog('------ App Request ------', level: LogLevel.info);
    debugLog('Timestamp: $timestamp', level: LogLevel.info);
    debugLog('URL: $baseUrl', level: LogLevel.info);
    debugLog('Path: $path', level: LogLevel.info);
    debugLog('Query: ${query ?? 'None'}', level: LogLevel.info);
    debugLog('Headers: ${headers ?? 'None'}', level: LogLevel.info);
    debugLog('Data: ${data ?? 'None'}', level: LogLevel.info);
    debugLog('------ End App Request ------', level: LogLevel.info);
  }

  /// Logs a Dio response
  static Future<void> logResponse(Response response) async {
    final request = response.requestOptions;
    final timestamp = DateTime.now().toIso8601String();

    debugLog('------ App Response ------', level: LogLevel.info);
    debugLog('Timestamp: $timestamp', level: LogLevel.info);
    debugLog('URL: ${request.baseUrl}', level: LogLevel.info);
    debugLog('Path: ${request.path}', level: LogLevel.info);
    debugLog(
      'Query: ${request.queryParameters.isNotEmpty ? request.queryParameters : 'None'}',
      level: LogLevel.info,
    );
    debugLog('Headers: ${request.headers}', level: LogLevel.info);
    debugLog('Status: ${response.statusCode ?? 'N/A'}', level: LogLevel.info);
    debugLog(
      'Status Message: ${response.statusMessage ?? 'N/A'}',
      level: LogLevel.info,
    );
    debugLog('Response Data: ${response.data ?? 'N/A'}', level: LogLevel.info);
    debugLog('------ End App Response ------', level: LogLevel.info);
  }

  /// Logs a Dio error
  static Future<void> logDioError(DioException error) async {
    final response = error.response;
    final request = error.requestOptions;
    final timestamp = DateTime.now().toIso8601String();

    debugLog('------ Dio Error ------', level: LogLevel.error);
    debugLog('Timestamp: $timestamp', level: LogLevel.error);
    debugLog('Error: $error', level: LogLevel.error);
    debugLog(
      'Message: ${error.message ?? 'No message available'}',
      level: LogLevel.error,
    );

    // Request info
    debugLog('Request URL: ${request.baseUrl}', level: LogLevel.error);
    debugLog('Request Path: ${request.path}', level: LogLevel.error);
    debugLog(
      'Request Query: ${request.queryParameters.isNotEmpty ? request.queryParameters : 'None'}',
      level: LogLevel.error,
    );
    debugLog('Request Headers: ${request.headers}', level: LogLevel.error);
    debugLog('Request Data: ${request.data ?? 'None'}', level: LogLevel.error);

    // Response info
    if (response != null) {
      debugLog(
        'Response Status: ${response.statusCode ?? 'N/A'}',
        level: LogLevel.error,
      );
      debugLog(
        'Response Status Message: ${response.statusMessage ?? 'N/A'}',
        level: LogLevel.error,
      );
      debugLog(
        'Response Data: ${response.data ?? 'N/A'}',
        level: LogLevel.error,
      );
      debugLog(
        'Response Headers: ${response.headers.map}',
        level: LogLevel.error,
      );
    } else {
      debugLog('No response available', level: LogLevel.error);
    }

    debugLog('------ End Dio Error ------', level: LogLevel.error);
  }
}
