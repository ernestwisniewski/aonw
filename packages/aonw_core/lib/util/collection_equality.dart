/// Structural equality helpers for value objects that compare collection
/// fields by content rather than identity.
///
/// These mirror the semantics of the hand-written comparisons that were
/// previously duplicated across domain and AI value objects: order-sensitive
/// for lists, key/value for maps, and membership for sets.
library;

/// Returns `true` when [a] and [b] hold equal elements in the same order.
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns `true` when [a] and [b] hold the same keys mapped to equal values.
bool mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Returns `true` when [a] and [b] contain the same elements.
bool setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}

/// Order-independent hash code for a map, suitable as the `hashCode` companion
/// of an equality that compares maps by their key/value pairs ([mapEquals]).
///
/// Equal maps hash equally regardless of insertion order, and any key or value
/// type is supported.
int mapHash<K, V>(Map<K, V> map) {
  return Object.hashAllUnordered([
    for (final entry in map.entries) Object.hash(entry.key, entry.value),
  ]);
}
