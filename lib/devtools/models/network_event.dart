/// One captured HTTP request and its response or error, or one socket message when [socketEvent] is set.
///
/// Example:
/// ```dart
/// for (final event in CorextraDevTools.instance.network.events) {
///   print('${event.method} ${event.url} → ${event.statusCode} in ${event.duration?.inMilliseconds} ms');
/// }
/// ```
class NetworkEvent {
  /// Creates a captured request; usually made for you by `NetworkEventStore.begin`.
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

  // ---------------- Request ----------------

  /// A unique id for this capture.
  final String id;

  /// The HTTP method, or for a socket message its direction: `EMIT` (sent by the app) or `ON` (pushed by the server).
  final String method;

  /// The request URL, or for a socket message the socket server's URL.
  final String url;

  /// When the request started.
  final DateTime startedAt;

  /// The query parameters sent.
  final Map<String, String> queryParameters;

  /// The request headers sent, with their real values.
  final Map<String, String> requestHeaders;

  /// The request body sent.
  final Object? requestBody;

  /// Lowercase header names the panel masks on screen; the real values are kept so Copy still works.
  final Set<String> hiddenHeaderKeys;

  /// The socket event name, like `message:new`, or null for HTTP.
  final String? socketEvent;

  // ---------------- Response ----------------

  /// The HTTP status code, or null while pending or when it failed before a response.
  int? statusCode;

  /// The HTTP status message, like `OK`.
  String? statusMessage;

  /// The response headers received.
  Map<String, String> responseHeaders = const {};

  /// The response body received.
  Object? responseBody;

  /// When the request finished, or null while it's still pending.
  DateTime? completedAt;

  /// The kind of failure, like `connectionTimeout`, or null when it succeeded.
  String? errorType;

  /// What went wrong, or null when it succeeded.
  String? errorMessage;

  // ---------------- Status ----------------

  /// Whether it's still waiting for a response.
  bool get isPending => completedAt == null;

  /// Whether it failed.
  bool get isError => errorMessage != null;

  /// Whether it's a socket message rather than an HTTP request.
  bool get isSocket => socketEvent != null;

  /// How long it took, or null while it's still pending.
  Duration? get duration => completedAt?.difference(startedAt);
}
