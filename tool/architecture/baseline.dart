import 'dart:io';

import 'failure.dart';
import 'policy.dart';
import 'strict_json.dart';

final class ArchitectureBaseline {
  ArchitectureBaseline({required Map<String, ScopeBaseline> scopes})
    : scopes = Map.unmodifiable(sortedMap(scopes));

  factory ArchitectureBaseline.empty(ArchitecturePolicy policy) =>
      ArchitectureBaseline(
        scopes: {
          for (final name in policy.scopes.keys)
            name: const ScopeBaseline(files: {}, declarations: {}),
        },
      );

  factory ArchitectureBaseline.load(String path, ArchitecturePolicy policy) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArchitectureFailure('Architecture baseline does not exist: $path');
    }
    return ArchitectureBaseline.parse(file.readAsStringSync(), policy, path);
  }

  factory ArchitectureBaseline.parse(
    String contents,
    ArchitecturePolicy policy,
    String description,
  ) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {'schema', 'scopes'}, description);
    if (readInt(root, 'schema', description) != 1) {
      throw ArchitectureFailure('$description has an unsupported schema.');
    }
    final rawScopes = readObject(root, 'scopes', description);
    expectKeys(rawScopes, policy.scopes.keys.toSet(), '$description.scopes');
    final scopes = <String, ScopeBaseline>{};
    for (final entry in rawScopes.entries) {
      scopes[entry.key] = ScopeBaseline.parse(
        entry.value,
        policy.scopes[entry.key]!,
        '$description.scopes.${entry.key}',
      );
    }
    final baseline = ArchitectureBaseline(scopes: scopes);
    requireCanonicalJson(contents, baseline.toJson(), description);
    return baseline;
  }

  final Map<String, ScopeBaseline> scopes;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  List<String> exactDifferences(ArchitectureBaseline expected) {
    final failures = <String>[];
    for (final name in scopes.keys) {
      failures.addAll(
        scopes[name]!.exactDifferences(expected.scopes[name]!, name),
      );
    }
    return failures;
  }

  List<String> ratchetDifferences(ArchitectureBaseline historical) {
    final failures = <String>[];
    for (final name in scopes.keys) {
      failures.addAll(
        scopes[name]!.ratchetDifferences(historical.scopes[name]!, name),
      );
    }
    return failures;
  }

  int get fileDebtCount =>
      scopes.values.fold(0, (sum, scope) => sum + scope.files.length);

  int get declarationDebtCount =>
      scopes.values.fold(0, (sum, scope) => sum + scope.declarations.length);
}

final class ScopeBaseline {
  const ScopeBaseline({required this.files, required this.declarations});

  factory ScopeBaseline.parse(
    Object? value,
    ScopePolicy policy,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {'files', 'declarations'}, description);
    final files = _readMetricMap(
      object,
      'files',
      description,
      validate: (path, lines) {
        validateRepositoryPath(path, '$description.files key');
        if (!path.startsWith('${policy.sourceRoot}/') ||
            !path.endsWith('.dart')) {
          throw ArchitectureFailure(
            '$description has an invalid file debt path: $path',
          );
        }
        final target = policy.profileFor(path).lineTarget;
        if (lines <= target) {
          throw ArchitectureFailure(
            '$description file debt is not above its $target line target: '
            '$path=$lines',
          );
        }
      },
    );
    final declarations = _readMetricMap(
      object,
      'declarations',
      description,
      validate: (key, lines) {
        final separator = key.indexOf('::');
        if (separator <= 0 || separator == key.length - 2) {
          throw ArchitectureFailure(
            '$description has an invalid declaration debt key: $key',
          );
        }
        final path = key.substring(0, separator);
        validateRepositoryPath(path, '$description.declarations path');
        if (!path.startsWith('${policy.sourceRoot}/') ||
            !path.endsWith('.dart')) {
          throw ArchitectureFailure(
            '$description declaration is outside ${policy.sourceRoot}: $key',
          );
        }
        if (lines <= policy.declarationLineTarget) {
          throw ArchitectureFailure(
            '$description declaration debt is not above its '
            '${policy.declarationLineTarget} line target: $key=$lines',
          );
        }
      },
    );
    return ScopeBaseline(files: files, declarations: declarations);
  }

  final Map<String, int> files;
  final Map<String, int> declarations;

  Map<String, Object?> toJson() => {
    'files': sortedMap(files),
    'declarations': sortedMap(declarations),
  };

  List<String> exactDifferences(ScopeBaseline expected, String scopeName) => [
    ..._exactMapDifferences(files, expected.files, '$scopeName file'),
    ..._exactMapDifferences(
      declarations,
      expected.declarations,
      '$scopeName declaration',
    ),
  ];

  List<String> ratchetDifferences(ScopeBaseline historical, String scopeName) =>
      [
        ..._ratchetMapDifferences(files, historical.files, '$scopeName file'),
        ..._ratchetMapDifferences(
          declarations,
          historical.declarations,
          '$scopeName declaration',
        ),
      ];
}

Map<String, int> _readMetricMap(
  Map<String, Object?> object,
  String key,
  String description, {
  required void Function(String key, int lines) validate,
}) {
  final raw = readObject(object, key, description);
  final result = <String, int>{};
  for (final entry in raw.entries) {
    if (entry.value is! int || (entry.value! as int) < 1) {
      throw ArchitectureFailure(
        '$description.$key.${entry.key} must be a positive integer.',
      );
    }
    final lines = entry.value! as int;
    validate(entry.key, lines);
    result[entry.key] = lines;
  }
  return Map.unmodifiable(sortedMap(result));
}

List<String> _exactMapDifferences(
  Map<String, int> actual,
  Map<String, int> expected,
  String label,
) {
  final failures = <String>[];
  final added = actual.keys.toSet().difference(expected.keys.toSet()).toList()
    ..sort();
  final removed = expected.keys.toSet().difference(actual.keys.toSet()).toList()
    ..sort();
  if (added.isNotEmpty) failures.add('$label debt added: $added');
  if (removed.isNotEmpty) failures.add('$label debt removed: $removed');
  for (final key in actual.keys.toSet().intersection(expected.keys.toSet())) {
    if (actual[key] != expected[key]) {
      failures.add(
        '$label metric changed: $key ${expected[key]} -> ${actual[key]}',
      );
    }
  }
  failures.sort();
  return failures;
}

List<String> _ratchetMapDifferences(
  Map<String, int> current,
  Map<String, int> historical,
  String label,
) {
  final failures = <String>[];
  final added =
      current.keys.toSet().difference(historical.keys.toSet()).toList()..sort();
  if (added.isNotEmpty) {
    failures.add('$label debt cannot be introduced: $added');
  }
  for (final key in current.keys.toSet().intersection(
    historical.keys.toSet(),
  )) {
    if (current[key]! > historical[key]!) {
      failures.add(
        '$label debt cannot grow: $key ${historical[key]} -> ${current[key]}',
      );
    }
  }
  failures.sort();
  return failures;
}
