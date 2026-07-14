import 'dart:convert';

/// Encodes JSON with recursively sorted object keys and no insignificant space.
String encodeCanonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is Iterable<Object?>) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}
