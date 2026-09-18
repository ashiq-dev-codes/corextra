## 1.2.8

- Fixed: DevTools network capture no longer blocks the UI thread. Bodies are now formatted only when a request is opened in the panel, not on every capture.
- Fixed: `AppLoggerInterceptor` no longer fully encodes huge bodies — pretty-printing is now capped by a work budget.

## 1.2.7

- Masked headers now show a short preview (e.g. `***ab12`) instead of a flat mask. Copy and the new **Share** button always use the real value.
- The summary bar above the tabs shrinks while scrolling, freeing up space on small screens.
- Payload and Response bodies get a **fullscreen** viewer.
- Collapsible JSON tree: bigger fold targets, and every line is now selectable and copyable.
- Default body capture limit raised from 20,000 to 100,000 characters.
- Android's back button now closes the DevTools panel (or its fullscreen/detail view) before it reaches the host app's navigation.

## 1.2.6

- Sensitive headers (`Authorization`, `Cookie`, `X-Api-Key`, etc.) get a **TOKEN** badge and copy button.
- JSON bodies render as a collapsible tree with **Expand all** / **Collapse all**.
- Colors now adapt to light and dark mode; long lines scroll horizontally.

## 1.2.5

- Added `deviceType` (`mobile` / `tablet` / `desktop`) with `isMobile` / `isTablet` / `isDesktop` shortcuts.
- Added `responsive<T>()` to pick a value per breakpoint without a `LayoutBuilder`.
- Added `screenWidth`, `screenHeight`, `isPortrait`, `isLandscape` on `BuildContext`.
- Added `FormValidators.compose([...])` to chain validators, and `FormValidators.optional()` for non-required fields.
- Added `minLength`, `maxLength`, `numeric`, `url`, and `pattern` validators.
- Every validator now accepts a `message:` override.
- Fixed: `email` validation now accepts real addresses (e.g. `user+tag@gmail.com`, long TLDs like `.technology`).

## 1.2.4

- Reverted the App Size tab added in 1.2.3 — it required a native Android plugin that broke builds on older toolchains. The package is pure Dart/Flutter again.

## 1.2.3

- DevTools tab bar redesign: **Network**, **Logs**, **Info** stay visible; **Performance** moved behind a **More** button.
- Fixed: swiping no longer switches tabs by accident.

## 1.2.2

- Example app rebuilt with a clean architecture and a Material 3 UI.
- DevTools Network scenarios now cover realistic error cases (4xx/5xx, malformed payloads, connectivity failures).
- Added a Logs section to the example app.
- Fixed: `capitalize()` no longer collapses repeated internal whitespace.

## 1.2.1

- Query parameters are now captured and shown in their own tab.
- Request/response detail view redesigned with **Headers / Payload / Response** tabs.
- Binary bodies show a byte count and hex preview; `FormData` bodies show real field values.
- Phone-width screens now drill into a full-screen detail view.
- Every tab gets a "scroll to top" button.
- Fixed: the floating window's resize handle now requires press-and-hold, preventing accidental resizing.

## 1.2.0

- Added an in-app DevTools panel (**Network**, **Logs**, **Performance**, **Info**) — no separate DevTools connection needed.
- Runtime dependencies now use unbounded version constraints.
- Added a runnable example app.

## 1.1.5

- Added `AppLoggerInterceptor`: pretty, color-coded Dio request/response/error logging.
- Added `LogColor` and `LogLevel` enums.
- Enhanced `debugLog` and `AppLogger` with level support.

## 1.1.4

- Updated exception classes to use Dart 3 super-parameters.
