import 'bundle_scan_result.dart';

/// Always `null` on platforms without `dart:io` (e.g. web).
Future<BundleScanResult?> scanInstalledBundle() async => null;
