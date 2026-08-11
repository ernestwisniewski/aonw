bool jsonDeepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
    if (left.length != right.length || !left.keys.every(right.containsKey)) {
      return false;
    }
    return left.entries.every(
      (entry) => jsonDeepEquals(entry.value, right[entry.key]),
    );
  }
  if (left is List<Object?> && right is List<Object?>) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!jsonDeepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}
