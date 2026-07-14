import 'dart:convert';

import '../release/canonical_json.dart';
import 'failure.dart';

final class PerformanceReportDocument {
  PerformanceReportDocument({
    required Map<String, Object?> stable,
    required Map<String, Object?> observations,
  }) : stable = Map.unmodifiable(stable),
       observations = Map.unmodifiable(observations) {
    _requireCaseMap(this.stable, 'stable');
    _requireCaseMap(this.observations, 'observations', allowEmpty: true);
    final stableCases = this.stable.keys.toSet();
    final observationCases = this.observations.keys.toSet();
    final missing = stableCases.difference(observationCases);
    final unknown = observationCases.difference(stableCases);
    if (missing.isNotEmpty || unknown.isNotEmpty) {
      final details = <String>[
        if (missing.isNotEmpty) 'missing: ${_sorted(missing).join(', ')}',
        if (unknown.isNotEmpty) 'unknown: ${_sorted(unknown).join(', ')}',
      ];
      throw PerformanceFailure(
        'observation cases do not match stable cases '
        '(${details.join('; ')}).',
      );
    }
  }

  factory PerformanceReportDocument.parseCanonical(String contents) {
    final root = _parseCanonicalObject(contents, 'performance report');
    _requireKeys(root, 'performance report', const {
      'observations',
      'schemaVersion',
      'stable',
    });
    _requireSchema(root['schemaVersion'], 'performance report');
    return PerformanceReportDocument(
      stable: _object(root['stable'], 'performance report.stable'),
      observations: _object(
        root['observations'],
        'performance report.observations',
      ),
    );
  }

  static const schemaVersion = 1;

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;

  Map<String, Object?> toJson() => {
    'observations': observations,
    'schemaVersion': schemaVersion,
    'stable': stable,
  };

  String get canonicalJson => encodeCanonicalJson(toJson());

  PerformanceBaselineDocument get baseline =>
      PerformanceBaselineDocument(stable: stable);
}

final class PerformanceBaselineDocument {
  PerformanceBaselineDocument({required Map<String, Object?> stable})
    : stable = Map.unmodifiable(stable) {
    _requireCaseMap(this.stable, 'stable');
  }

  factory PerformanceBaselineDocument.parseCanonical(String contents) {
    final root = _parseCanonicalObject(contents, 'performance baseline');
    _requireKeys(root, 'performance baseline', const {
      'schemaVersion',
      'stable',
    });
    _requireSchema(root['schemaVersion'], 'performance baseline');
    return PerformanceBaselineDocument(
      stable: _object(root['stable'], 'performance baseline.stable'),
    );
  }

  static const schemaVersion = 1;

  final Map<String, Object?> stable;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'stable': stable,
  };

  String get canonicalJson => encodeCanonicalJson(toJson());
}

final class PerformancePolicyDocument {
  PerformancePolicyDocument({required Iterable<String> requiredCases})
    : requiredCases = List.unmodifiable(requiredCases) {
    _requireSortedUnique(this.requiredCases, 'requiredCases');
  }

  factory PerformancePolicyDocument.parseCanonical(String contents) {
    final root = _parseCanonicalObject(contents, 'performance policy');
    _requireKeys(root, 'performance policy', const {
      'requiredCases',
      'schemaVersion',
    });
    _requireSchema(root['schemaVersion'], 'performance policy');
    final cases =
        _list(
          root['requiredCases'],
          'performance policy.requiredCases',
        ).asMap().entries.map((entry) {
          final value = entry.value;
          if (value is! String || value.isEmpty || value != value.trim()) {
            throw PerformanceFailure(
              'performance policy.requiredCases[${entry.key}] must be a '
              'non-empty trimmed string.',
            );
          }
          return value;
        });
    return PerformancePolicyDocument(requiredCases: cases);
  }

  final List<String> requiredCases;
}

Map<String, Object?> _parseCanonicalObject(String contents, String name) {
  final canonicalContents = contents.endsWith('\n')
      ? contents.substring(0, contents.length - 1)
      : contents;
  final Object? decoded;
  try {
    decoded = jsonDecode(canonicalContents);
  } on FormatException catch (error) {
    throw PerformanceFailure('Invalid $name JSON: ${error.message}');
  }
  if (encodeCanonicalJson(decoded) != canonicalContents) {
    throw PerformanceFailure('$name JSON must be canonical.');
  }
  return _object(decoded, name);
}

Map<String, Object?> _object(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw PerformanceFailure('$name must be a JSON object.');
  }
  return value;
}

List<Object?> _list(Object? value, String name) {
  if (value is! List<Object?>) {
    throw PerformanceFailure('$name must be a JSON array.');
  }
  return value;
}

void _requireSchema(Object? value, String name) {
  if (value is! int || value != 1) {
    throw PerformanceFailure('$name schemaVersion must be 1.');
  }
}

void _requireCaseMap(
  Map<String, Object?> cases,
  String name, {
  bool allowEmpty = false,
}) {
  if (cases.isEmpty && !allowEmpty) {
    throw PerformanceFailure('$name must not be empty.');
  }
  for (final entry in cases.entries) {
    if (entry.key.isEmpty || entry.key != entry.key.trim()) {
      throw PerformanceFailure(
        '$name case names must be non-empty and trimmed.',
      );
    }
    if (entry.value is! Map<String, Object?>) {
      throw PerformanceFailure('$name.${entry.key} must be a JSON object.');
    }
  }
}

void _requireKeys(
  Map<String, Object?> object,
  String name,
  Set<String> expected,
) {
  final actual = object.keys.toSet();
  final missing = expected.difference(actual);
  final unknown = actual.difference(expected);
  if (missing.isEmpty && unknown.isEmpty) return;
  final details = <String>[
    if (missing.isNotEmpty) 'missing: ${_sorted(missing).join(', ')}',
    if (unknown.isNotEmpty) 'unknown: ${_sorted(unknown).join(', ')}',
  ];
  throw PerformanceFailure('$name has invalid fields (${details.join('; ')}).');
}

void _requireSortedUnique(List<String> values, String name) {
  if (values.isEmpty) throw PerformanceFailure('$name must not be empty.');
  for (var index = 1; index < values.length; index++) {
    if (values[index - 1].compareTo(values[index]) >= 0) {
      throw PerformanceFailure('$name must be strictly sorted and unique.');
    }
  }
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();
