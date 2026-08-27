/// One node in a Flutter `--analyze-size` JSON tree; `n`/`value`/`children` match `flutter_tools`' own output verbatim, so no remapping is needed.
class SizeAnalysisNode {
  const SizeAnalysisNode({
    required this.name,
    required this.sizeBytes,
    this.children = const [],
  });

  factory SizeAnalysisNode.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>?;
    return SizeAnalysisNode(
      name: (json['n'] as String?) ?? '(unnamed)',
      sizeBytes: (json['value'] as num?)?.toInt() ?? 0,
      children: [
        for (final child in childrenJson ?? const <dynamic>[])
          SizeAnalysisNode.fromJson(child as Map<String, dynamic>),
      ],
    );
  }

  final String name;
  final int sizeBytes;
  final List<SizeAnalysisNode> children;

  /// Falls back to summing children when a node's own `value` is missing/zero.
  int get totalBytes {
    if (sizeBytes > 0) return sizeBytes;
    if (children.isEmpty) return 0;
    return children.fold(0, (sum, child) => sum + child.totalBytes);
  }

  /// [children] sorted largest [totalBytes] first.
  List<SizeAnalysisNode> get sortedChildren =>
      [...children]..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
}
