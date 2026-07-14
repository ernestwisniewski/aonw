import 'dart:io';

import 'failure.dart';
import 'policy.dart';
import 'strict_json.dart';

final class MutationBaseline {
  MutationBaseline({required Map<String, MutationScopeBaseline> scopes})
    : scopes = Map.unmodifiable(sortedMap(scopes));

  factory MutationBaseline.empty(MutationPolicy policy) => MutationBaseline(
    scopes: {
      for (final entry in policy.scopes.entries)
        entry.key: MutationScopeBaseline(
          targets: {for (final path in entry.value.targetFiles) path: 0},
          operatorTotals: {for (final name in policy.operators) name: 0},
          survivors: const {},
        ),
    },
  );

  factory MutationBaseline.load(String path, MutationPolicy policy) {
    final file = File(path);
    if (!file.existsSync()) {
      throw MutationFailure('Mutation baseline does not exist: $path');
    }
    return MutationBaseline.parse(file.readAsStringSync(), policy, path);
  }

  factory MutationBaseline.parse(
    String contents,
    MutationPolicy policy,
    String description,
  ) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {'schema', 'scopes'}, description);
    if (readInt(root, 'schema', description) != 1) {
      throw MutationFailure('$description has an unsupported schema.');
    }
    final rawScopes = readObject(root, 'scopes', description);
    expectKeys(rawScopes, policy.scopes.keys.toSet(), '$description.scopes');
    final scopes = <String, MutationScopeBaseline>{};
    for (final entry in rawScopes.entries) {
      scopes[entry.key] = MutationScopeBaseline.parse(
        entry.value,
        policy.scopes[entry.key]!,
        policy.operators,
        '$description.scopes.${entry.key}',
      );
    }
    final baseline = MutationBaseline(scopes: scopes);
    requireCanonicalJson(contents, baseline.toJson(), description);
    return baseline;
  }

  final Map<String, MutationScopeBaseline> scopes;

  int get mutantCount =>
      scopes.values.fold(0, (sum, scope) => sum + scope.mutantCount);

  int get survivorCount =>
      scopes.values.fold(0, (sum, scope) => sum + scope.survivors.length);

  Map<String, Object?> toJson() => {
    'schema': 1,
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  List<String> exactDifferences(MutationBaseline expected) {
    final failures = <String>[];
    for (final name in scopes.keys) {
      failures.addAll(
        scopes[name]!.exactDifferences(expected.scopes[name]!, name),
      );
    }
    return failures;
  }

  List<String> ratchetDifferences(MutationBaseline historical) {
    final failures = <String>[];
    for (final name in scopes.keys) {
      failures.addAll(
        scopes[name]!.ratchetDifferences(historical.scopes[name]!, name),
      );
    }
    return failures;
  }
}

final class MutationScopeBaseline {
  MutationScopeBaseline({
    required Map<String, int> targets,
    required Map<String, int> operatorTotals,
    required Map<String, MutationSurvivor> survivors,
  }) : targets = Map.unmodifiable(sortedMap(targets)),
       operatorTotals = Map.unmodifiable(sortedMap(operatorTotals)),
       survivors = Map.unmodifiable(sortedMap(survivors));

  factory MutationScopeBaseline.parse(
    Object? value,
    MutationScopePolicy policy,
    List<String> operators,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'targets',
      'operatorTotals',
      'survivors',
    }, description);
    final targets = _readCounts(object, 'targets', description);
    expectKeys(
      targets.cast<String, Object?>(),
      policy.targetFiles.toSet(),
      '$description.targets',
    );
    final operatorTotals = _readCounts(object, 'operatorTotals', description);
    expectKeys(
      operatorTotals.cast<String, Object?>(),
      operators.toSet(),
      '$description.operatorTotals',
    );
    final rawSurvivors = readObject(object, 'survivors', description);
    final survivors = <String, MutationSurvivor>{};
    for (final entry in rawSurvivors.entries) {
      _validateSurvivorId(entry.key, '$description.survivors key');
      survivors[entry.key] = MutationSurvivor.parse(
        entry.value,
        policy,
        operators,
        '$description.survivors.${entry.key}',
      );
    }

    final targetTotal = targets.values.fold(0, (sum, value) => sum + value);
    final operatorTotal = operatorTotals.values.fold(
      0,
      (sum, value) => sum + value,
    );
    if (targetTotal != operatorTotal) {
      throw MutationFailure(
        '$description target and operator totals differ: '
        '$targetTotal != $operatorTotal.',
      );
    }
    final survivorsByTarget = <String, int>{};
    final survivorsByOperator = <String, int>{};
    for (final survivor in survivors.values) {
      survivorsByTarget.update(
        survivor.path,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      survivorsByOperator.update(
        survivor.operator,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    for (final entry in survivorsByTarget.entries) {
      if (entry.value > targets[entry.key]!) {
        throw MutationFailure(
          '$description has more survivors than mutants for ${entry.key}.',
        );
      }
    }
    for (final entry in survivorsByOperator.entries) {
      if (entry.value > operatorTotals[entry.key]!) {
        throw MutationFailure(
          '$description has more survivors than mutants for ${entry.key}.',
        );
      }
    }
    return MutationScopeBaseline(
      targets: targets,
      operatorTotals: operatorTotals,
      survivors: survivors,
    );
  }

  final Map<String, int> targets;
  final Map<String, int> operatorTotals;
  final Map<String, MutationSurvivor> survivors;

  int get mutantCount => targets.values.fold(0, (sum, value) => sum + value);

  Map<String, Object?> toJson() => {
    'targets': targets,
    'operatorTotals': operatorTotals,
    'survivors': {
      for (final entry in survivors.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  List<String> exactDifferences(
    MutationScopeBaseline expected,
    String scopeName,
  ) {
    final failures = <String>[];
    if (!_sameMap(targets, expected.targets)) {
      failures.add('$scopeName mutation target census changed.');
    }
    if (!_sameMap(operatorTotals, expected.operatorTotals)) {
      failures.add('$scopeName mutation operator totals changed.');
    }
    if (!_sameMap(survivors, expected.survivors)) {
      failures.add('$scopeName mutation survivors changed.');
    }
    return failures;
  }

  List<String> ratchetDifferences(
    MutationScopeBaseline historical,
    String scopeName,
  ) {
    final failures = <String>[];
    final newIds =
        survivors.keys
            .toSet()
            .difference(historical.survivors.keys.toSet())
            .toList()
          ..sort();
    if (newIds.isNotEmpty) {
      failures.add('$scopeName cannot introduce mutation survivors: $newIds');
    }
    for (final id in survivors.keys.toSet().intersection(
      historical.survivors.keys.toSet(),
    )) {
      if (survivors[id] != historical.survivors[id]) {
        failures.add('$scopeName mutation survivor identity changed: $id');
      }
    }
    failures.sort();
    return failures;
  }
}

final class MutationSurvivor {
  const MutationSurvivor({
    required this.path,
    required this.operator,
    required this.declaration,
    required this.original,
    required this.replacement,
  });

  factory MutationSurvivor.parse(
    Object? value,
    MutationScopePolicy policy,
    List<String> operators,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'path',
      'operator',
      'declaration',
      'original',
      'replacement',
    }, description);
    final path = readString(object, 'path', description);
    validateRepositoryPath(path, '$description.path');
    if (!policy.targetFiles.contains(path)) {
      throw MutationFailure('$description.path is not a policy target: $path');
    }
    final operator = readString(object, 'operator', description);
    if (!operators.contains(operator)) {
      throw MutationFailure(
        '$description.operator is not enabled by the mutation policy: '
        '$operator',
      );
    }
    final declaration = readString(object, 'declaration', description);
    if (declaration.isEmpty) {
      throw MutationFailure('$description.declaration must not be empty.');
    }
    final original = readString(object, 'original', description);
    if (original.isEmpty) {
      throw MutationFailure('$description.original must not be empty.');
    }
    final replacement = readString(object, 'replacement', description);
    return MutationSurvivor(
      path: path,
      operator: operator,
      declaration: declaration,
      original: original,
      replacement: replacement,
    );
  }

  final String path;
  final String operator;
  final String declaration;
  final String original;
  final String replacement;

  Map<String, Object?> toJson() => {
    'path': path,
    'operator': operator,
    'declaration': declaration,
    'original': original,
    'replacement': replacement,
  };

  @override
  bool operator ==(Object other) =>
      other is MutationSurvivor &&
      path == other.path &&
      operator == other.operator &&
      declaration == other.declaration &&
      original == other.original &&
      replacement == other.replacement;

  @override
  int get hashCode =>
      Object.hash(path, operator, declaration, original, replacement);
}

Map<String, int> _readCounts(
  Map<String, Object?> object,
  String key,
  String description,
) {
  final raw = readObject(object, key, description);
  final result = <String, int>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! int || value < 0) {
      throw MutationFailure(
        '$description.$key.${entry.key} must be a non-negative integer.',
      );
    }
    result[entry.key] = value;
  }
  return Map.unmodifiable(sortedMap(result));
}

void _validateSurvivorId(String value, String description) {
  if (value.isEmpty ||
      value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw MutationFailure('$description must be a non-empty portable ID.');
  }
}

bool _sameMap<K, V>(Map<K, V> first, Map<K, V> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) return false;
  }
  return true;
}
