import 'package:flutter/foundation.dart';

import '../models/network_event.dart';

/// The requests DevTools has captured, oldest first, capped at [maxEntries].
///
/// Example:
/// ```dart
/// final events = CorextraDevTools.instance.network.events;
/// print('${events.length} requests captured');
/// ```
class NetworkEventStore extends ChangeNotifier {
  /// Creates a store that keeps the newest [maxEntries] requests.
  NetworkEventStore({this.maxEntries = 200});

  // ---------------- Data ----------------

  /// The most requests kept; the oldest is dropped when a new one arrives.
  final int maxEntries;

  final List<NetworkEvent> _events = [];

  /// Every captured request in capture order, oldest first.
  ///
  /// Example:
  /// ```dart
  /// final failed = CorextraDevTools.instance.network.events.where((e) => e.isError);
  /// ```
  List<NetworkEvent> get events => List.unmodifiable(_events);

  // ---------------- Recording ----------------

  /// Records a request that just started and returns it, so you can [complete] it later.
  ///
  /// Use it to show traffic from a client other than Dio; Dio apps use `CorextraDevToolsInterceptor` instead.
  ///
  /// Example:
  /// ```dart
  /// final store = CorextraDevTools.instance.network;
  /// final event = store.begin(method: 'GET', url: 'https://api.example.com/users');
  /// final response = await http.get(Uri.parse(event.url));
  /// event
  ///   ..statusCode = response.statusCode
  ///   ..responseBody = response.body
  ///   ..completedAt = DateTime.now();
  /// store.complete(event);
  /// ```
  NetworkEvent begin({
    required String method,
    required String url,
    Map<String, String> queryParameters = const {},
    Map<String, String> requestHeaders = const {},
    Object? requestBody,
    Set<String> hiddenHeaderKeys = const {},
    String? socketEvent,
  }) {
    final event = NetworkEvent(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_events.length}',
      method: method,
      url: url,
      startedAt: DateTime.now(),
      queryParameters: queryParameters,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      hiddenHeaderKeys: hiddenHeaderKeys,
      socketEvent: socketEvent,
    );
    _events.add(event);
    while (_events.length > maxEntries) {
      _events.removeAt(0);
    }
    notifyListeners();
    return event;
  }

  /// Marks [event] as finished after you've set its response or error fields, so the panel updates; see [begin].
  void complete(NetworkEvent event) {
    notifyListeners();
  }

  /// Removes every captured request.
  ///
  /// Example:
  /// ```dart
  /// CorextraDevTools.instance.network.clear();
  /// ```
  void clear() {
    _events.clear();
    notifyListeners();
  }
}
