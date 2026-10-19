part of 'network_tab.dart';

// ---------------- Body data ----------------

/// A body decoded and split into lines once per request, then shared by the view, find and Copy, so a busy app never redoes it.
class _Body {
  _Body._(this.data, this.lines, this._json);

  factory _Body.of(Object? data) {
    final json = _decodeJson(data);
    if (json != null) {
      try {
        return _Body._(data, _flattenJson(json), json);
      } catch (_) {
        // A value JSON can't encode — show it as plain text below.
      }
    }
    final text = prettyFormatBody(data);
    return _Body._(data, [
      for (final line in text.split('\n')) _CodeLine.text(line),
    ], null);
  }

  final Object? data;
  final List<_CodeLine> lines;
  final Object? _json;

  bool get isJson => _json != null;

  late final List<String> plainLines = [
    for (final line in lines) line.plainText,
  ];

  /// Encoded only when Copy or Share is tapped, never just to show the body.
  String copyText() {
    if (_json != null) {
      try {
        return const JsonEncoder.withIndent('  ').convert(_json);
      } catch (_) {
        // Falls through to the lines as shown.
      }
    }
    return plainLines.join('\n');
  }

  final Map<double, double> _widths = {};

  /// Monospace, so a line's width is its character count; wide characters like CJK and emoji count double.
  double contentWidth(double charWidth) =>
      _widths[charWidth] ??= () {
        var widest = 0.0;
        for (final line in lines) {
          var units = line.plainText.length + line.collapsedExtraChars;
          for (final unit in line.plainText.codeUnits) {
            if (unit >= 0x1100) units++;
          }
          widest = math.max(widest, line.indent + units * charWidth);
        }
        return widest;
      }();
}

/// The body as a JSON object or array, or null when it isn't one.
Object? _decodeJson(Object? data) {
  if (data is Map || data is List) return data;
  if (data is! String) return null;
  try {
    final value = jsonDecode(data);
    return value is Map || value is List ? value : null;
  } catch (_) {
    return null;
  }
}

final _bodyCache = Expando<Map<_Section, _Body>>();

/// Cached on the request itself, so it's freed along with it once the request leaves the capture buffer.
_Body _bodyOf(NetworkEvent event, _Section section) {
  final data = switch (section) {
    _Section.query => event.queryParameters,
    _Section.requestBody => event.requestBody,
    _ => event.responseBody,
  };
  final cache = _bodyCache[event] ??= {};
  final cached = cache[section];
  if (cached != null && identical(cached.data, data)) return cached;
  return cache[section] = _Body.of(data);
}

// ---------------- Body view ----------------

/// Shows a request body as a collapsible JSON tree when it decodes to an object or array, falling back to plain lines otherwise.
class _BodyView extends StatelessWidget {
  const _BodyView({
    required this.event,
    required this.section,
    required this.title,
    this.maxHeight = double.infinity,
    this.onScroll,
  });

  final NetworkEvent event;
  final _Section section;
  final String title;

  /// A body taller than this scrolls inside its own block rather than growing past it.
  final double maxHeight;
  final void Function(double offset, ScrollDirection direction)? onScroll;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: _CodeView(
        body: _bodyOf(event, section),
        title: title,
        findPrefix: _findPrefix(event, section),
        onScroll: onScroll,
      ),
    );
  }
}
