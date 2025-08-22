/// Base class for all custom exceptions in `corextra`.
/// Provides optional error code, readable message, and additional details.
abstract class CorextraException implements Exception {
  const CorextraException({required this.message, this.code, this.details});
  final String? code;
  final String message;
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final detailsPart = details != null ? ' - Details: $details' : '';
    return '[${code ?? 'ERROR'}] $message$detailsPart';
  }
}

/// Exception for network-related errors (Dio, HTTP, etc.).
class CorextraNetworkException extends CorextraException {
  const CorextraNetworkException({String? code, String? message, super.details})
    : super(
        code: code ?? 'NETWORK_ERROR',
        message: message ?? 'A network error occurred!',
      );
}

/// Generic or custom application errors.
class CorextraCustomException extends CorextraException {
  const CorextraCustomException({String? code, String? message, super.details})
    : super(
        code: code ?? 'CUSTOM_ERROR',
        message: message ?? 'Something went wrong!',
      );
}
