
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
- String utilities like `.capitalize()`  
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
- debugLog:
  - Lightweight, debug-only logger for development builds
  - Supports multiple log levels (info, warning, error)
- AppLogger:
  - Structured logging for app events, Dio requests, responses, and errors
  - Easy integration with existing network layers
  - Optional support for global tokens or custom metadata

---

## Getting Started

Add this package to your Dart or Flutter project by adding this line to your `pubspec.yaml`:

```yaml
dependencies:
  corextra: ^1.0.5
```

Then import it in your Dart code:

```dart
import 'package:corextra/corextra.dart';
```
