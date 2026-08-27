import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show MethodChannel;

import '../models/size_analysis_node.dart';
import 'bundle_scan_result.dart';

/// Folds a directory's smallest entries into one node once it has more than this many — high enough that a real app's asset folder (fonts, per-package assets, manifests) shows in full; this is a last-resort guard against a genuinely pathological folder, not routine display trimming.
const _maxChildrenPerNode = 300;

/// Hard ceiling on total filesystem entries visited across the whole scan, so a pathologically large or deeply nested directory can't stall the UI.
const _maxTotalEntries = 20000;

/// Hard wall-clock ceiling on the whole scan, in case a single slow/blocking entry (a special file, a stalled network mount) evades the entry-count cap.
const _scanTimeout = Duration(seconds: 8);

/// Backs [_scanAndroidApk] — Android has no pure-Dart way to find its own installed APK path(s), so a tiny native plugin (`CorextraPlugin.kt`) exposes them instead.
const _appSizeChannel = MethodChannel('corextra/app_size');

/// Walks the running app's own installed bundle and sums it up into the same tree shape [SizeAnalysisNode.fromJson] produces, so it renders through the exact same treemap/breakdown UI. iOS/macOS/Windows/Linux walk the real `.app`/install directory directly; Android has no such directory to walk, so it parses its own installed APK(s) as zip archives instead. Web has neither, and resolves to `null`.
Future<BundleScanResult?> scanInstalledBundle() async {
  if (Platform.isAndroid) return _scanAndroidApk();
  if (Platform.isFuchsia) return null;

  final bundleDir = _findBundleRoot();
  if (bundleDir == null) return null;

  try {
    final root = await _scan(bundleDir).timeout(_scanTimeout);
    return BundleScanResult(root: root, platformLabel: Platform.operatingSystem);
  } catch (_) {
    return null;
  }
}

Future<SizeAnalysisNode> _scan(Directory bundleDir) {
  final name = bundleDir.path.split(Platform.pathSeparator).last;
  var visited = 0;

  Future<SizeAnalysisNode> scanDirectory(Directory dir, String nodeName) async {
    if (visited >= _maxTotalEntries) {
      return SizeAnalysisNode(name: nodeName, sizeBytes: 0);
    }

    List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } catch (_) {
      return SizeAnalysisNode(name: nodeName, sizeBytes: 0);
    }

    final children = <SizeAnalysisNode>[];
    for (final entry in entries) {
      if (visited >= _maxTotalEntries) break;
      visited++;
      final entryName = entry.path.split(Platform.pathSeparator).last;
      try {
        if (entry is Directory) {
          children.add(await scanDirectory(entry, entryName));
        } else if (entry is File) {
          children.add(SizeAnalysisNode(name: entryName, sizeBytes: await entry.length()));
        }
      } catch (_) {
        // Unreadable entry (permissions, broken symlink target, ...) — skip it.
      }
    }

    return SizeAnalysisNode(name: nodeName, sizeBytes: 0, children: _capChildren(children));
  }

  return scanDirectory(bundleDir, name.isEmpty ? bundleDir.path : name);
}

/// The `.app` bundle on iOS is the executable's own parent directory; on macOS it's a few levels up (`Contents/MacOS/Exe` → `Name.app`), found by walking up for a `.app`-suffixed ancestor. Windows/Linux have no bundle format, so the whole install directory stands in for it.
Directory? _findBundleRoot() {
  final executableDir = File(Platform.resolvedExecutable).parent;
  if (!Platform.isMacOS) return executableDir;

  var candidate = executableDir;
  for (var i = 0; i < 6; i++) {
    if (candidate.path.endsWith('.app')) return candidate;
    final parent = candidate.parent;
    if (parent.path == candidate.path) break;
    candidate = parent;
  }
  return executableDir;
}

/// Asks the native side (see `android/.../CorextraPlugin.kt`) for the base APK's path — plus any split APKs from an Android App Bundle install — then parses each as a zip and rebuilds the same directory-tree shape a filesystem walk would produce, purely in Dart from here on.
Future<BundleScanResult?> _scanAndroidApk() async {
  try {
    final paths = await _appSizeChannel
        .invokeListMethod<String>('getApkPaths')
        .timeout(_scanTimeout);
    if (paths == null || paths.isEmpty) return null;

    final apkNodes = <SizeAnalysisNode>[];
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final apkName = path.split('/').last;
      apkNodes.add(_buildApkTree(apkName, archive));
    }

    final root = SizeAnalysisNode(
      name: apkNodes.length == 1 ? apkNodes.single.name : 'Installed APKs',
      sizeBytes: 0,
      children: apkNodes.length == 1 ? apkNodes.single.children : apkNodes,
    );
    return BundleScanResult(root: root, platformLabel: 'apk');
  } catch (_) {
    return null;
  }
}

/// Rebuilds a zip's flat `path/to/file` entry list into the same nested folder shape a real directory walk would produce.
SizeAnalysisNode _buildApkTree(String apkName, Archive archive) {
  final root = _MutableTreeNode(apkName);
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final parts = entry.name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) continue;

    var current = root;
    for (var i = 0; i < parts.length - 1; i++) {
      current = current.children.putIfAbsent(
        parts[i],
        () => _MutableTreeNode(parts[i]),
      );
    }
    final leafName = parts.last;
    final leaf = current.children.putIfAbsent(
      leafName,
      () => _MutableTreeNode(leafName),
    );
    leaf.fileBytes += entry.size;
  }
  return root.toNode();
}

class _MutableTreeNode {
  _MutableTreeNode(this.name);

  final String name;
  int fileBytes = 0;
  final Map<String, _MutableTreeNode> children = {};

  SizeAnalysisNode toNode() {
    if (children.isEmpty) {
      return SizeAnalysisNode(name: name, sizeBytes: fileBytes);
    }
    return SizeAnalysisNode(
      name: name,
      sizeBytes: 0,
      children: _capChildren(
        children.values.map((c) => c.toNode()).toList(),
      ),
    );
  }
}

List<SizeAnalysisNode> _capChildren(List<SizeAnalysisNode> children) {
  if (children.length <= _maxChildrenPerNode) return children;
  final sorted = [...children]
    ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
  final kept = sorted.take(_maxChildrenPerNode - 1).toList();
  final foldedCount = sorted.length - kept.length;
  final foldedBytes = sorted
      .skip(kept.length)
      .fold<int>(0, (sum, n) => sum + n.totalBytes);
  kept.add(
    SizeAnalysisNode(name: '$foldedCount more items', sizeBytes: foldedBytes),
  );
  return kept;
}
