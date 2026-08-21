/// A single captured HTTP request/response (or error) exchange.
class NetworkEvent {
  NetworkEvent({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    this.requestHeaders = const {},
    this.requestBody,
  });

  final String id;
  final String method;
  final String url;
  final DateTime startedAt;
  final Map<String, String> requestHeaders;
  final Object? requestBody;

  int? statusCode;
  String? statusMessage;
  Map<String, String> responseHeaders = const {};
  Object? responseBody;
  DateTime? completedAt;
  String? errorType;
  String? errorMessage;

  bool get isPending => completedAt == null;

  bool get isError => errorMessage != null;

  Duration? get duration => completedAt?.difference(startedAt);
}
