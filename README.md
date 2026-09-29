# corextra

Handy Dart extensions and utility functions for `String`, `int`, `double`, `List`, and more — plus form validators, responsive helpers, logging, and an in-app DevTools panel.

[![pub package](https://img.shields.io/pub/v/corextra.svg)](https://pub.dev/packages/corextra)

---

## Features

### Core Extensions
- Null-safe checks like `.isNullOrEmpty` on `String?` and `List?`
- Safe conversions: `.toTryInt()`, `.toTryDouble()`, `.toTryBool()`
- String helpers: `.capitalize()`, `.toPascalCase()`, `.toCamelCase()`
- DateTime parsing and formatting
- `safeSetState`: calls `setState()` only if the widget is still mounted

### Form Validators
- `required`, `email`, `phone`, `otp`, `password`, `confirmPassword`
- `minLength`, `maxLength`, `numeric`, `url`, `pattern`
- `FormValidators.compose([...])` — chain validators, returns the first error
- `FormValidators.optional(validator)` — skip validation on empty, non-required fields
- Every validator takes an optional `message:` override
- Optional translation support via `easy_localization`

### Responsive Utilities
- `ResponsiveBreakpoints`: `sm` / `md` / `lg` / `xl` / `xxl` helpers on `BuildContext` or `BoxConstraints`
- `deviceType`, `isMobile`, `isTablet`, `isDesktop` — coarse device classification
- `responsive<T>(base: ..., md: ..., lg: ...)` — pick a value per breakpoint, no `LayoutBuilder` needed
- `screenWidth`, `screenHeight`, `isPortrait`, `isLandscape` on `BuildContext`

### Error Handling
- `CorextraException`, `CorextraCustomException`, `CorextraNetworkException`
- `DioErrorHandler` maps Dio errors to user-friendly, typed exceptions

### Logging
- `debugLog` — simple logger with `LogLevel` (`info` / `warning` / `error`). Prints to the console in debug builds and shows in the DevTools Logs tab
- `AppLogger` — structured logging for app events and Dio requests/responses/errors
- `AppLoggerInterceptor` — pretty, color-coded Dio logs, one block per event (toggle with `enabled: false`)
- `CorextraSocketLogger` — logs socket messages to the console **and** DevTools — see [Socket logging](#socket-logging)

### Animation
- `FadeSlideTransition` — combined fade + slide transition, with `top` / `bottom` / `left` / `right` / `custom` directions

### DevTools Panel
An in-app inspector styled after Flutter DevTools. No separate DevTools connection needed, and it's automatically disabled outside debug builds.

```dart
MaterialApp(
  builder: (context, child) =>
      CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
  home: const HomeScreen(),
)

dio.interceptors.add(const CorextraDevToolsInterceptor());
```

A draggable bubble opens the panel:

- **Network** — every request/response, searchable and filterable by method or status. Headers, query params, and body each get their own tab. Sensitive headers (`Authorization`, `Cookie`, etc.) get a **TOKEN** badge — mask the value with `hiddenHeaders` while keeping copy/share working. JSON renders as a collapsible, syntax-highlighted tree. Socket messages show here too (filter by **Socket**).
- **Logs** — every `debugLog`/`AppLogger` call, searchable and filterable by level.
- **Info** — app and device details via `package_info_plus`/`device_info_plus`.
- **Performance** (under **More**) — a live FPS/frame-time chart with jank highlighting.

Tap **Minimize** to shrink the panel into a small floating window. Android's back button closes whatever's open in the panel one step at a time, instead of affecting the host app underneath it. Toggle everything at runtime with `CorextraDevTools.instance.enabled`.

Planned: a widget/layout inspector, memory heap snapshots, a storage viewer, and a route/navigation inspector.

### Socket logging
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

In DevTools, each row shows the event name, `EMIT` (sent) or `ON` (received), and its status: `OK`, `ERR`, or pending while waiting for an ack.

| Option | Default | What it does |
|---|---|---|
| `consoleEnabled` | `true` | Turn console logs on or off |
| `devToolsEnabled` | follows `CorextraDevTools.instance.enabled` | Turn DevTools capture on or off |
| `captureBody` | `true` | Save message data in DevTools |
| `maxBodyLength` | `100000` | Trims text messages longer than this |

---

## Getting Started

Add the dependency:

```yaml
dependencies:
  corextra: ^1.2.9
```

Import it:

```dart
import 'package:corextra/corextra.dart';
```

## Example

A runnable demo app lives in [`example/`](example/), including the DevTools panel:

```sh
cd example
flutter pub get
flutter run
```
