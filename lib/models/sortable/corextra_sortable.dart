/// Makes a class sortable by the values you pick, so `list.sort()`, `<` and `>` just work.
mixin CorextraSortable implements Comparable<CorextraSortable> {
  // ---------------- Sort order ----------------

  /// Values to sort by, most important first; later values break ties and nulls sort last, e.g. `List<Object?> get sortBy => [rank, name];`.
  List<Object?> get sortBy;

  // ---------------- Comparing ----------------

  /// Compares [sortBy] value by value, so `players.sort()` orders by rank, then name.
  @override
  int compareTo(CorextraSortable other) {
    final mine = sortBy;
    final theirs = other.sortBy;
    final length = mine.length < theirs.length ? mine.length : theirs.length;
    for (var i = 0; i < length; i++) {
      final result = _compareValues(mine[i], theirs[i]);
      if (result != 0) return result;
    }
    return mine.length.compareTo(theirs.length);
  }

  /// Whether this sorts before [other], e.g. `if (first < second) ...`.
  bool operator <(CorextraSortable other) => compareTo(other) < 0;

  /// Whether this sorts before [other] or ties with it.
  bool operator <=(CorextraSortable other) => compareTo(other) <= 0;

  /// Whether this sorts after [other].
  bool operator >(CorextraSortable other) => compareTo(other) > 0;

  /// Whether this sorts after [other] or ties with it.
  bool operator >=(CorextraSortable other) => compareTo(other) >= 0;
}

// ---------------- Private helpers ----------------

int _compareValues(Object? a, Object? b) {
  if (a == null || b == null) {
    if (a == null && b == null) return 0;
    return a == null ? 1 : -1;
  }
  if (a is num && b is num) return a.compareTo(b);
  if (a is bool && b is bool) return a == b ? 0 : (a ? 1 : -1);
  if (a is Enum && b is Enum) return a.index.compareTo(b.index);
  if (a is Comparable && b is Comparable) {
    try {
      return a.compareTo(b);
    } catch (_) {
      // Different types, like a String and a DateTime: fall back to their text.
    }
  }
  return '$a'.compareTo('$b');
}
