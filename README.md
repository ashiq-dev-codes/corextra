
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
- Optional **translation support** via `easy_localization` 

### Responsive Utilities
- ResponsiveBreakpoints: simple and customizable screen size helpers (`xs`, `sm`, `md`, `lg`, `xl`) for responsive layouts in Flutter  

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

A draggable bubble opens the panel, with five tabs:
- **Network** — every request/response, searchable and filterable by method or status. Query parameters, headers, and body each get their own **Headers / Payload / Response** tab in the detail view, so a large body scrolls on its own without pushing anything else out of reach. Wide screens get a two-pane list + detail view; narrow screens drill into a full-screen detail with a Back button. Redact sensitive headers with `hiddenHeaders`
- **Logs** — every `debugLog`/`AppLogger` call, searchable and filterable by level — no extra wiring needed
- **Performance** — a live FPS/frame-time chart with jank highlighting and tap-to-inspect frames
- **App Size** — see what's taking up space as an interactive treemap plus a sorted breakdown list. Opens automatically with a live **quick scan** — no build step, no file — reading the installed bundle directly on iOS/macOS/Windows/Linux/Android (not available on web); for the full class-level Dart breakdown, **import** a `flutter build <target> --analyze-size` JSON file instead
- **Info** — app + device details via `package_info_plus`/`device_info_plus`

Every list in the panel gets a floating "scroll to top" button once you've scrolled down. Tap **Minimize** to shrink the panel into a small floating window you can keep an eye on while testing the rest of the app — press and hold its corner before dragging to resize it. Drag the bubble or the window to a screen edge to tuck it out of the way. Toggle everything at runtime with `CorextraDevTools.instance.enabled`.

Planned for a future phase: a widget/layout inspector, memory heap snapshots, a storage (shared_preferences) viewer, a route/navigation inspector, and App Size diffing between two builds.

---

## Getting Started

Add this package to your Dart or Flutter project by adding this line to your `pubspec.yaml`:

```yaml
dependencies:
  corextra: ^1.2.2
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
