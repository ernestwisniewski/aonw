import 'dart:convert';

import 'failure.dart';

Map<String, Object?> decodeObject(String contents, String description) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(contents);
  } on FormatException catch (error) {
    throw MutationFailure('$description is not valid JSON: $error');
  }
  if (decoded is! Map<String, Object?>) {
    throw MutationFailure('$description must be a JSON object.');
  }
  return decoded;
}

Map<String, Object?> asObject(Object? value, String description) {
  if (value is! Map<String, Object?>) {
    throw MutationFailure('$description must be an object.');
  }
  return value;
}

Map<String, Object?> readObject(
  Map<String, Object?> object,
  String key,
  String description,
) => asObject(object[key], '$description.$key');

String readString(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! String) {
    throw MutationFailure('$description.$key must be a string.');
  }
  return value;
}

int readInt(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! int) {
    throw MutationFailure('$description.$key must be an integer.');
  }
  return value;
}

List<String> readStringList(
  Map<String, Object?> object,
  String key,
  String description,
) {
  final value = object[key];
  if (value is! List<Object?> || value.any((entry) => entry is! String)) {
    throw MutationFailure('$description.$key must be a string list.');
  }
  final result = value.cast<String>();
  requireSortedUnique(result, '$description.$key');
  final caseFolded = result.map((entry) => entry.toLowerCase()).toSet();
  if (caseFolded.length != result.length) {
    throw MutationFailure(
      '$description.$key must not contain case-colliding values.',
    );
  }
  return List.unmodifiable(result);
}

void expectKeys(
  Map<String, Object?> object,
  Set<String> expected,
  String description,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unknown = actual.difference(expected).toList()..sort();
  if (missing.isEmpty && unknown.isEmpty) return;
  throw MutationFailure(
    '$description has invalid keys; missing=$missing unknown=$unknown.',
  );
}

void requireSortedUnique(List<String> values, String description) {
  final sorted = values.toSet().toList()..sort();
  if (sorted.length != values.length || !_sameList(sorted, values)) {
    throw MutationFailure('$description must be sorted and unique.');
  }
}

void requireCanonicalJson(
  String source,
  Object? canonicalValue,
  String description,
) {
  final normalized = source.replaceAll('\r\n', '\n');
  if (normalized != canonicalJson(canonicalValue)) {
    throw MutationFailure(
      '$description must use the canonical sorted JSON representation.',
    );
  }
}

String canonicalJson(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

Map<String, V> sortedMap<V>(Map<String, V> source) => {
  for (final key in source.keys.toList()..sort()) key: source[key] as V,
};

void validateRepositoryPath(String path, String description) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.endsWith('/') ||
      path.contains('\\') ||
      path.contains('//') ||
      RegExp(r'[:*?"<>|]').hasMatch(path) ||
      path.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw MutationFailure('$description is not a portable relative path.');
  }
  for (final segment in path.split('/')) {
    final basename = segment.split('.').first.toUpperCase();
    if (segment.isEmpty ||
        segment == '.' ||
        segment == '..' ||
        segment.endsWith('.') ||
        segment.endsWith(' ') ||
        RegExp(
          r'^(?:CON|PRN|AUX|NUL|CLOCK\$|COM[1-9]|LPT[1-9])$',
        ).hasMatch(basename)) {
      throw MutationFailure('$description contains an invalid segment.');
    }
  }
}

void validateName(String value, String description) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
    throw MutationFailure('$description is not a canonical name: $value');
  }
}

bool _sameList<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
