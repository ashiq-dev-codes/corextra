import 'dart:ui' show Rect;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

/// [origin] anchors the sheet so iPad's popover-based presentation doesn't crash.
Future<void> shareText(String text, {Rect? origin}) async {
  await SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
}

Future<Map<String, String>> loadAppInfo() async {
  final info = await PackageInfo.fromPlatform();
  return {
    'App name': info.appName,
    'Package': info.packageName,
    'Version': '${info.version} (${info.buildNumber})',
    'Device': await _deviceLabel(),
  };
}

Future<String> _deviceLabel() async {
  final plugin = DeviceInfoPlugin();
  try {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model} '
            '(Android ${info.version.release})';
      case TargetPlatform.iOS:
        final info = await plugin.iosInfo;
        return '${info.name} (${info.systemName} ${info.systemVersion})';
      case TargetPlatform.macOS:
        final info = await plugin.macOsInfo;
        return '${info.model} (macOS ${info.osRelease})';
      case TargetPlatform.windows:
        final info = await plugin.windowsInfo;
        return info.productName;
      case TargetPlatform.linux:
        final info = await plugin.linuxInfo;
        return info.prettyName;
      case TargetPlatform.fuchsia:
        return 'Fuchsia device';
    }
  } catch (_) {
    return 'Unavailable';
  }
}
