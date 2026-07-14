import 'dart:convert';

/// Encodes JSON with recursively sorted object keys and no insignificant space.
String encodeCanonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList();
    for (final entry in entries) {
      if (entry.key is! String) {
        throw ArgumentError.value(
          entry.key,
          'key',
          'JSON object keys must be strings',
        );
      }
    }
    entries.sort(
      (left, right) => (left.key as String).compareTo(right.key as String),
    );
    return <String, Object?>{
      for (final entry in entries)
        entry.key as String: _canonicalize(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}
