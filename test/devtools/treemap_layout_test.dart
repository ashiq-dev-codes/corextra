import 'dart:ui';

import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lays out one tile per node, covering the full bounds area', () {
    const nodes = [
      SizeAnalysisNode(name: 'A', sizeBytes: 600),
      SizeAnalysisNode(name: 'B', sizeBytes: 300),
      SizeAnalysisNode(name: 'C', sizeBytes: 100),
    ];
    final bounds = Rect.fromLTWH(0, 0, 200, 100);

    final tiles = layoutTreemap(nodes, bounds);

    expect(tiles, hasLength(3));
    final totalArea = tiles.fold<double>(
      0,
      (sum, t) => sum + t.rect.width * t.rect.height,
    );
    expect(totalArea, closeTo(bounds.width * bounds.height, 0.5));
    for (final tile in tiles) {
      expect(tile.rect.width, greaterThan(0));
      expect(tile.rect.height, greaterThan(0));
    }
  });

  test('skips zero-size nodes', () {
    const nodes = [
      SizeAnalysisNode(name: 'A', sizeBytes: 100),
      SizeAnalysisNode(name: 'Empty', sizeBytes: 0),
    ];
    final tiles = layoutTreemap(nodes, Rect.fromLTWH(0, 0, 100, 100));
    expect(tiles, hasLength(1));
    expect(tiles.single.node.name, 'A');
  });

  test('returns no tiles for empty input or degenerate bounds', () {
    expect(layoutTreemap(const [], Rect.fromLTWH(0, 0, 100, 100)), isEmpty);
    expect(
      layoutTreemap(
        const [SizeAnalysisNode(name: 'A', sizeBytes: 100)],
        Rect.zero,
      ),
      isEmpty,
    );
  });
}
