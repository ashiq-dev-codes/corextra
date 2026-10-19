import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

enum Level { low, high }

class Player with CorextraSortable {
  Player(this.name, this.rank, {this.level, this.active});

  final String name;
  final int? rank;
  final Level? level;
  final bool? active;

  @override
  List<Object?> get sortBy => [rank, name];
}

class Mixed with CorextraSortable {
  Mixed(this.value);

  final Object? value;

  @override
  List<Object?> get sortBy => [value];
}

void main() {
  test('list.sort() sorts by sortBy, using later values to break ties', () {
    final players = [Player('Zed', 1), Player('Ali', 2), Player('Amy', 1)]
      ..sort();
    expect(players.map((p) => p.name), ['Amy', 'Zed', 'Ali']);
  });

  test('nulls sort last', () {
    final players = [Player('A', null), Player('B', 3), Player('C', 1)]..sort();
    expect(players.map((p) => p.name), ['C', 'B', 'A']);
  });

  test('comparison operators follow compareTo', () {
    final first = Player('A', 1);
    final second = Player('B', 2);
    expect(first < second, isTrue);
    expect(second > first, isTrue);
    expect(first <= Player('A', 1), isTrue);
    expect(first >= Player('A', 1), isTrue);
  });

  test('sorts enums by declaration order and false before true', () {
    final enums = [Mixed(Level.high), Mixed(Level.low)]..sort();
    expect(enums.map((m) => m.value), [Level.low, Level.high]);
    final flags = [Mixed(true), Mixed(false)]..sort();
    expect(flags.map((m) => m.value), [false, true]);
  });

  test('never throws on values of different types', () {
    final mixed = [Mixed('b'), Mixed(DateTime(2026)), Mixed(1), Mixed('a')];
    expect(() => mixed.sort(), returnsNormally);
  });
}
