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
  final violations = <String>[];
  final constructionsByPath = <String, List<ArgumentList>>{};
  final runAiTurnUseCaseConstructionsByPath = <String, List<ArgumentList>>{};

  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _TypeConstructionCollector('GameStateReducer');
    unit.accept(collector);
    if (collector.calls.isNotEmpty) {
      constructionsByPath[entry.key] = collector.calls;
    }
    final runAiTurnUseCaseCollector = _TypeConstructionCollector(
      'RunAiTurnUseCase',
    );
    unit.accept(runAiTurnUseCaseCollector);
    if (runAiTurnUseCaseCollector.calls.isNotEmpty) {
      runAiTurnUseCaseConstructionsByPath[entry.key] =
          runAiTurnUseCaseCollector.calls;
    }
  }

  for (final entry in constructionsByPath.entries) {
    if (!_localReducerConstructionContracts.containsKey(entry.key)) {
      violations.add(
        '${entry.key} must not construct GameStateReducer outside the '
        'indexed local composition roots',
      );
    }
  }

  for (final entry in runAiTurnUseCaseConstructionsByPath.entries) {
    if (!_runAiTurnUseCaseConstructionContracts.containsKey(entry.key)) {
      violations.add(
        '${entry.key} must not construct RunAiTurnUseCase outside the '
        'indexed AI composition roots',
      );
    }
  }

  for (final contractEntry in _localReducerConstructionContracts.entries) {
    final path = contractEntry.key;
    final contract = contractEntry.value;
    final source = sources[path];
    if (source == null) {
      violations.add('$path must remain a local reducer composition root');
      continue;
    }
    final constructions = constructionsByPath[path] ?? const [];
    if (constructions.length != contract.count) {
      violations.add(
        '$path must construct GameStateReducer exactly ${contract.count} '
        'time(s); found '
        '${constructions.length}',
      );
    }
    for (final construction in constructions) {
      final mapData = _namedArgument(construction, 'mapData');
      final source = mapData?.toSource() ?? '<missing>';
      if (!contract.mapSources.contains(source)) {
        violations.add(
          '$path must pass an approved indexed MapReadView to '
          'GameStateReducer.mapData; found $source',
        );
      }
    }
  }

  for (final contractEntry in _runAiTurnUseCaseConstructionContracts.entries) {
    final path = contractEntry.key;
    final contract = contractEntry.value;
    final source = sources[path];
    if (source == null) {
      violations.add('$path must remain an AI composition root');
      continue;
    }
    final constructions = runAiTurnUseCaseConstructionsByPath[path] ?? const [];
    if (constructions.length != contract.count) {
      violations.add(
        '$path must construct RunAiTurnUseCase exactly ${contract.count} '
        'time(s); found ${constructions.length}',
      );
    }
    for (final construction in constructions) {
      final mapData = _namedArgument(construction, 'mapData');
      final source = mapData?.toSource() ?? '<missing>';
      if (!contract.mapSources.contains(source)) {
        violations.add(
          '$path must pass an approved indexed MapReadView to '
          'RunAiTurnUseCase.mapData; found $source',
        );
      }
    }
  }

  for (final countEntry in _localReducerIndexedReadCounts.entries) {
    final path = countEntry.key;
    final expectedCount = countEntry.value;
    final source = sources[path];
    if (source == null) {
      violations.add('$path must remain covered by the map-view index guard');
      continue;
    }
    final unit = parseString(content: source, path: path).unit;
    final indexedReads = _NamedInvocationCollector('indexedReadView');
    unit.accept(indexedReads);
    if (indexedReads.invocations.length != expectedCount) {
      violations.add(
        '$path must call indexedReadView exactly $expectedCount time(s); found '
        '${indexedReads.invocations.length}',
      );
    }
  }

  final resolverSource = sources[_localCommandResolverPath];
  if (resolverSource == null) {
    violations.add(
      '$_localCommandResolverPath must forward the indexed reducer map view',
    );
    return violations;
  }
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
