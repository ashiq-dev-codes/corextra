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
- Redesigned the Network tab: colored method/status pills, the request path shown separately from its host/query, headers rendered as a readable key/value list instead of a raw map dump, and request/response bodies shown in a monospace code block with a one-tap copy button
- The Network tab is now responsive: on screens ≥700 logical pixels wide it splits into a master/detail view (a compact request list on the left, the selected request's full detail on the right) — the same layout Flutter's own DevTools Network view uses — while phone-sized screens keep the single-column expandable list
- Added a "Minimize" button in the panel header: instead of closing the panel, it shrinks to a small draggable floating window showing the *same* Network/Logs/Performance/Info tab content as the full panel — not a stripped-down summary — so you can watch live activity while still freely interacting with (and testing) the rest of the app underneath, closer to inspecting a page in a browser. Drag the window by its header to move it; tap Expand to return to the full panel, or Close to dismiss back to the bubble
- Made dragging the bubble and floating window smoother: the dragged content is now built once and reused every frame (only the position updates, via a `ValueListenableBuilder` instead of rebuilding the whole widget on every pixel of movement) and wrapped in a `RepaintBoundary` so moving it is a cheap compositor-level operation — most noticeable on the floating window, whose content is a full tab set
- The bubble and floating window now dock and peek at the screen edge when dragged near one, Android floating-widget style — releasing a drag within 80px of the left or right edge slides it mostly off-screen there, leaving a small "tap to bring back" tab, so it stays out of the way of the app you're testing. Releasing away from either edge leaves it exactly where dropped, as before

## 1.1.5

- Added `AppLoggerInterceptor`: a Dio interceptor that logs requests, responses, and errors in a pretty, bordered, color-coded format — one consolidated block per event
- Added `LogColor` enum with ANSI color codes (`red`, `blue`, `green`, `yellow`, `reset`) for terminal output
- Added `LogLevel` enum (`info`, `warning`, `error`) for structured log levels, each mapped to a distinct color
- Enhanced `debugLog` with `LogLevel` support for color-coded console output
- Enhanced `AppLogger` with detailed structured logging for requests, responses, and Dio errors
- Updated `dio` to `^5.9.2` and `test` to `^1.31.0`

## 1.1.4

- Updated exception classes (`CorextraException` and subclasses) to use Dart 3 super-parameters for cleaner and more maintainable code