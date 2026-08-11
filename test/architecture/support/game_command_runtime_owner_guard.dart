import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const gameEnginePath =
    'packages/aonw_core/lib/game/application/engine/game_engine.dart';
const gameIntentResolverPath =
    'lib/game/application/services/game_intent_resolver.dart';
const localCommandResolverPath =
    'lib/game/application/services/local_command_resolver.dart';
const legacyGameStateReducerPath =
    'lib/game/domain/reducer/game_state/game_state_reducer.dart';
const replayServicePath = 'lib/game/application/services/replay_service.dart';
const benchmarkCommandDispatcherPath =
    'tool/run_save_ai_benchmark/engine_command_dispatcher.dart';

const focusedGameEngineHandlers = <String>{
  'ArtifactTradeEngineHandler',
  'CityEngineHandler',
  'CombatEngineHandler',
  'DiplomacyEngineHandler',
  'MovementEngineHandler',
  'ProductionEngineHandler',
  'ResearchEngineHandler',
  'TurnEngineHandler',
  'TransportInfrastructureEngineHandler',
  'UnitActionEngineHandler',
  'WorkerEngineHandler',
};

const serverSystemCommandTypes = <String>{
  'FinalizeTimedOutTurn',
  'KickParticipant',
};

Map<String, int> runtimeDispatchTypeNameCounts(String source) {
  final counts = <String, int>{};
  parseString(
    content: source,
  ).unit.accept(_DispatchTypeNameCountCollector(counts));
  return counts;
}

Map<String, List<String>> runtimeConstructionPaths(
  Map<String, String> sources,
  Set<String> typeNames,
) {
  final paths = <String, List<String>>{};
  for (final entry in sources.entries) {
    final constructed = <String>[];
    parseString(
      content: entry.value,
      path: entry.key,
    ).unit.accept(_ConstructedTypeCollector(constructed, typeNames));
    for (final typeName in constructed) {
      paths.putIfAbsent(typeName, () => <String>[]).add(entry.key);
    }
  }
  return paths;
}

void expectCanonicalGameCommandRuntimeOwnership({
  required Map<String, String> sources,
  required Map<String, int> domainOwnerCounts,
  required Set<String> intentClassNames,
  required List<String> intentDispatchPaths,
}) {
  expect(
    domainOwnerCounts,
    {for (final className in domainOwnerCounts.keys) className: 1},
    reason:
        'Every concrete DomainCommand must map to exactly one GameEngine '
        'family.',
  );
  final intentPatterns = runtimeDispatchTypeNameCounts(
    sources[gameIntentResolverPath]!,
  );
  expect(
    {for (final name in intentClassNames) name: intentPatterns[name] ?? 0},
    {for (final name in intentClassNames) name: 1},
    reason:
        'Every concrete GameIntent must have exactly one GameIntentResolver '
        'branch.',
  );
  expect(
    intentDispatchPaths,
    isEmpty,
    reason:
        'GameIntent runtime dispatch is presentation-only and may not remain '
        'in server or AI rule composition.',
  );

  final handlerPaths = runtimeConstructionPaths(
    sources,
    focusedGameEngineHandlers,
  );
  expect(handlerPaths.keys, focusedGameEngineHandlers);
  expect(
    {for (final entry in handlerPaths.entries) entry.key: entry.value.toSet()},
    {
      for (final handler in focusedGameEngineHandlers)
        handler: {gameEnginePath},
    },
    reason: 'Focused engine handlers may only be constructed by GameEngine.',
  );
  final systemPaths = runtimeConstructionPaths(
    sources,
    serverSystemCommandTypes,
  );
  expect(systemPaths.keys, serverSystemCommandTypes);
  expect(
    systemPaths.values.expand((paths) => paths),
    everyElement(
      anyOf(
        startsWith('server/lib/src/'),
        equals(
          'packages/aonw_core/lib/game/application/engine/system_command.dart',
        ),
      ),
    ),
    reason:
        'Only trusted server code and the closed system codec may construct '
        'SystemCommand values.',
  );

  expect(sources[localCommandResolverPath], isNot(contains('reducer.reduce(')));
  expect(
    sources[benchmarkCommandDispatcherPath],
    isNot(contains('_reducer.reduce(')),
  );
  expect(
    sources[legacyGameStateReducerPath],
    allOf(
      isNot(contains('GameStateTransition reduce(')),
      isNot(contains('GameStateTransition reduceWithEnvironment(')),
    ),
  );
  expect(
    sources[replayServicePath],
    isNot(contains('GameIntentResolver')),
    reason:
        'Replay must reject presentation intents instead of resolving them.',
  );
}

final class _DispatchTypeNameCountCollector extends RecursiveAstVisitor<void> {
  _DispatchTypeNameCountCollector(this.counts);

  final Map<String, int> counts;

  @override
  void visitObjectPattern(ObjectPattern node) {
    final name = node.type.name.lexeme;
    counts[name] = (counts[name] ?? 0) + 1;
    super.visitObjectPattern(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (node.type case NamedType(:final name)) {
      counts[name.lexeme] = (counts[name.lexeme] ?? 0) + 1;
    }
    super.visitIsExpression(node);
  }
}

final class _ConstructedTypeCollector extends RecursiveAstVisitor<void> {
  _ConstructedTypeCollector(this.constructed, this.typeNames);

  final List<String> constructed;
  final Set<String> typeNames;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.type.name.lexeme;
    if (typeNames.contains(name)) constructed.add(name);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (node.target == null && typeNames.contains(name)) constructed.add(name);
    super.visitMethodInvocation(node);
  }
}
