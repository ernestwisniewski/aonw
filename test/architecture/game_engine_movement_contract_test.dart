import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/movement_family_pattern_guard.dart';
import 'support/static_member_reference_guard.dart';

const _engineHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'movement_engine_handler.dart';
const _gameEnginePath =
    'packages/aonw_core/lib/game/application/engine/game_engine.dart';
void main() {
  test('movement handler has exactly one game engine call-site', () {
    expect(
      instanceMemberReferenceCountsByPath(
        productionDartSources(),
        'MovementEngineHandler',
        'apply',
      ),
      {_gameEnginePath: 1},
      reason: 'MovementEngineHandler.apply must remain private to GameEngine.',
    );
  });

  test('movement domain adapters have one engine composition point', () {
    final sources = productionDartSources();

    for (final (typeName, methodName) in const [
      ('DomainMoveUnitResolver', 'resolve'),
      ('DomainAutoExploreCommandResolver', 'resolve'),
      ('DomainMerchantRoutingCommandResolver', 'assignRoute'),
      ('DomainMerchantRoutingCommandResolver', 'moveToCity'),
      ('DomainUnitActionCommandResolver', 'cancelUnitAction'),
      ('DomainUnitDetachmentResolver', 'detachTroop'),
    ]) {
      expect(
        instanceMemberReferenceCountsByPath(sources, typeName, methodName),
        {_engineHandlerPath: 1},
        reason: '$typeName.$methodName must be composed only by GameEngine.',
      );
    }
  });

  test('local server AI and replay cannot bypass movement engine', () {
    final runtimeSources = _localServerAiReplaySources(productionDartSources());
    for (final (typeName, methodName) in const [
      ('MovementCommandResolver', 'resolve'),
      ('AutoExploreCommandResolver', 'resolve'),
      ('MerchantRoutingCommandResolver', 'assignRoute'),
      ('MerchantRoutingCommandResolver', 'moveToCity'),
      ('UnitActionCommandResolver', 'cancelUnitAction'),
      ('DetachTroopResolver', 'detachTroop'),
    ]) {
      final references =
          typeName == 'MerchantRoutingCommandResolver' ||
              typeName == 'UnitActionCommandResolver' ||
              typeName == 'DetachTroopResolver'
          ? staticMemberReferenceCountsByPath(
              runtimeSources,
              typeName,
              methodName,
            )
          : instanceMemberReferenceCountsByPath(
              runtimeSources,
              typeName,
              methodName,
            );
      expect(
        references,
        isEmpty,
        reason:
            'Local/server/AI/replay runtime must not call '
            '$typeName.$methodName.',
      );
    }

    expect(
      unreviewedMovementFamilyPatternPaths(runtimeSources),
      isEmpty,
      reason:
          'Every movement-family switch must remain either an engine bridge '
          'or an explicitly reviewed non-execution planning/presentation '
          'branch.',
    );
  });

  test('family switch ratchet rejects an unreviewed runtime branch', () {
    final sources = {
      ..._localServerAiReplaySources(productionDartSources()),
      'lib/game/application/services/second_movement_executor.dart': '''
Object execute(Object command) => switch (command) {
  MoveUnitCommand() => command,
  _ => command,
};
''',
    };

    expect(
      unreviewedMovementFamilyPatternPaths(sources),
      contains('lib/game/application/services/second_movement_executor.dart'),
    );
  });

  test(
    'family switch ratchet rejects an added occurrence in reviewed path',
    () {
      const path =
          'lib/game/application/services/authoritative_command_policy.dart';
      final runtimeSources = _localServerAiReplaySources(
        productionDartSources(),
      );
      final sources = {
        ...runtimeSources,
        path:
            '''
${runtimeSources[path]}
Object secondMovementFamilySwitch(Object command) => switch (command) {
  MoveUnitCommand() => command,
  _ => command,
};
''',
      };

      expect(unreviewedMovementFamilyPatternPaths(sources), contains(path));
    },
  );

  test('migrated command routing shares the game engine classifier', () {
    final sources = productionDartSources();
    expect(
      staticMemberReferenceCountsByPath(sources, 'GameEngine', 'commandFamily'),
      {
        'packages/aonw_core/lib/ai/simulation/'
                'economy_simulation_command_applier.dart':
            1,
        'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart': 1,
        'packages/aonw_core/lib/ai/mcts/mcts_simulated_state.dart': 1,
        'lib/game/application/services/'
                'accepted_engine_command_interaction_source.dart':
            1,
        'lib/game/application/services/local_command_resolver.dart': 1,
        'lib/game/application/services/'
                'local_city_economy_command_resolver.dart':
            1,
        'lib/game/application/services/'
                'local_research_diplomacy_command_resolver.dart':
            1,
        'tool/run_save_ai_benchmark/engine_command_dispatcher.dart': 1,
      },
    );
    final benchmarkSources = _saveAiBenchmarkSources(sources);
    expect(
      instanceMemberReferenceCountsByPath(
        benchmarkSources,
        'GameStateReducer',
        'reduce',
      ),
      isEmpty,
    );
    expect(
      instanceMemberReferenceCountsByPath(
        benchmarkSources,
        'SimulationGameEngineAdapter',
        'apply',
      ),
      {'tool/run_save_ai_benchmark/engine_command_dispatcher.dart': 1},
    );
  });

  test('benchmark replay derives the complete persistent state', () {
    final benchmarkSources = _saveAiBenchmarkSources(productionDartSources());

    expect(
      constructedTypeViolations(benchmarkSources, type: 'PersistentGameState'),
      isEmpty,
      reason:
          'Benchmark replay must use GameClientState.toPersistentState so new '
          'persistent slices cannot be silently dropped.',
    );
  });

  test('move preview confirmation is transport-owned and rule-free', () {
    final preview = File(
      'lib/game/domain/reducer/movement/movement_reducer_move_preview.dart',
    ).readAsStringSync();
    final policy = File(
      'lib/game/application/services/authoritative_command_policy.dart',
    ).readAsStringSync();

    expect(preview, isNot(contains('MovementCommandResolver')));
    expect(preview, isNot(contains('MovementReducer.moveUnit')));
    expect(policy, contains('return MoveUnitCommand('));
  });

  test('movement performance workload measures the game engine boundary', () {
    final workload = File(
      'tool/performance/movement_command_workload.dart',
    ).readAsStringSync();

    expect(workload, contains('const GameEngine().apply('));
    expect(workload, isNot(contains('PersistentMoveUnitResolver')));
  });
}

Map<String, String> _localServerAiReplaySources(Map<String, String> sources) =>
    {
      for (final entry in sources.entries)
        if (entry.key.startsWith('lib/') ||
            entry.key.startsWith('server/lib/') ||
            entry.key.startsWith('server/bin/') ||
            entry.key.startsWith('packages/aonw_core/lib/ai/'))
          entry.key: entry.value,
    };

Map<String, String> _saveAiBenchmarkSources(Map<String, String> sources) => {
  for (final entry in sources.entries)
    if (entry.key == 'tool/run_save_ai_benchmark.dart' ||
        entry.key.startsWith('tool/run_save_ai_benchmark/'))
      entry.key: entry.value,
};
