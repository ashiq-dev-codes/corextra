## 1.2.0

- Added an in-app DevTools panel (`CorextraDevToolsOverlay`) with Network, Logs, Performance, and Info tabs — no separate DevTools connection required
- Added `CorextraDevToolsInterceptor`, a Dio interceptor that feeds the Network tab (additive to `AppLoggerInterceptor`)
- `debugLog`/`AppLogger` now automatically feed the panel's Logs tab when DevTools capture is enabled
- Added `device_info_plus` and `package_info_plus` dependencies for the Info tab
- `CorextraDevToolsInterceptor` now accepts `hiddenHeaders` to redact sensitive header values (e.g. API keys, auth tokens) before they're stored
- Fixed a crash ("No Overlay widget found") and layout overflow in the DevTools panel when `CorextraDevToolsOverlay` is mounted via `MaterialApp.builder` (the documented, recommended usage) — the panel now runs inside its own self-contained `Overlay`, only while it's actually open, giving tooltips an `Overlay` to attach to and the panel a concrete, finite size to lay out against
- Fixed the DevTools bubble blocking all taps/scrolls to the host app: it had been kept inside an always-mounted, screen-sized `Overlay`/`Navigator`, which claims hit-testing across its entire bounds even where nothing is drawn. The bubble no longer has an ancestor `Overlay` (and no longer has a `Tooltip`, which requires one) — it now only ever occupies its own small hit-testable area
- Polished the DevTools panel UI: icon-labeled tabs, consistent empty states, clearer log/network rows with timestamps, and a performance legend
- Added a runnable example app in `example/` (previously a doc-only snippet), demonstrating the DevTools panel end to end
- The DevTools panel now has its own theme (dark by default), independent of the host app's theme, with a light/dark toggle in the header
- Switched the DevTools panel's icons to `lucide_icons_flutter`

## 1.1.5

- Added `AppLoggerInterceptor`: a Dio interceptor that logs requests, responses, and errors in a pretty, bordered, color-coded format — one consolidated block per event
- Added `LogColor` enum with ANSI color codes (`red`, `blue`, `green`, `yellow`, `reset`) for terminal output
- Added `LogLevel` enum (`info`, `warning`, `error`) for structured log levels, each mapped to a distinct color
- Enhanced `debugLog` with `LogLevel` support for color-coded console output
- Enhanced `AppLogger` with detailed structured logging for requests, responses, and Dio errors
- Updated `dio` to `^5.9.2` and `test` to `^1.31.0`

## 1.1.4

- Updated exception classes (`CorextraException` and subclasses) to use Dart 3 super-parameters for cleaner and more maintainable code