import '../models/size_analysis_node.dart';

/// The result of scanning the running app's own installed bundle on disk, from [app_bundle_scan.dart].
class BundleScanResult {
  const BundleScanResult({required this.root, required this.platformLabel});

  final SizeAnalysisNode root;

  /// `Platform.operatingSystem` at scan time — `ios`, `macos`, `windows`, or `linux`.
  final String platformLabel;
}
