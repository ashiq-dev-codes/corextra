import 'package:corextra/logs/enum/log_color.dart';

/// Logging levels
enum LogLevel { info, warning, error }

extension LogLevelData on LogLevel {
  String get getColor {
    switch (this) {
      case LogLevel.info:
        return LogColor.blue.getValue;
      case LogLevel.warning:
        return LogColor.yellow.getValue;
      case LogLevel.error:
        return LogColor.red.getValue;
    }
  }
}
