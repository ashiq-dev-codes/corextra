/// Whether [a] and [b] are equal, comparing lists, maps and sets by their contents.
bool deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!deepEquals(entry.value, b[entry.key])) return false;
    }
    return true;
  }
  if (a is Set && b is Set) {
    if (a.length != b.length) return false;
    return a.every((x) => b.contains(x) || b.any((y) => deepEquals(x, y)));
  }
  return a == b;
}

/// A hash code that matches [deepEquals]: equal contents give equal hashes.
int deepHash(Object? value) {
  return switch (value) {
    List() => Object.hashAll(value.map(deepHash)),
    Map() => Object.hashAllUnordered(
      value.entries.map((e) => Object.hash(deepHash(e.key), deepHash(e.value))),
    ),
    Set() => Object.hashAllUnordered(value.map(deepHash)),
    _ => value.hashCode,
  };
}
