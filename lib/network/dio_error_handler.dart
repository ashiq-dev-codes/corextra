import 'package:dio/dio.dart';

import '../exceptions/corextra_exceptions.dart';

/// Utility helper for Dio-related features like
/// error handling, logging, and potential future enhancements.
class DioErrorHandler {
  /// Returns a user-friendly message for a given DioException.
  static String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet and try again.';
      case DioExceptionType.sendTimeout:
        return 'The request took too long to send. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.badResponse:
        return 'Received an invalid response from the server.';
      case DioExceptionType.cancel:
        return 'The request was canceled.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server. Please check your network.';
      case DioExceptionType.unknown:
      default:
        return 'Something went wrong. Please try again later.';
    }
  }

  /// Throws a [CorextraServerException] with a user-friendly message.
  static void handleError(DioException error) {
    throw CorextraNetworkException(
      message: getErrorMessage(error),
      details: {
        'statusCode': error.response?.statusCode,
        'data': error.response?.data,
      },
    );
  }
}
