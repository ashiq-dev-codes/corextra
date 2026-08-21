
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
An in-app inspector panel — no separate DevTools connection required, works in a running debug build.
- **CorextraDevToolsOverlay**:
  - Wraps your app (e.g. via `MaterialApp.builder`) with a floating, draggable bubble
  - Tap it to open a panel with **Network**, **Logs**, **Performance**, and **Info** tabs
  - Defaults to visible only in `kDebugMode`; toggle at runtime via `CorextraDevTools.instance.enabled`
- **CorextraDevToolsInterceptor**:
  - Dio interceptor that feeds the Network tab (method, URL, headers, body, status, duration)
  - Purely observational — additive to `AppLoggerInterceptor`, safe to use both together
- **Logs tab**: automatically populated by `debugLog`/`AppLogger` — no extra wiring needed
- **Performance tab**: live FPS and jank monitoring via Flutter's own frame timings, plus an approximate memory (RSS) reading
- **Info tab**: app + device details via `package_info_plus`/`device_info_plus`, and current capture-buffer counts
- Planned for a future phase: widget/layout inspector, memory heap snapshots, a storage (shared_preferences) viewer, and a route/navigation inspector

---

## Getting Started

Add this package to your Dart or Flutter project by adding this line to your `pubspec.yaml`:

```yaml
dependencies:
  corextra: ^1.2.0
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
