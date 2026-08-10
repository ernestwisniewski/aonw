part of 'check_coverage.dart';

final class _GitOutput {
  const _GitOutput({required this.stdout, required this.stderr});

  final String stdout;
  final String stderr;
}

String _formatSummary(
  String scopeName,
  _ScopeSnapshot snapshot,
  Map<String, ({String base, _DiffSnapshot snapshot})> diffs,
) {
  final buffer = StringBuffer('Coverage $scopeName:');
  for (final layerName in snapshot.layers.keys.toList()..sort()) {
    final layer = snapshot.layers[layerName]!;
    buffer.write('\n  $layerName: lines ${layer.lines}, files ${layer.files}');
  }
  buffer.write('\n  missing LCOV records: ${snapshot.missingFiles.length}');
  for (final entry in diffs.entries) {
    buffer.write(
      '\n  ${entry.key} (${entry.value.base}) changed coverable lines: '
      '${entry.value.snapshot.total}',
    );
  }
  return buffer.toString();
}

String _formatPercent(_Counts counts) => counts.found == 0
    ? 'n/a'
    : '${(counts.hit * 100 / counts.found).toStringAsFixed(2)}%';

String _formatBasisPoints(int basisPoints) =>
    '${(basisPoints / 100).toStringAsFixed(2)}%';

String _formatLocations(List<String> locations) {
  const limit = 50;
  if (locations.length <= limit) return locations.join(', ');
  return '${locations.take(limit).join(', ')} '
      '(and ${locations.length - limit} more)';
}

String _requiredRef(String? raw, String option) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || RegExp(r'^0+$').hasMatch(value)) {
    throw CoverageFailure(
      'Coverage checks require $option. Use the Make targets, which choose '
      'local and CI refs explicitly.',
    );
  }
  return value;
}

int _parseLcovCount(
  String raw,
  String path,
  int lineNumber,
  String directive,
  int? previous,
) {
  final value = int.tryParse(raw);
  if (previous != null || value == null || value < 0) {
    throw CoverageFailure(
      '$path:$lineNumber: invalid or duplicate $directive record.',
    );
  }
  return value;
}

Map<String, Object?> _decodeObject(String contents, String description) {
  try {
    return _asObject(jsonDecode(contents), description);
  } on FormatException catch (error) {
    throw CoverageFailure('$description: invalid JSON: ${error.message}');
  }
}

Map<String, Object?> _asObject(Object? value, String description) {
  if (value is! Map<Object?, Object?>) {
    throw CoverageFailure('$description must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw CoverageFailure('$description contains a non-string key.');
    }
    result[key] = entry.value;
  }
  return result;
}

Map<String, Object?> _readObject(
  Map<String, Object?> object,
  String key,
  String description,
) => _asObject(object[key], '$description.$key');

String _readString(
  Map<String, Object?> object,
  String key,
  String description,
) {
  final value = object[key];
  if (value is! String || value.isEmpty) {
    throw CoverageFailure('$description.$key must be a non-empty string.');
  }
  return value;
}

int _readInt(Map<String, Object?> object, String key, String description) {
  final value = object[key];
  if (value is! int) {
    throw CoverageFailure('$description.$key must be an integer.');
  }
  return value;
}

List<String> _readStringList(
  Map<String, Object?> object,
  String key,
  String description,
) => _asStringList(object[key], '$description.$key');

List<String> _asStringList(Object? value, String description) {
  if (value is! List<Object?>) {
    throw CoverageFailure('$description must be a JSON array.');
  }
  final result = <String>[];
  for (final entry in value) {
    if (entry is! String || entry.isEmpty) {
      throw CoverageFailure('$description entries must be non-empty strings.');
    }
    result.add(entry);
  }
  return result;
}

void _expectKeys(
  Map<String, Object?> object,
  Set<String> expected,
  String description,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual);
  final extra = actual.difference(expected);
  if (missing.isNotEmpty || extra.isNotEmpty) {
    throw CoverageFailure(
      '$description has invalid keys; missing [${_sorted(missing)}], extra '
      '[${_sorted(extra)}].',
    );
  }
}

void _requireUnique(Iterable<String> values, String description) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    if (!seen.add(value)) duplicates.add(value);
  }
  if (duplicates.isNotEmpty) {
    throw CoverageFailure(
      '$description contains duplicates: ${_sorted(duplicates)}',
    );
  }
}

void _validatePolicyPath(
  String path,
  String description, {
  bool allowDot = false,
}) {
  if (allowDot && path == '.') return;
  if (_isAbsolutePath(path) ||
      path.contains('\\') ||
      path.startsWith('./') ||
      path.contains('//')) {
    throw CoverageFailure('$description is not a canonical relative path.');
  }
  final withoutTrailingSlash = path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  _normalizeRelativePath(withoutTrailingSlash);
}

String _resolvePath(String repository, String path) {
  if (_isAbsolutePath(path)) return File(path).absolute.path;
  return File('$repository/$path').absolute.path;
}

String _relativeToRepository(String repository, String absolutePath) {
  final root = Directory(repository).absolute.path;
  final candidate = File(absolutePath).absolute.path;
  if (candidate == root) return '.';
  final prefix = '$root${Platform.pathSeparator}';
  if (!candidate.startsWith(prefix)) {
    throw CoverageFailure('Path is outside the repository: $absolutePath');
  }
  return _normalizeRelativePath(
    candidate.substring(prefix.length).replaceAll(Platform.pathSeparator, '/'),
  );
}

String _normalizeRelativePath(String path) {
  if (path.isEmpty || _isAbsolutePath(path) || path.contains('\\')) {
    throw CoverageFailure('Invalid relative path: $path');
  }
  final result = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      throw CoverageFailure('Relative path escapes its root: $path');
    }
    result.add(segment);
  }
  if (result.isEmpty) {
    throw CoverageFailure('Invalid relative path: $path');
  }
  return result.join('/');
}

bool _isAbsolutePath(String path) =>
    path.startsWith('/') || RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);

String _sorted(Iterable<String> values) {
  final sorted = values.toList()..sort();
  return sorted.join(', ');
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
