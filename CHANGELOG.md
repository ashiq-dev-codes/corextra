## 1.2.1

### Network tab: query parameters, and a redesigned detail view

Query parameters sent on a request are now captured and shown in their own **Query Parameters** block — previously they were silently dropped and never visible anywhere in the panel.

The request/response detail view is now laid out browser-DevTools-style, with **Headers / Payload / Response** tabs instead of one long scrolling stack:

- **Headers** — the full URL, any error message, and request/response headers.
- **Payload** — query parameters and the request body.
- **Response** — the response body on its own.

Each tab scrolls independently, which also fixes two real bugs from the old single-stack layout:

- A request/response body large enough to be truncated (past the interceptor's `maxBodyLength`) no longer collapses into a single unreadable line — the truncated text now stays properly indented JSON right up to the cutoff.
- A long error message or URL could overflow the detail view, especially inside the floating (PIP) window at its minimum size. The fixed summary above the tabs is now capped to short, constant-height content (method, path, status, duration, time); the full URL and any error message live in the Headers tab instead.

Binary response bodies (`Uint8List`, e.g. `ResponseType.bytes`) now show a byte count and hex preview instead of a JSON array of every byte value, and multipart `FormData` request bodies show their actual field values and file metadata instead of `Instance of 'FormData'`.

On a phone-width screen, tapping a request now drills into a full-screen detail view with a Back button, instead of expanding inline in the same list — this removes a scroll conflict between the request list and a large response body.

### Every DevTools tab now has a "scroll to top" button

A small floating button appears once you've scrolled down a captured list (requests, logs, ...), and jumps back to the top in one tap.

### Other changes

- The floating (PIP) window's resize handle now requires a press-and-hold before dragging, so a bare tap-drag near the corner no longer resizes it by accident.
- The request list's path text now wraps up to 3 lines with ellipsis overflow (previously 1), so a long path is easier to identify at a glance.
- The example app now exercises every case above: query parameters, PUT/PATCH/DELETE, a raw text body, multipart `FormData`, a binary response, an HTML response, and a response guaranteed to trigger truncation.

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