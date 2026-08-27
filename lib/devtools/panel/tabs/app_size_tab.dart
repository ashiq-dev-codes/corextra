import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../devtools_controller.dart';
import '../../models/size_analysis_node.dart';
import '../../util/app_bundle_scan.dart';
import '../../util/app_size_file_picker.dart';
import '../../util/bundle_scan_result.dart';
import '../../util/byte_format.dart';
import '../../util/treemap_layout.dart';
import '../scroll_to_top_fab.dart';

/// Loads a Flutter `--analyze-size` JSON file, or quick-scans the app's own installed bundle, and shows what's taking up space as a treemap plus a breakdown list, modeled on Flutter DevTools' own App Size tool.
class AppSizeTab extends StatefulWidget {
  const AppSizeTab({
    super.key,
    this.pickFile = openAppSizeAnalysisFile,
    this.scanBundle = scanInstalledBundle,
  });

  /// Overridable so tests can substitute a fake file instead of a real platform picker.
  final Future<XFile?> Function() pickFile;

  /// Overridable so tests can substitute a fake result instead of scanning this test run's own real filesystem.
  final Future<BundleScanResult?> Function() scanBundle;

  @override
  State<AppSizeTab> createState() => _AppSizeTabState();
}

class _AppSizeTabState extends State<AppSizeTab> {
  bool _loading = false;

  /// Drill-down path from the root to the node currently shown; kept locally (not in [AppSizeStore]), the same way `NetworkTab` keeps its selection.
  List<SizeAnalysisNode> _path = [];

  @override
  void initState() {
    super.initState();
    // A quick scan needs no file, so it runs automatically on first open — but only if nothing's loaded yet, so it never clobbers data from an earlier session.
    if (CorextraDevTools.instance.appSize.root == null) {
      _runQuickScan();
    }
  }

  Future<void> _runQuickScan() async {
    setState(() => _loading = true);
    try {
      await CorextraDevTools.instance.appSize.runQuickScan(widget.scanBundle);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFile() async {
    setState(() => _loading = true);
    try {
      final file = await widget.pickFile();
      if (file == null) return;
      final content = await file.readAsString();
      if (!mounted) return;
      CorextraDevTools.instance.appSize.loadFromJson(
        content,
        fileName: file.name,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Drills into any node, leaves included — a leaf still shows something (see [_Treemap]'s explanation of why it can't go deeper), rather than being a dead, unexplained tap target.
  void _drillInto(SizeAnalysisNode node) {
    setState(() => _path = [..._path, node]);
  }

  void _goToBreadcrumb(int index) {
    setState(() => _path = _path.sublist(0, index + 1));
  }

  @override
  Widget build(BuildContext context) {
    final store = CorextraDevTools.instance.appSize;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final root = store.root;
        final errorMessage = store.errorMessage;

        if (root == null) {
          return _EmptyOrError(
            errorMessage: errorMessage,
            loading: _loading,
            onOpenFile: _openFile,
            onRetryQuickScan: _runQuickScan,
          );
        }

        if (_path.isEmpty || !identical(_path.first, root)) {
          _path = [root];
        }
        final path = _path;
        final current = path.last;

        return LayoutBuilder(
          builder: (context, viewport) {
            final treemapHeight = (viewport.maxHeight * 0.4).clamp(
              160.0,
              320.0,
            );
            return DevToolsScrollToTop(
              builder: (context, controller) => SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      _ErrorBanner(message: errorMessage),
                      const SizedBox(height: 12),
                    ],
                    _SummaryHeader(
                      fileName: store.fileName!,
                      loadedAt: store.loadedAt!,
                      platform: store.platform,
                      isLive: store.isLive,
                      totalBytes: root.totalBytes,
                      loading: _loading,
                      onRescan: _runQuickScan,
                      onOpenFile: _openFile,
                      onClear: store.clear,
                    ),
                    const SizedBox(height: 12),
                    _Breadcrumbs(path: path, onTap: _goToBreadcrumb),
                    const SizedBox(height: 6),
                    const _ExploreHint(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: treemapHeight,
                      child: _Treemap(
                        node: current,
                        isLive: store.isLive,
                        onTapNode: _drillInto,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BreakdownList(node: current, onTapNode: _drillInto),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.errorMessage,
    required this.loading,
    required this.onOpenFile,
    required this.onRetryQuickScan,
  });

  final String? errorMessage;
  final bool loading;
  final VoidCallback onOpenFile;
  final VoidCallback onRetryQuickScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    /// Scrollable, not just centered — the hint below can wrap past what a fixed box fits at the PiP window's minimum width.
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewport.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.hardDrive, size: 40, color: mutedColor),
                  const SizedBox(height: 12),
                  Text(
                    'No size data loaded yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For the full class-level breakdown, run `flutter '
                    'build <target> --analyze-size`, transfer the '
                    'resulting *-code-size-analysis_*.json onto this '
                    'device, then import it below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: loading ? null : onRetryQuickScan,
                        icon: loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Retry quick scan'),
                      ),
                      FilledButton.icon(
                        onPressed: loading ? null : onOpenFile,
                        icon: const Icon(LucideIcons.folderOpen, size: 16),
                        label: const Text('Import file'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.fileName,
    required this.loadedAt,
    required this.platform,
    required this.isLive,
    required this.totalBytes,
    required this.loading,
    required this.onRescan,
    required this.onOpenFile,
    required this.onClear,
  });

  final String fileName;
  final DateTime loadedAt;
  final String? platform;
  final bool isLive;
  final int totalBytes;
  final bool loading;
  final VoidCallback onRescan;
  final VoidCallback onOpenFile;
  final VoidCallback onClear;

  static final _timeFormat = DateFormat('M/d/yyyy h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    formatBytes(totalBytes),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (platform != null) _Pill(text: _platformLabel(platform!)),
                  _Pill(
                    text: isLive ? 'Live scan' : 'Imported',
                    color: isLive ? Colors.green : null,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$fileName · ${_timeFormat.format(loadedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Rescan the installed app bundle',
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.refreshCw, size: 18),
          onPressed: loading ? null : onRescan,
        ),
        IconButton(
          tooltip: 'Import file',
          icon: const Icon(LucideIcons.folderOpen, size: 18),
          onPressed: loading ? null : onOpenFile,
        ),
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(LucideIcons.x, size: 18),
          onPressed: onClear,
        ),
      ],
    );
  }
}

String _platformLabel(String type) => switch (type) {
  'apk' => 'Android (APK)',
  'aab' => 'Android (AAB)',
  'ios' => 'iOS',
  'macos' => 'macOS',
  'windows' => 'Windows',
  'linux' => 'Linux',
  _ => type,
};

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.path, required this.onTap});

  final List<SizeAnalysisNode> path;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < path.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: i == path.length - 1 ? null : () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  i == path.length - 1
                      ? '${path[i].name} (${formatBytes(path[i].totalBytes)})'
                      : path[i].name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: i == path.length - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExploreHint extends StatelessWidget {
  const _ExploreHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Tap a box below, or a row further down, to see what\'s inside it.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Treemap extends StatelessWidget {
  const _Treemap({
    required this.node,
    required this.isLive,
    required this.onTapNode,
  });

  final SizeAnalysisNode node;
  final bool isLive;
  final ValueChanged<SizeAnalysisNode> onTapNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (node.children.isEmpty) {
      final mutedColor = theme.colorScheme.onSurfaceVariant;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.fileQuestion, size: 28, color: mutedColor),
              const SizedBox(height: 8),
              Text(
                '"${node.name}" is a single file — nothing more to break down here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
              if (isLive) ...[
                const SizedBox(height: 4),
                Text(
                  'If this is your compiled Dart code, importing a '
                  '--analyze-size file instead shows the package/class '
                  'breakdown inside it.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final tiles = layoutTreemap(
          node.children,
          Rect.fromLTWH(0, 0, size.width, size.height),
        );
        return GestureDetector(
          onTapUp: (details) {
            for (final tile in tiles) {
              if (tile.rect.contains(details.localPosition)) {
                onTapNode(tile.node);
                return;
              }
            }
          },
          child: CustomPaint(
            key: const Key('app-size-treemap'),
            size: size,
            painter: _TreemapPainter(
              tiles: tiles,
              baseColor: theme.colorScheme.primary,
              borderColor: theme.colorScheme.surface,
              textColor: theme.colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}

class _TreemapPainter extends CustomPainter {
  _TreemapPainter({
    required this.tiles,
    required this.baseColor,
    required this.borderColor,
    required this.textColor,
  });

  final List<TreemapTile> tiles;
  final Color baseColor;
  final Color borderColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final rect = tile.rect;
      if (rect.width <= 0 || rect.height <= 0) continue;

      final shade = (i / (tiles.length == 1 ? 1 : tiles.length - 1)) * 0.35;
      final fill = Color.lerp(baseColor, Colors.black, shade)!;

      canvas.drawRect(rect, Paint()..color = fill.withValues(alpha: 0.85));
      canvas.drawRect(
        rect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      _drawLabel(canvas, tile, rect);
    }
  }

  void _drawLabel(Canvas canvas, TreemapTile tile, Rect rect) {
    if (rect.width < 36 || rect.height < 20) return;
    final painter = TextPainter(
      text: TextSpan(
        text: '${tile.node.name}\n${formatBytes(tile.node.totalBytes)}',
        style: TextStyle(color: textColor, fontSize: 11, height: 1.3),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 8);
    if (painter.height > rect.height - 6) return;
    painter.paint(canvas, rect.topLeft + const Offset(5, 4));
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) =>
      !identical(oldDelegate.tiles, tiles);
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({required this.node, required this.onTapNode});

  final SizeAnalysisNode node;
  final ValueChanged<SizeAnalysisNode> onTapNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = node.sortedChildren;
    if (children.isEmpty) {
      return Text(
        'No further breakdown available for this node.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final total = node.totalBytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Breakdown',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '(${children.length}, largest first)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _BreakdownHeaderRow(),
        const Divider(height: 12),
        for (final child in children)
          _BreakdownRow(
            node: child,
            fraction: total <= 0 ? 0 : child.totalBytes / total,
            onTap: () => onTapNode(child),
          ),
      ],
    );
  }
}

/// Muted small-caps column labels above [_BreakdownRow]s, so the row's numbers (a percentage next to a bar next to an absolute size) read as a table instead of an unlabeled wall of digits.
class _BreakdownHeaderRow extends StatelessWidget {
  const _BreakdownHeaderRow();

  static const _labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = _labelStyle.copyWith(color: mutedColor);
    return Row(
      children: [
        const SizedBox(width: 20),
        Expanded(flex: 3, child: Text('NAME', style: style)),
        const SizedBox(width: 8),
        const Expanded(flex: 2, child: SizedBox()),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('%', textAlign: TextAlign.right, style: style),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text('SIZE', textAlign: TextAlign.right, style: style),
        ),
        const SizedBox(width: 18),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.node,
    required this.fraction,
    required this.onTap,
  });

  final SizeAnalysisNode node;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFolder = node.children.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Icon(
                  isFolder ? LucideIcons.folder : LucideIcons.file,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${(fraction * 100).toStringAsFixed(fraction >= 0.1 ? 0 : 1)}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  formatBytes(node.totalBytes),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              SizedBox(
                width: 18,
                child: isFolder
                    ? Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, Color? color}) : _color = color;

  final String text;
  final Color? _color;

  @override
  Widget build(BuildContext context) {
    final color = _color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
