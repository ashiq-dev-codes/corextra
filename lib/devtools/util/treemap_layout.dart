import 'dart:ui' show Rect;

import '../models/size_analysis_node.dart';

/// A [SizeAnalysisNode] laid out into a screen-space rectangle by [layoutTreemap].
class TreemapTile {
  const TreemapTile({required this.node, required this.rect});

  final SizeAnalysisNode node;
  final Rect rect;
}

/// Lays out [nodes] into [bounds] via the squarified treemap algorithm (Bruls/Huizing/van Wijk), the same one Flutter DevTools' App Size tool uses.
List<TreemapTile> layoutTreemap(List<SizeAnalysisNode> nodes, Rect bounds) {
  final sized = nodes.where((n) => n.totalBytes > 0).toList()
    ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
  if (sized.isEmpty || bounds.width <= 0 || bounds.height <= 0) {
    return const [];
  }

  final total = sized.fold<int>(0, (sum, n) => sum + n.totalBytes);
  final scale = (bounds.width * bounds.height) / total;
  double areaOf(SizeAnalysisNode n) => n.totalBytes * scale;

  double worstRatio(List<SizeAnalysisNode> row, double side) {
    final areas = row.map(areaOf).toList();
    final sum = areas.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return double.infinity;
    final maxArea = areas.reduce((a, b) => a > b ? a : b);
    final minArea = areas.reduce((a, b) => a < b ? a : b);
    final side2 = side * side;
    final ratio1 = (side2 * maxArea) / (sum * sum);
    final ratio2 = (sum * sum) / (side2 * minArea);
    return ratio1 > ratio2 ? ratio1 : ratio2;
  }

  final tiles = <TreemapTile>[];

  /// Places `row` as a band along the shorter side of `target`; returns the leftover rect for the next row.
  Rect placeRow(List<SizeAnalysisNode> row, Rect target) {
    final rowArea = row.fold<double>(0, (a, n) => a + areaOf(n));
    if (target.width < target.height) {
      final bandHeight = rowArea / target.width;
      var x = target.left;
      for (final n in row) {
        final w = areaOf(n) / bandHeight;
        tiles.add(TreemapTile(node: n, rect: Rect.fromLTWH(x, target.top, w, bandHeight)));
        x += w;
      }
      return Rect.fromLTWH(
        target.left,
        target.top + bandHeight,
        target.width,
        (target.height - bandHeight).clamp(0.0, double.infinity),
      );
    } else {
      final bandWidth = rowArea / target.height;
      var y = target.top;
      for (final n in row) {
        final h = areaOf(n) / bandWidth;
        tiles.add(TreemapTile(node: n, rect: Rect.fromLTWH(target.left, y, bandWidth, h)));
        y += h;
      }
      return Rect.fromLTWH(
        target.left + bandWidth,
        target.top,
        (target.width - bandWidth).clamp(0.0, double.infinity),
        target.height,
      );
    }
  }

  var remaining = sized;
  var rect = bounds;
  var row = <SizeAnalysisNode>[];
  while (remaining.isNotEmpty) {
    final next = remaining.first;
    final side = rect.width < rect.height ? rect.width : rect.height;
    final candidateRow = [...row, next];
    if (row.isEmpty || worstRatio(row, side) >= worstRatio(candidateRow, side)) {
      row = candidateRow;
      remaining = remaining.skip(1).toList();
    } else {
      rect = placeRow(row, rect);
      row = [];
    }
  }
  if (row.isNotEmpty) placeRow(row, rect);

  return tiles;
}
