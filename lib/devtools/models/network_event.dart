/// A single captured HTTP request/response (or error) exchange, or one socket message when [socketEvent] is set.
class NetworkEvent {
  NetworkEvent({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    this.queryParameters = const {},
    this.requestHeaders = const {},
    this.requestBody,
    this.hiddenHeaderKeys = const {},
    this.socketEvent,
  });

  final String id;

  /// The HTTP method, or for a socket message its direction: `EMIT` (sent by the app) or `ON` (pushed by the server).
  final String method;

  /// The request URL, or for a socket message the socket server's URL.
  final String url;
  final DateTime startedAt;
  final Map<String, String> queryParameters;
  final Map<String, String> requestHeaders;
  final Object? requestBody;

  /// Lowercase header names (from `CorextraDevToolsInterceptor.hiddenHeaders`) the panel should mask on screen — the real values above are kept as-is so Copy still works.
  final Set<String> hiddenHeaderKeys;

  /// The socket event name (e.g. `message:new`), or `null` for HTTP.
  final String? socketEvent;

  int? statusCode;
  String? statusMessage;
  Map<String, String> responseHeaders = const {};
  Object? responseBody;
  DateTime? completedAt;
  String? errorType;
  String? errorMessage;

  bool get isPending => completedAt == null;

  bool get isError => errorMessage != null;

  bool get isSocket => socketEvent != null;

  Duration? get duration => completedAt?.difference(startedAt);
}
