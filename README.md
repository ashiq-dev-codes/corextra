
# corextra

A lightweight Dart package offering handy extensions and utility functions  
for common types like `String`, `int`, `double`, `List`, and more.  
Make your Dart and Flutter code cleaner, safer, and easier to read.

[![pub package](https://img.shields.io/pub/v/corextra.svg)](https://pub.dev/packages/corextra)

---

## Features

- Extensions on core types for safer parsing and formatting  
- Null-safe and concise checks like `.isNullOrEmpty` on `String?` and `List?`  
- Convenient conversion helpers: `.toTryInt()`, `.toTryDouble()`, `.toTryBool()`  
- String utilities like `.capitalize()`  
- Numeric helpers to sanitize negative values  
- Helper functions like `isStringEmpty()` and `isListEmpty()` for legacy or functional use  
- ResponsiveBreakpoints: simple and customizable screen size helpers (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`) for responsive layouts in Flutter  
- DateTime extensions for easy parsing from string to `DateTime` and formatting from `DateTime` to string with customizable formats

---

## Getting Started

Add this package to your Dart or Flutter project by adding this line to your `pubspec.yaml`:

```yaml
dependencies:
  corextra: ^1.0.2
```

Then import it in your Dart code:

```dart
import 'package:corextra/corextra.dart';
```
