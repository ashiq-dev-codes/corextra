/// Base class for all custom exceptions in the package.
abstract class CorextraException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const CorextraException({required this.message, this.code, this.details});

  @override
  String toString() {
    final detailsPart = details != null ? ' - Details: $details' : '';
    return '[${code ?? 'ERROR'}] $message$detailsPart';
  }
}

/// Exception for network-related errors
class CorextraNetworkException extends CorextraException {
  const CorextraNetworkException({
    String? code,
    String? message,
    super.details, // <- super parameter
  }) : super(
         code: code ?? 'NETWORK_ERROR',
         message: message ?? 'A network error occurred!',
       );
}

/// Exception for server-related errors
class CorextraServerException extends CorextraException {
  const CorextraServerException({
    String? code,
    String? message,
    super.details, // <- super parameter
  }) : super(
         code: code ?? 'SERVER_ERROR',
         message: message ?? 'A server error occurred!',
       );
}

/// Generic or custom application errors
class CorextraCustomException extends CorextraException {
  const CorextraCustomException({
    String? code,
    String? message,
    super.details, // <- super parameter
  }) : super(
         code: code ?? 'CUSTOM_ERROR',
         message: message ?? 'Something went wrong!',
       );
}

/// Exception for forced app updates
class CorextraNewVersionException extends CorextraException {
  const CorextraNewVersionException({
    String? message,
    super.details, // <- super parameter
  }) : super(
         code: 'NEW_VERSION_REQUIRED',
         message: message ?? 'A new version of the app is required!',
       );
}

/// Exception for unknown/general errors
class CorextraGeneralException extends CorextraException {
  const CorextraGeneralException({
    String? message,
    super.details, // <- super parameter
  }) : super(
         code: 'GENERAL_ERROR',
         message: message ?? 'An unexpected error occurred!',
       );
}
