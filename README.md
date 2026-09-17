
# corextra

A lightweight Dart package offering handy extensions and utility functions  
for common types like `String`, `int`, `double`, `List`, and more.  
Make your Dart and Flutter code cleaner, safer, and easier to read.

[![pub package](https://img.shields.io/pub/v/corextra.svg)](https://pub.dev/packages/corextra)

---

## Features

### Core Extensions
- Extensions on core types for safer parsing and formatting  
- Null-safe and concise checks like `.isNullOrEmpty` on `String?` and `List?`  
- Convenient conversion helpers: `.toTryInt()`, `.toTryDouble()`, `.toTryBool()`  
- String utilities like `.capitalize()`, `.toPascalCase()`, `.toCamelCase()`    
- Numeric helpers to sanitize negative values  
- Helper functions like `isStringEmpty()` and `isListEmpty()` for legacy or functional use  
- DateTime extensions for:
  - Parsing from string to `DateTime`
  - Formatting `DateTime` to string with customizable formats  
- `safeSetState`:
  - Safely updates widget state only if the widget is still mounted
  - Prevents `setState()` calls on disposed widgets, reducing runtime errors  

### Form Validators
- General-purpose form field validators for Flutter `TextFormField`  
- Validators included:
  - `required` — ensures a field is not empty  
  - `email` — validates email format  
  - `phone` — validates phone numbers with optional mask length  
  - `otp` — validates OTP with customizable length  
  - `password` — validates password with customizable minimum length  
  - `confirmPassword` — ensures password confirmation matches original password  
  - `minLength` / `maxLength` — string length checks  
  - `numeric` — digits-only check  
  - `url` — validates http/https URLs  
  - `pattern` — validates against a custom `RegExp`  
- `FormValidators.compose([...])` chains multiple validators on one field, returning the first error  
- `FormValidators.optional(validator)` skips validation on empty, non-required fields  
- Every validator takes an optional `message:` override, no translator setup required for one-off custom text  
- Optional **translation support** via `easy_localization` 

### Responsive Utilities
- `ResponsiveBreakpoints`: simple and customizable screen size helpers (`sm`, `md`, `lg`, `xl`, `xxl`) for responsive layouts in Flutter, usable from `BuildContext` or `BoxConstraints`  
- `deviceType` / `isMobile` / `isTablet` / `isDesktop` — coarse device classification, no breakpoint chaining needed  
- `responsive<T>(base: ..., md: ..., lg: ...)` — pick a value per breakpoint directly, without a `LayoutBuilder`  
- `screenWidth`, `screenHeight`, `isPortrait`, `isLandscape` — on `BuildContext`  

### Error Handling
- Custom Exception System for structured error handling:
  - `CorextraException` (base class)
  - `CorextraCustomException` for generic app-level errors
  - `CorextraNetworkException` for network-related errors (e.g., Dio, HTTP requests)
- DioErrorHandler:
  - Maps Dio errors to user-friendly messages
  - Throws typed exceptions (`CorextraNetworkException`)

### Logging Utilities
- `debugLog`:
  - Lightweight, debug-only logger for development builds
  - Supports multiple log levels via `LogLevel` (`info`, `warning`, `error`)
  - Each level maps to a distinct ANSI color via `LogColor`
- `AppLogger`:
  - Structured logging for app events, Dio requests, responses, and errors
  - Easy integration with existing network layers
- `AppLoggerInterceptor`:
  - Dio interceptor for pretty-printed, bordered, color-coded HTTP logs
  - One consolidated block per request, response, or error
  - Toggle with `enabled: false` to silence all logs

### Animation Utilities
- **FadeSlideTransition**:
  - A combined **fade + slide** transition widget
  - Supports directions: `top`, `bottom`, `left`, `right`, and `custom`
  - Built with `AnimatedSwitcher` for smooth transitions

### DevTools Utilities
An in-app inspector, styled after Flutter DevTools — no separate DevTools connection needed, and it's automatically disabled outside debug builds.

```dart
MaterialApp(
  builder: (context, child) =>
      CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
  home: const HomeScreen(),
)

dio.interceptors.add(const CorextraDevToolsInterceptor());
```

A draggable bubble opens the panel. Network, Logs, and Info sit directly on the tab bar; Performance — used less often — lives behind a **More** button:
- **Network** — every request/response, searchable and filterable by method or status
  - Wide screens get a two-pane list + detail view; narrow screens drill into a full-screen detail with a Back button
  - Query parameters, headers, and body each get their own **Headers / Payload / Response** tab, so a large body scrolls on its own
  - The summary above the tabs shrinks to one line while you scroll, then expands again once you scroll back up — so small screens still have room to read
  - Auth headers (`Authorization`, `Cookie`, `X-Api-Key`, etc.) get a **TOKEN** badge with copy and share buttons. Mask one with `hiddenHeaders` and it still shows a short preview (`***ab12`) — Copy and Share keep using the full real value
  - JSON bodies render as a collapsible, syntax-highlighted tree — tap any `{`/`[` to fold it, long-press any line to copy it, or use **Expand all** / **Collapse all**
  - Anything else falls back to a plain, horizontally-scrollable code block with its own scrollbar
  - Payload and Response blocks also get a **fullscreen** button, for reviewing large data on its own
- **Logs** — every `debugLog`/`AppLogger` call, searchable and filterable by level — no extra wiring needed
- **Info** — app + device details via `package_info_plus`/`device_info_plus`
- **Performance** (in More) — a live FPS/frame-time chart with jank highlighting and tap-to-inspect frames

Every list in the panel gets a floating "scroll to top" button once you've scrolled down. Tap **Minimize** to shrink the panel into a small floating window you can keep an eye on while testing the rest of the app — press and hold its corner before dragging to resize it. Drag the bubble or the window to a screen edge to tuck it out of the way. Android's hardware back button closes whatever's open in the panel (a fullscreen viewer, a drilled-in request, then the panel itself) one step at a time, instead of popping the host app's own screen underneath it. Toggle everything at runtime with `CorextraDevTools.instance.enabled`.

Planned for a future phase: a widget/layout inspector, memory heap snapshots, a storage (shared_preferences) viewer, and a route/navigation inspector.

---

## Getting Started

Add this package to your Dart or Flutter project by adding this line to your `pubspec.yaml`:

```yaml
dependencies:
  corextra: ^1.2.7
```

Then import it in your Dart code:

```dart
import 'package:corextra/corextra.dart';
```

## Example

A runnable demo app lives in [`example/`](example/), including the
DevTools panel. Run it with:

```sh
cd example
flutter pub get
flutter run
```
