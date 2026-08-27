import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SizeAnalysisNode.fromJson', () {
    test('parses n/value/children from flutter_tools output verbatim', () {
      final node = SizeAnalysisNode.fromJson({
        'n': 'Root',
        'value': 1000,
        'children': [
          {'n': 'Frameworks', 'value': 700},
          {'n': 'Runner', 'value': 300},
        ],
      });

      expect(node.name, 'Root');
      expect(node.sizeBytes, 1000);
      expect(node.children, hasLength(2));
      expect(node.children.first.name, 'Frameworks');
      expect(node.children.first.sizeBytes, 700);
    });

    test('parses nested children recursively', () {
      final node = SizeAnalysisNode.fromJson({
        'n': 'Root',
        'value': 100,
        'children': [
          {
            'n': 'A',
            'value': 100,
            'children': [
              {'n': 'A1', 'value': 60},
              {'n': 'A2', 'value': 40},
            ],
          },
        ],
      });

      final a = node.children.single;
      expect(a.children, hasLength(2));
      expect(a.children.map((c) => c.name), ['A1', 'A2']);
    });

    test('defaults a missing name/value rather than throwing', () {
      final node = SizeAnalysisNode.fromJson({});
      expect(node.name, '(unnamed)');
      expect(node.sizeBytes, 0);
      expect(node.children, isEmpty);
    });
  });

  group('SizeAnalysisNode.totalBytes', () {
    test('uses its own value when set', () {
      const node = SizeAnalysisNode(name: 'A', sizeBytes: 42);
      expect(node.totalBytes, 42);
    });

    test('falls back to summing children when its own value is zero', () {
      const node = SizeAnalysisNode(
        name: 'A',
        sizeBytes: 0,
        children: [
          SizeAnalysisNode(name: 'A1', sizeBytes: 10),
          SizeAnalysisNode(name: 'A2', sizeBytes: 20),
        ],
      );
      expect(node.totalBytes, 30);
    });
  });

  test('sortedChildren orders largest totalBytes first', () {
    const node = SizeAnalysisNode(
      name: 'Root',
      sizeBytes: 0,
      children: [
        SizeAnalysisNode(name: 'Small', sizeBytes: 10),
        SizeAnalysisNode(name: 'Big', sizeBytes: 100),
        SizeAnalysisNode(name: 'Medium', sizeBytes: 50),
      ],
    );
    expect(
      node.sortedChildren.map((c) => c.name),
      ['Big', 'Medium', 'Small'],
    );
  });
}
