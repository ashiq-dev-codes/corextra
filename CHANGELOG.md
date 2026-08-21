## 1.2.0

### In-app DevTools panel

A Flutter-DevTools-style inspector built right into your app — no separate DevTools connection, and it's automatically disabled outside debug builds.

```dart
MaterialApp(
  builder: (context, child) =>
      CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
  home: const HomeScreen(),
)

dio.interceptors.add(const CorextraDevToolsInterceptor());
```

A draggable bubble opens the panel, with four tabs:

- **Network** — every request and response via `CorextraDevToolsInterceptor` (safe to use alongside `AppLoggerInterceptor`). Search by method, URL, or status, and filter by method or status category. Wide screens get a two-pane list + detail view, the same layout Flutter's own DevTools Network tab uses. Redact sensitive headers with `hiddenHeaders`.
- **Logs** — every `debugLog`/`AppLogger` call, live, with the same search and level filters.
- **Performance** — a live FPS and frame-time chart modeled on DevTools' own Performance view: stacked UI/Raster bars, a 60 FPS budget line, jank highlighting, and tap-to-inspect any frame.
- **Info** — app and device details via `package_info_plus`/`device_info_plus`.

Tap **Minimize** to shrink the panel into a small floating window, so you can keep an eye on activity while still testing the rest of the app. Drag the bubble or the floating window to a screen edge to tuck it out of the way (Android-floating-widget style), or resize the floating window from its corner.

### Other changes

- Runtime dependencies (`dio`, `intl`, `device_info_plus`, `package_info_plus`, `lucide_icons_flutter`) now use unbounded `>=` version constraints, so this package never blocks your own dependency resolution.
- Added a runnable example app in `example/`, including the DevTools panel end to end.

## 1.1.5

- Added `AppLoggerInterceptor`: a Dio interceptor that logs requests, responses, and errors in a pretty, bordered, color-coded format — one consolidated block per event
- Added `LogColor` enum with ANSI color codes (`red`, `blue`, `green`, `yellow`, `reset`) for terminal output
- Added `LogLevel` enum (`info`, `warning`, `error`) for structured log levels, each mapped to a distinct color
- Enhanced `debugLog` with `LogLevel` support for color-coded console output
- Enhanced `AppLogger` with detailed structured logging for requests, responses, and Dio errors
- Updated `dio` to `^5.9.2` and `test` to `^1.31.0`

## 1.1.4

- Updated exception classes (`CorextraException` and subclasses) to use Dart 3 super-parameters for cleaner and more maintainable code