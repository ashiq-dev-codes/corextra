import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'models/frame_sample.dart';
import 'models/log_entry.dart';
import 'models/network_event.dart';
import 'models/size_analysis_node.dart';
import 'util/bundle_scan_result.dart';

/// Bounded, FIFO ring buffer of captured [NetworkEvent]s.
class NetworkEventStore extends ChangeNotifier {
  NetworkEventStore({this.maxEntries = 200});

  final int maxEntries;
  final List<NetworkEvent> _events = [];

  /// Most recent events first is left to consumers; this list is kept in
  /// capture order (oldest first).
  List<NetworkEvent> get events => List.unmodifiable(_events);

  /// Records the start of a request and returns the event so the caller
  /// can complete it later via [complete].
  NetworkEvent begin({
    required String method,
    required String url,
    Map<String, String> queryParameters = const {},
    Map<String, String> requestHeaders = const {},
    Object? requestBody,
  }) {
    final event = NetworkEvent(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_events.length}',
      method: method,
      url: url,
      startedAt: DateTime.now(),
      queryParameters: queryParameters,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
    );
    _events.add(event);
    while (_events.length > maxEntries) {
      _events.removeAt(0);
    }
    notifyListeners();
    return event;
  }

  /// Notifies listeners that [event] (already mutated in place by the
  /// caller with response/error fields) has completed.
  void complete(NetworkEvent event) {
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }
}

/// Bounded, FIFO ring buffer of captured [LogEntry]s.
class LogEntryStore extends ChangeNotifier {
  LogEntryStore({this.maxEntries = 500});

  final int maxEntries;
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void add(LogEntry entry) {
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

/// Bounded, FIFO ring buffer of captured [FrameSample]s.
class FrameSampleStore extends ChangeNotifier {
  FrameSampleStore({this.maxEntries = 300});

  final int maxEntries;
  final List<FrameSample> _samples = [];

  /// Approximate resident set size in bytes, if available on this
  /// platform; pushed in periodically from outside this store.
  int? lastRssBytes;

  List<FrameSample> get samples => List.unmodifiable(_samples);

  void add(FrameSample sample) {
    _samples.add(sample);
    while (_samples.length > maxEntries) {
      _samples.removeAt(0);
    }
    notifyListeners();
  }

  /// Average FPS over the most recent [window] samples (~1s at 60Hz).
  double get currentFps {
    if (_samples.isEmpty) return 60;
    final recent = _samples.length > 60
        ? _samples.sublist(_samples.length - 60)
        : _samples;
    final total = recent.fold<double>(0, (sum, s) => sum + s.fps);
    return total / recent.length;
  }

  int recentJankyCount({int window = 60}) {
    final recent = _samples.length > window
        ? _samples.sublist(_samples.length - window)
        : _samples;
    return recent.where((s) => s.isJanky).length;
  }

  void setRssBytes(int? bytes) {
    lastRssBytes = bytes;
    notifyListeners();
  }

  void clear() {
    _samples.clear();
    lastRssBytes = null;
    notifyListeners();
  }
}

/// Holds the most recently opened `--analyze-size` JSON analysis, if any, for the DevTools App Size tab.
class AppSizeStore extends ChangeNotifier {
  SizeAnalysisNode? _root;
  String? _fileName;
  DateTime? _loadedAt;
  String? _platform;
  String? _errorMessage;
  bool _isLive = false;

  SizeAnalysisNode? get root => _root;

  String? get fileName => _fileName;

  DateTime? get loadedAt => _loadedAt;

  /// `apk`, `aab`, `ios`, `macos`, `windows`, or `linux` — from the imported JSON's `type` field, or `Platform.operatingSystem` after [runQuickScan].
  String? get platform => _platform;

  /// True when [root] came from [runQuickScan] (the live installed bundle) rather than an imported `--analyze-size` file.
  bool get isLive => _isLive;

  /// Set when the most recent [loadFromJson] or [runQuickScan] call failed; cleared by the next call, success or not.
  String? get errorMessage => _errorMessage;

  /// Parses [jsonText] (a `*-code-size-analysis_*.json` file's contents) and, if it looks valid, replaces the loaded analysis; on failure, leaves any previously loaded analysis in place and sets [errorMessage].
  void loadFromJson(String jsonText, {required String fileName}) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object at the top level.');
      }
      _setLoaded(
        root: SizeAnalysisNode.fromJson(decoded),
        fileName: fileName,
        platform: decoded['type'] as String?,
        isLive: false,
      );
    } catch (_) {
      _errorMessage = '"$fileName" doesn\'t look like a Flutter size analysis file.';
      notifyListeners();
    }
  }

  /// Runs [scan] (normally [scanInstalledBundle], overridable so callers — e.g. widget tests — can substitute a fake instead of touching the real filesystem) for a live size breakdown; on failure, leaves any previously loaded analysis in place and sets [errorMessage].
  Future<void> runQuickScan(
    Future<BundleScanResult?> Function() scan,
  ) async {
    final result = await scan();
    if (result == null) {
      _errorMessage =
          'Quick scan isn\'t available on this platform yet — use '
          '"Import file" to load a --analyze-size JSON instead.';
      notifyListeners();
      return;
    }
    _setLoaded(
      root: result.root,
      fileName: 'Installed app bundle',
      platform: result.platformLabel,
      isLive: true,
    );
  }

  void _setLoaded({
    required SizeAnalysisNode root,
    required String fileName,
    required String? platform,
    required bool isLive,
  }) {
    _root = root;
    _fileName = fileName;
    _platform = platform;
    _isLive = isLive;
    _loadedAt = DateTime.now();
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _root = null;
    _fileName = null;
    _loadedAt = null;
    _platform = null;
    _isLive = false;
    _errorMessage = null;
    notifyListeners();
  }
}

/// Central, in-memory DevTools store for the current app run.
///
/// Everything captured here lives only in memory and defaults to
/// [kDebugMode] so it can never accidentally stay active in a release
/// build. Toggle at runtime with [enabled]:
/// ```dart
/// CorextraDevTools.instance.enabled = false;
/// ```
class CorextraDevTools {
  CorextraDevTools._internal();

  static final CorextraDevTools instance = CorextraDevTools._internal();

  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(kDebugMode);

  bool get enabled => enabledNotifier.value;

  set enabled(bool value) => enabledNotifier.value = value;

  /// The DevTools panel's own theme — independent of the host app's
  /// theme. Defaults to dark; toggle with a light/dark [ThemeMode] via
  /// the panel's theme switcher, or set directly:
  /// ```dart
  /// CorextraDevTools.instance.themeMode = ThemeMode.light;
  /// ```
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  ThemeMode get themeMode => themeModeNotifier.value;

  set themeMode(ThemeMode value) => themeModeNotifier.value = value;

  final NetworkEventStore network = NetworkEventStore();
  final LogEntryStore logs = LogEntryStore();
  final FrameSampleStore performance = FrameSampleStore();
  final AppSizeStore appSize = AppSizeStore();

  /// Clears all captured data. Does not change [enabled].
  void resetAll() {
    network.clear();
    logs.clear();
    performance.clear();
    appSize.clear();
  }
}
