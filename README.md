# corextra

Handy Dart extensions and utilities for Flutter — plus form validators, responsive helpers, logging, and an in-app DevTools panel.

[![pub package](https://img.shields.io/pub/v/corextra.svg)](https://pub.dev/packages/corextra)

Works on **Android, iOS, Web (including WASM), macOS, Windows, and Linux**.

---

## Getting Started

Add the dependency:

```yaml
dependencies:
  corextra: ^1.2.10
```

Import it:

```dart
import 'package:corextra/corextra.dart';
```

---

## Features

### Extensions
- Null-safe checks: `.isNullOrEmpty` on `String?` and `List?`
- Safe conversions: `.toTryInt()`, `.toTryDouble()`, `.toTryBool()`
- String helpers: `.capitalize()`, `.toPascalCase()`, `.toCamelCase()`
- DateTime parsing and formatting
- `safeSetState` — calls `setState()` only if the widget is still mounted

### Form Validators
- `required`, `email`, `phone`, `otp`, `password`, `confirmPassword`
- `minLength`, `maxLength`, `numeric`, `url`, `pattern`
- `FormValidators.compose([...])` — run several validators, return the first error
- `FormValidators.optional(validator)` — skip validation when a non-required field is empty
- Every validator accepts a custom `message:`
- Optional translations via `easy_localization`

### Responsive
- `ResponsiveBreakpoints` — `sm` / `md` / `lg` / `xl` / `xxl` on `BuildContext` or `BoxConstraints`
- `deviceType`, `isMobile`, `isTablet`, `isDesktop`
- `responsive<T>(base: ..., md: ..., lg: ...)` — pick a value per screen size, no `LayoutBuilder` needed
- `screenWidth`, `screenHeight`, `isPortrait`, `isLandscape` on `BuildContext`

### Error Handling
- `CorextraException`, `CorextraCustomException`, `CorextraNetworkException`
- `DioErrorHandler` — turns Dio errors into clear, typed exceptions

### Logging
- `debugLog` — simple logger with levels (`info` / `warning` / `error`). Prints in debug builds and shows in the DevTools Logs tab
- `AppLogger` — structured logs for app events and Dio requests
- `AppLoggerInterceptor` — pretty, color-coded Dio logs (turn off with `enabled: false`)
- `CorextraSocketLogger` — logs socket messages to the console **and** DevTools. See [Socket Logging](#socket-logging)

### Animation
- `FadeSlideTransition` — fade + slide in from `top`, `bottom`, `left`, `right`, or a `custom` offset

---

## DevTools Panel

An in-app inspector, like Flutter DevTools but inside your app. No extra setup or connection needed.

```dart
MaterialApp(
  builder: (context, child) =>
      CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
  home: const HomeScreen(),
)

dio.interceptors.add(const CorextraDevToolsInterceptor());
```

Tap the floating bubble to open the panel.

| Tab | What it shows |
|---|---|
| **Network** | Every HTTP request and socket message. Search and filter by method or status. |
| **Logs** | Every `debugLog` / `AppLogger` call. Search and filter by level. |
| **Info** | App version and device details (the browser, on web). |
| **Performance** (under **More**) | Live FPS chart with jank highlighting. |

**In the Network tab:**
- Headers, query params, and body each get their own tab
- JSON shows as a collapsible, color-coded tree
- Large bodies scroll inside their own box — drag along the edge to scroll, or tap the edge to jump
- Copy, Share, and Fullscreen buttons stay in view while you scroll
- Auth headers (`Authorization`, `Cookie`, …) get a **TOKEN** badge. Hide their values on screen with `hiddenHeaders` — Copy still gives the real value

**Good to know:**
- Tap **Minimize** to shrink the panel into a small floating window
- Android's back button closes the panel step by step, without affecting your app
- On web, **Share** opens the browser's share sheet, or copies to the clipboard if the browser doesn't have one
- On in debug builds, off in release. Change it anytime with `CorextraDevTools.instance.enabled = true`

Coming later: widget inspector, memory snapshots, storage viewer, and route inspector.

---

## Socket Logging

`CorextraSocketLogger` logs every socket message in two places:

- **Console** — a color-coded block per message (debug builds only)
- **DevTools** — a row in the **Network** tab (filter by **Socket**)

It works with any socket library (Socket.IO, WebSocket, etc.). Call it wherever you send or receive:

```dart
final logger = CorextraSocketLogger(url: socketUrl);

// Messages from the server
socket.onAny((event, [data]) => logger.receive(event, data));
socket.onConnectError((error) => logger.receive('connect_error', error, isError: true));

// Messages you send
logger.emit('chat:open', payload);
socket.emit('chat:open', payload);

// Messages you send and wait for a reply (ack)
final ack = await logger.emitWithAck(
  'chat:latest_messages',
  payload,
  () => socket.timeout(15000).emitWithAckAsync('chat:latest_messages', payload),
);
```

Each row in DevTools shows the event name, `EMIT` (sent) or `ON` (received), and its status: `OK`, `ERR`, or pending while waiting for an ack.

| Option | Default | What it does |
|---|---|---|
| `consoleEnabled` | `true` | Turn console logs on or off |
| `devToolsEnabled` | follows `CorextraDevTools.instance.enabled` | Turn DevTools capture on or off |
| `captureBody` | `true` | Save message data in DevTools |
| `maxBodyLength` | `100000` | Trims text messages longer than this |

---

## Example

A runnable demo app, including the DevTools panel, lives in [`example/`](example/):

```sh
cd example
flutter pub get
flutter run
```
