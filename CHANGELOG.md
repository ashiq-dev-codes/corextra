## 1.3.0

- New **Models** feature: write API models without `build_runner` or code generation. See [Models](README.md#models).
- `CorextraJsonModel` — declare each field once as a typed getter (`int? get id => read('id')`) and get safe parsing, `toJson()`, `==`, `hashCode` and `toString` for free. Reads loose API values like `"7"` or `1` for `true`, never throws on bad data, and supports nested models, lists, enums, fallback keys, nested paths like `'user.name'`, JSON sent as text, Unix timestamps and custom date formats.
- `CorextraDataClass` — `==`, `hashCode` and a readable `toString` for classes with normal fields, comparing lists and maps by their contents.
- `CorextraSortable` — makes `list.sort()`, `<` and `>` work by the fields you pick.
- `CorextraValidatable` — `validation.isValid`, `validation.errors` and `validation.firstError` using your `FormValidators`.
- All four are mixins, so your classes can still extend any base class.
- `toTryInt()`, `toTryDouble()`, `toTryBool()` and `toTryDateTime()` now ignore spaces around the value.
- `toTryBool()` now also accepts `yes` / `no` in any letter case.
- **Breaking:** `toTryBool()` now returns `null` for text it doesn't recognize (like `'maybe'` or `'2'`) instead of `false`. Use `value.toTryBool() ?? false` to keep the old result.
- DevTools and Models APIs now have usage examples in their docs, shown when you hover in your IDE and on pub.dev.
- DevTools files moved into clearer folders. Every class keeps its name, so apps that import `package:corextra/corextra.dart` need no changes. If you import a DevTools file directly, update its path.

## 1.2.11

- DevTools has a new **Find** box that searches every tab at once: URLs, headers, request and response bodies, logs, and app info. Every match is highlighted like a browser's find — press **Enter** or the arrows to jump between them, and DevTools opens the right tab, request, and section for you. It replaces the separate Network and Logs search boxes.
- DevTools and logging no longer slow your app down, even with constant API traffic: console logs are formatted between frames instead of inside your requests, the panel refreshes a few times a second at most, and huge responses open instantly.
- The Network and Logs lists now have the same easy-to-grab scrollbar as response bodies.
- `AppLogger` now limits how much request and response data it logs, so a huge body can't stall your app.
- Very long log messages are shortened in the **Logs** tab; the console still shows them in full.
- Plain-text bodies are now selectable one line at a time. **Copy** still copies the whole body.
- **Breaking:** removed the DevTools **Performance** tab, along with `PerformanceTab`, `FrameSample`, `FrameSampleStore`, and `CorextraDevTools.instance.performance`. DevTools no longer tracks frame timings or memory in the background.

## 1.2.10

- Now WebAssembly (WASM) compatible — supports all 6 platforms: Android, iOS, Web, macOS, Windows, and Linux.
- DevTools on web: **Share** opens the browser's share sheet (or copies to the clipboard if there isn't one), and the **Info** tab shows your app version and browser.
- No changes on Android, iOS, macOS, Windows, or Linux.

## 1.2.9

- Added `CorextraSocketLogger` — logs socket messages to the console and DevTools. Works with Socket.IO or any WebSocket.
- The DevTools **Network** tab now shows socket messages, with a new **Socket** filter.
- Large bodies now scroll inside their own box, with easy-to-grab scrollbars: drag along the edge, or tap it to jump.
- The Copy, Share, and Fullscreen buttons stay in view while you scroll a body.
- Added `NetworkEvent.socketEvent` and `NetworkEvent.isSocket`.
- Fixed: `debugLog` messages now show in the DevTools Logs tab in release (QA) builds too, when DevTools is enabled.

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
