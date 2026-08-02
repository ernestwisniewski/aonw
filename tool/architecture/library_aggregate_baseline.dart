import 'dart:io';

import 'failure.dart';
import 'library_aggregate_metrics.dart';
import 'library_aggregate_policy.dart';
import 'policy.dart';
import 'strict_json.dart';

final class LibraryAggregateBaseline {
  LibraryAggregateBaseline({
    required Map<String, ScopeLibraryAggregateBaseline> scopes,
  }) : scopes = Map.unmodifiable(sortedMap(scopes));

  factory LibraryAggregateBaseline.fromMetrics(
    ArchitecturePolicy architecturePolicy,
    LibraryAggregatePolicy aggregatePolicy,
    Map<String, Map<String, LibraryAggregateMetric>> metrics,
  ) {
    return LibraryAggregateBaseline(
      scopes: {
        for (final entry in architecturePolicy.scopes.entries)
          entry.key: ScopeLibraryAggregateBaseline.fromMetrics(
            entry.value,
            aggregatePolicy,
            metrics[entry.key]!,
          ),
      },
    );
  }

  factory LibraryAggregateBaseline.load(
    String path,
    ArchitecturePolicy architecturePolicy,
    LibraryAggregatePolicy aggregatePolicy,
  ) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ArchitectureFailure(
        'Architecture aggregate baseline does not exist: $path',
      );
    }
    return LibraryAggregateBaseline.parse(
      file.readAsStringSync(),
      architecturePolicy,
      aggregatePolicy,
      path,
    );
  }

  factory LibraryAggregateBaseline.parse(
    String contents,
    ArchitecturePolicy architecturePolicy,
    LibraryAggregatePolicy aggregatePolicy,
    String description,
  ) {
    final root = decodeObject(contents, description);
    expectKeys(root, const {'schema', 'scopes'}, description);
    if (readInt(root, 'schema', description) != schema) {
      throw ArchitectureFailure('$description has an unsupported schema.');
    }
    final rawScopes = readObject(root, 'scopes', description);
    expectKeys(
      rawScopes,
      architecturePolicy.scopes.keys.toSet(),
      '$description.scopes',
    );
    final baseline = LibraryAggregateBaseline(
      scopes: {
        for (final entry in rawScopes.entries)
          entry.key: ScopeLibraryAggregateBaseline.parse(
            entry.value,
            architecturePolicy.scopes[entry.key]!,
            aggregatePolicy,
            '$description.scopes.${entry.key}',
          ),
      },
    );
    requireCanonicalJson(contents, baseline.toJson(), description);
    return baseline;
  }

  static const schema = 1;

  final Map<String, ScopeLibraryAggregateBaseline> scopes;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'scopes': {
      for (final entry in scopes.entries) entry.key: entry.value.toJson(),
    },
  };

  String get canonicalRepresentation => canonicalJson(toJson());

  List<String> exactDifferences(LibraryAggregateBaseline expected) => [
    for (final name in scopes.keys)
      ...scopes[name]!.exactDifferences(expected.scopes[name]!, name),
  ];

  List<String> ratchetDifferences(LibraryAggregateBaseline historical) => [
    for (final name in scopes.keys)
      ...scopes[name]!.ratchetDifferences(historical.scopes[name]!, name),
  ];

  int get debtCount {
    final libraries = <String>{};
    for (final scope in scopes.values) {
      libraries
        ..addAll(scope.sourceLines.keys)
        ..addAll(scope.callableCount.keys)
        ..addAll(scope.callableLines.keys)
        ..addAll(scope.cyclomaticComplexity.keys)
        ..addAll(scope.cognitiveComplexity.keys);
    }
    return libraries.length;
  }
}

final class ScopeLibraryAggregateBaseline {
  const ScopeLibraryAggregateBaseline({
    required this.sourceLines,
    required this.callableCount,
    required this.callableLines,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  factory ScopeLibraryAggregateBaseline.fromMetrics(
    ScopePolicy scope,
    LibraryAggregatePolicy aggregatePolicy,
    Map<String, LibraryAggregateMetric> metrics,
  ) {
    final sourceLines = <String, int>{};
    final callableCount = <String, int>{};
    final callableLines = <String, int>{};
    final cyclomaticComplexity = <String, int>{};
    final cognitiveComplexity = <String, int>{};
    for (final entry in metrics.entries) {
      final targets = aggregatePolicy.targetsFor(scope.roleFor(entry.key));
      final metric = entry.value;
      if (metric.sourceLines > targets.sourceLines) {
        sourceLines[entry.key] = metric.sourceLines;
      }
      if (metric.callableCount > targets.callableCount) {
        callableCount[entry.key] = metric.callableCount;
      }
      if (metric.callableLines > targets.callableLines) {
        callableLines[entry.key] = metric.callableLines;
      }
      if (metric.cyclomaticComplexity > targets.cyclomaticComplexity) {
        cyclomaticComplexity[entry.key] = metric.cyclomaticComplexity;
      }
      if (metric.cognitiveComplexity > targets.cognitiveComplexity) {
        cognitiveComplexity[entry.key] = metric.cognitiveComplexity;
      }
    }
    return ScopeLibraryAggregateBaseline(
      sourceLines: Map.unmodifiable(sortedMap(sourceLines)),
      callableCount: Map.unmodifiable(sortedMap(callableCount)),
      callableLines: Map.unmodifiable(sortedMap(callableLines)),
      cyclomaticComplexity: Map.unmodifiable(sortedMap(cyclomaticComplexity)),
      cognitiveComplexity: Map.unmodifiable(sortedMap(cognitiveComplexity)),
    );
  }

  factory ScopeLibraryAggregateBaseline.parse(
    Object? value,
    ScopePolicy scope,
    LibraryAggregatePolicy aggregatePolicy,
    String description,
  ) {
    final object = asObject(value, description);
    expectKeys(object, const {
      'sourceLines',
      'callableCount',
      'callableLines',
      'cyclomaticComplexity',
      'cognitiveComplexity',
    }, description);
    Map<String, int> metric(
      String key,
      int Function(LibraryAggregateTargets targets) target,
    ) => _readMetricMap(
      object,
      key,
      description,
      scope,
      aggregatePolicy,
      target,
    );
    return ScopeLibraryAggregateBaseline(
      sourceLines: metric('sourceLines', (targets) => targets.sourceLines),
      callableCount: metric(
        'callableCount',
        (targets) => targets.callableCount,
      ),
      callableLines: metric(
        'callableLines',
        (targets) => targets.callableLines,
      ),
      cyclomaticComplexity: metric(
        'cyclomaticComplexity',
        (targets) => targets.cyclomaticComplexity,
      ),
      cognitiveComplexity: metric(
        'cognitiveComplexity',
        (targets) => targets.cognitiveComplexity,
      ),
    );
  }

  final Map<String, int> sourceLines;
  final Map<String, int> callableCount;
  final Map<String, int> callableLines;
  final Map<String, int> cyclomaticComplexity;
  final Map<String, int> cognitiveComplexity;

  Map<String, Object?> toJson() => {
    'sourceLines': sortedMap(sourceLines),
    'callableCount': sortedMap(callableCount),
    'callableLines': sortedMap(callableLines),
    'cyclomaticComplexity': sortedMap(cyclomaticComplexity),
    'cognitiveComplexity': sortedMap(cognitiveComplexity),
  };

  List<String> exactDifferences(
    ScopeLibraryAggregateBaseline expected,
    String scopeName,
  ) => [
    ..._exact(sourceLines, expected.sourceLines, '$scopeName library lines'),
    ..._exact(
      callableCount,
      expected.callableCount,
      '$scopeName library callable count',
    ),
    ..._exact(
      callableLines,
      expected.callableLines,
      '$scopeName library callable lines',
    ),
    ..._exact(
      cyclomaticComplexity,
      expected.cyclomaticComplexity,
      '$scopeName library cyclomatic complexity',
    ),
    ..._exact(
      cognitiveComplexity,
      expected.cognitiveComplexity,
      '$scopeName library cognitive complexity',
    ),
  ];

  List<String> ratchetDifferences(
    ScopeLibraryAggregateBaseline historical,
    String scopeName,
  ) => [
    ..._ratchet(
      sourceLines,
      historical.sourceLines,
      '$scopeName library lines',
    ),
    ..._ratchet(
      callableCount,
      historical.callableCount,
      '$scopeName library callable count',
    ),
    ..._ratchet(
      callableLines,
      historical.callableLines,
      '$scopeName library callable lines',
    ),
    ..._ratchet(
      cyclomaticComplexity,
      historical.cyclomaticComplexity,
      '$scopeName library cyclomatic complexity',
    ),
    ..._ratchet(
      cognitiveComplexity,
      historical.cognitiveComplexity,
      '$scopeName library cognitive complexity',
    ),
  ];
}

Map<String, int> _readMetricMap(
  Map<String, Object?> object,
  String key,
  String description,
  ScopePolicy scope,
  LibraryAggregatePolicy aggregatePolicy,
  int Function(LibraryAggregateTargets targets) target,
) {
  final raw = readObject(object, key, description);
  final result = <String, int>{};
  for (final entry in raw.entries) {
    validateRepositoryPath(entry.key, '$description.$key path');
    if (!entry.key.startsWith('${scope.sourceRoot}/') ||
        !entry.key.endsWith('.dart')) {
      throw ArchitectureFailure(
        '$description.$key entry is outside ${scope.sourceRoot}: ${entry.key}',
      );
    }
    final value = entry.value;
    if (value is! int || value < 1) {
      throw ArchitectureFailure(
        '$description.$key.${entry.key} must be a positive integer.',
      );
    }
    final limit = target(aggregatePolicy.targetsFor(scope.roleFor(entry.key)));
    if (value <= limit) {
      throw ArchitectureFailure(
        '$description.$key debt is not above $limit: ${entry.key}=$value',
      );
    }
    result[entry.key] = value;
  }
  return Map.unmodifiable(sortedMap(result));
}

List<String> _exact(
  Map<String, int> current,
  Map<String, int> expected,
  String label,
) {
  final failures = <String>[];
  final added = current.keys.toSet().difference(expected.keys.toSet()).toList()
    ..sort();
  final removed =
      expected.keys.toSet().difference(current.keys.toSet()).toList()..sort();
  if (added.isNotEmpty) failures.add('$label debt added: $added');
  if (removed.isNotEmpty) failures.add('$label debt removed: $removed');
  for (final key in current.keys.toSet().intersection(expected.keys.toSet())) {
    if (current[key] != expected[key]) {
      failures.add(
        '$label metric changed: $key ${expected[key]} -> ${current[key]}',
      );
    }
  }
  failures.sort();
  return failures;
}

List<String> _ratchet(
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
