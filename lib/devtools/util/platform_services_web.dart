// Plugin-free on web: share_plus, package_info_plus and device_info_plus import `dart:io` internally, which breaks WASM.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

Future<void> shareText(String text, {Rect? origin}) async {
  final navigator = web.window.navigator;
  // No Web Share API (desktop Firefox, non-HTTPS pages): fall back to the clipboard.
  if (!navigator.has('share')) {
    await Clipboard.setData(ClipboardData(text: text));
    return;
  }
  await navigator.share(web.ShareData(text: text)).toDart;
}

/// Reads the `version.json` Flutter emits on web builds, the same source `package_info_plus` uses.
Future<Map<String, String>> loadAppInfo() async {
  final json = await _versionJson();
  String field(String key) => json[key]?.toString() ?? '';
  return {
    'App name': field('app_name'),
    'Package': field('package_name'),
    'Version': '${field('version')} (${field('build_number')})',
    'Device': web.window.navigator.userAgent,
  };
}

Future<Map<String, dynamic>> _versionJson() async {
  try {
    final uri = Uri.parse(web.document.baseURI).resolve('version.json');
    final response =
        await web.window
            .fetch(uri.toString().toJS, web.RequestInit(cache: 'no-store'))
            .toDart;
    if (!response.ok) return const {};
    final body = (await response.text().toDart).toDart;
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }
}
