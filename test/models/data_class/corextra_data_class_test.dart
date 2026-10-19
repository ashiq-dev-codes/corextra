import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

class Point with CorextraDataClass {
  const Point(this.x, this.y, {this.tags = const []});

  final int x;
  final int y;
  final List<String> tags;

  @override
  Map<String, Object?> get fields => {'x': x, 'y': y, 'tags': tags};
}

class Size with CorextraDataClass {
  const Size(this.x, this.y);

  final int x;
  final int y;

  @override
  Map<String, Object?> get fields => {'x': x, 'y': y};
}

void main() {
  test('equal when the fields match, comparing lists by contents', () {
    final a = Point(1, 2, tags: ['a']);
    final b = Point(1, 2, tags: ['a']);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect({a, b}, hasLength(1));
    expect(a == Point(1, 2, tags: ['b']), isFalse);
    expect(a == const Point(1, 3), isFalse);
  });

  test('different types with the same fields are not equal', () {
    expect(const Size(1, 2), isNot(const Point(1, 2)));
  });

  test('works with const constructors', () {
    expect(identical(const Point(1, 2), const Point(1, 2)), isTrue);
  });

  test('toString lists each field by name', () {
    expect(const Size(1, 2).toString(), 'Size(x: 1, y: 2)');
  });
}
