/// Logging Color
enum LogColor { red, blue, reset, green, yellow }

extension LogColorData on LogColor {
  String get getValue {
    switch (this) {
      case LogColor.red:
        return '\x1B[31m';
      case LogColor.blue:
        return '\x1B[34m';
      case LogColor.reset:
        return '\x1B[0m';
      case LogColor.green:
        return '\x1B[32m';
      case LogColor.yellow:
        return '\x1B[33m';
    }
  }
}
