part of '../world_map_projection_boundary_test.dart';

const _gameStateProviderPath =
    'lib/game/presentation/providers/game/game_state_provider.dart';
const _replayProvidersPath =
    'lib/game/presentation/providers/replay/replay_providers.dart';
const _localCommandResolverPath =
    'lib/game/application/services/local_command_resolver.dart';
const _saveAiBenchmarkPath = 'tool/run_save_ai_benchmark.dart';
const _multiTurnReplayPath =
    'tool/run_save_ai_benchmark/multi_turn_replay.dart';
const _benchmarkSyntheticHelpersPath =
    'tool/run_save_ai_benchmark/benchmark_synthetic_helpers.dart';
const _runtimeSmokePath = 'tool/run_save_ai_benchmark/runtime_smoke.dart';
const _syntheticSuitePath = 'tool/run_save_ai_benchmark/synthetic_suite.dart';
const _replayWorkloadPath = 'tool/performance/replay_workload.dart';
const _aiTurnProcessPreparerPath =
    'lib/game/presentation/services/ai_turn_process_preparer.dart';
const _aiTurnPreparationBuilderPath =
    'lib/game/application/services/ai_turn_preparation_builder.dart';
const _runAiTurnUseCasePath =
    'lib/game/application/use_cases/run_ai_turn_use_case.dart';
const _localReducerConstructionContracts =
    <String, ({int count, Set<String> mapSources})>{
      _gameStateProviderPath: (
        count: 1,
        mapSources: {'session.mapData.indexedReadView()'},
      ),
      _replayProvidersPath: (
        count: 1,
        mapSources: {'session.mapData.indexedReadView()'},
      ),
      _saveAiBenchmarkPath: (count: 1, mapSources: {'context.mapData'}),
      _multiTurnReplayPath: (count: 1, mapSources: {'context.mapData'}),
      _benchmarkSyntheticHelpersPath: (
        count: 2,
        mapSources: {'prepared.context.mapData'},
      ),
      _runtimeSmokePath: (count: 1, mapSources: {'mapView'}),
      _replayWorkloadPath: (count: 1, mapSources: {'mapView'}),
    };
const _runAiTurnUseCaseConstructionContracts =
    <String, ({int count, Set<String> mapSources})>{
      _aiTurnProcessPreparerPath: (
        count: 1,
        mapSources: {'currentSession.mapData.indexedReadView()'},
      ),
      _runtimeSmokePath: (count: 1, mapSources: {'mapView'}),
    };
const _localReducerIndexedReadCounts = <String, int>{
  _gameStateProviderPath: 1,
  _replayProvidersPath: 1,
  _saveAiBenchmarkPath: 1,
  _multiTurnReplayPath: 0,
  _benchmarkSyntheticHelpersPath: 0,
  _runtimeSmokePath: 0,
  _syntheticSuitePath: 2,
  _replayWorkloadPath: 1,
  _aiTurnProcessPreparerPath: 1,
  _aiTurnPreparationBuilderPath: 0,
  _runAiTurnUseCasePath: 0,
};

List<String> _localReducerMapViewViolations() {
  return _localReducerMapViewViolationsFor(productionDartSources());
}

List<String> _localReducerMapViewViolationsFor(Map<String, String> sources) {
  final localReducerConstructions = _typeConstructionsByPath(
    sources,
    'GameStateReducer',
  );
  final runAiTurnUseCaseConstructions = _typeConstructionsByPath(
    sources,
    'RunAiTurnUseCase',
  );
  return [
    ..._unexpectedConstructionRootViolations(
      constructions: localReducerConstructions,
      contracts: _localReducerConstructionContracts,
      typeName: 'GameStateReducer',
      approvedRoots: 'indexed local composition roots',
    ),
    ..._constructionContractViolations(
      sources: sources,
      constructions: localReducerConstructions,
      contracts: _localReducerConstructionContracts,
      typeName: 'GameStateReducer',
      missingRoot: 'a local reducer composition root',
    ),
    ..._unexpectedConstructionRootViolations(
      constructions: runAiTurnUseCaseConstructions,
      contracts: _runAiTurnUseCaseConstructionContracts,
      typeName: 'RunAiTurnUseCase',
      approvedRoots: 'indexed AI composition roots',
    ),
    ..._constructionContractViolations(
      sources: sources,
      constructions: runAiTurnUseCaseConstructions,
      contracts: _runAiTurnUseCaseConstructionContracts,
      typeName: 'RunAiTurnUseCase',
      missingRoot: 'an AI composition root',
    ),
    ..._indexedReadCountViolations(sources),
    ..._localCommandResolverViolations(sources),
  ];
}

Map<String, List<ArgumentList>> _typeConstructionsByPath(
  Map<String, String> sources,
  String typeName,
) {
  final constructions = <String, List<ArgumentList>>{};
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _TypeConstructionCollector(typeName);
    unit.accept(collector);
    if (collector.calls.isNotEmpty) constructions[entry.key] = collector.calls;
  }
  return constructions;
}

List<String> _unexpectedConstructionRootViolations({
  required Map<String, List<ArgumentList>> constructions,
  required Map<String, ({int count, Set<String> mapSources})> contracts,
  required String typeName,
  required String approvedRoots,
}) => [
  for (final path in constructions.keys)
    if (!contracts.containsKey(path))
      '$path must not construct $typeName outside the $approvedRoots',
];

List<String> _constructionContractViolations({
  required Map<String, String> sources,
  required Map<String, List<ArgumentList>> constructions,
  required Map<String, ({int count, Set<String> mapSources})> contracts,
  required String typeName,
  required String missingRoot,
}) {
  final violations = <String>[];
  for (final entry in contracts.entries) {
    final path = entry.key;
    final contract = entry.value;
    if (!sources.containsKey(path)) {
      violations.add('$path must remain $missingRoot');
      continue;
    }
    final calls = constructions[path] ?? const [];
    if (calls.length != contract.count) {
      violations.add(
        '$path must construct $typeName exactly ${contract.count} time(s); '
        'found ${calls.length}',
      );
    }
    for (final call in calls) {
      final mapSource =
          _namedArgument(call, 'mapData')?.toSource() ?? '<missing>';
      if (!contract.mapSources.contains(mapSource)) {
        violations.add(
          '$path must pass an approved indexed MapReadView to '
          '$typeName.mapData; found $mapSource',
        );
      }
    }
  }
  return violations;
}

List<String> _indexedReadCountViolations(Map<String, String> sources) {
  final violations = <String>[];
  for (final entry in _localReducerIndexedReadCounts.entries) {
    final source = sources[entry.key];
    if (source == null) {
      violations.add(
        '${entry.key} must remain covered by the map-view index guard',
      );
      continue;
    }
    final unit = parseString(content: source, path: entry.key).unit;
    final indexedReads = _NamedInvocationCollector('indexedReadView');
    unit.accept(indexedReads);
    if (indexedReads.invocations.length != entry.value) {
      violations.add(
        '${entry.key} must call indexedReadView exactly ${entry.value} '
        'time(s); found ${indexedReads.invocations.length}',
      );
    }
  }
  return violations;
}

List<String> _localCommandResolverViolations(Map<String, String> sources) {
  final resolverSource = sources[_localCommandResolverPath];
  if (resolverSource == null) {
    return [
      '$_localCommandResolverPath must forward the indexed reducer map view',
    ];
  }
  final violations = <String>[];
  final resolverUnit = parseString(
    content: resolverSource,
    path: _localCommandResolverPath,
  ).unit;
  final indexedReads = _NamedInvocationCollector('indexedReadView');
  resolverUnit.accept(indexedReads);
  if (indexedReads.invocations.isNotEmpty) {
    violations.add(
      '$_localCommandResolverPath must reuse reducer.mapData without building '
      'another indexed view',
    );
  }

  final requests = _NamedTypeConstructionCollector(
    'PersistentTurnPipelineRequest.simultaneousFinalize',
  );
  resolverUnit.accept(requests);
  if (requests.calls.length != 1) {
    violations.add(
      '$_localCommandResolverPath must construct simultaneous-finalize request '
      'exactly once; found ${requests.calls.length}',
    );
  } else {
    final mapView = _namedArgument(requests.calls.single, 'mapView');
    if (mapView?.toSource() != 'reducer.mapData') {
      violations.add(
        '$_localCommandResolverPath must pass reducer.mapData directly to '
        'PersistentTurnPipelineRequest.mapView',
      );
    }
  }

  return violations;
}

Expression? _namedArgument(ArgumentList arguments, String name) {
  for (final argument in arguments.arguments) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      return argument.expression;
    }
  }
  return null;
}

final class _TypeConstructionCollector extends RecursiveAstVisitor<void> {
  _TypeConstructionCollector(this.typeName);

  final String typeName;
  final List<ArgumentList> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == typeName) {
      calls.add(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == typeName) {
      calls.add(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }
}

final class _NamedTypeConstructionCollector extends RecursiveAstVisitor<void> {
  _NamedTypeConstructionCollector(this.constructorSource);

  final String constructorSource;
  final List<ArgumentList> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final source = node.target == null
        ? node.methodName.name
        : '${node.target!.toSource()}.${node.methodName.name}';
    if (source == constructorSource) calls.add(node.argumentList);
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.toSource() == constructorSource) {
      calls.add(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }
}
