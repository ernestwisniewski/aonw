import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _mctsSimulatorPath = 'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';
const _economyCommandApplierPath =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';
const _activePlayerSyncPath =
    'lib/game/domain/reducer/game_state/'
    'game_state_reducer_active_player.dart';

void main() {
  test('AI and MCTS finalize turns only through GameEngine', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'PersistentTurnEconomyProcessor',
        'advanceForPlayers',
      ),
      isEmpty,
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'PersistentTurnMovementProcessor',
        'resetForPlayers',
      ),
      isEmpty,
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'SimulationGameEngineAdapter',
        'finalizeSimultaneousTurn',
      ),
      {_mctsSimulatorPath: 1, _economyCommandApplierPath: 1},
      reason:
          'Turn simulation may sequence submissions, but every turn effect '
          'must come from GameEngine.',
    );
  });

  test('turn bypass ratchet detects direct persistent processor calls', () {
    const sources = {
      'packages/aonw_core/lib/ai/second_turn_engine.dart': '''
void advance(Object state) {
  PersistentTurnEconomyProcessor.advanceForPlayers(state: state);
  PersistentTurnMovementProcessor.resetForPlayers(state: state);
}
''',
    };

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'PersistentTurnEconomyProcessor',
        'advanceForPlayers',
      ),
      isNotEmpty,
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'PersistentTurnMovementProcessor',
        'resetForPlayers',
      ),
      isNotEmpty,
    );
  });

  test('retired alternative turn entry points stay removed', () {
    final sources = productionDartSources();

    expect(
      removedProductionSymbolViolations(
        sources,
        symbol: 'EndTurnReducer',
        uriSuffix: '/end_turn_reducer.dart',
      ),
      isEmpty,
    );
    expect(
      removedProductionSymbolViolations(
        sources,
        symbol: 'PersistentTurnPipeline',
        uriSuffix: '/persistent_turn_pipeline.dart',
      ),
      isEmpty,
    );
    expect(
      File('lib/game/domain/reducer/turn/end_turn_reducer.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/aonw_core/lib/game/domain/turn/'
        'persistent_turn_pipeline.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('active-player presentation sync does not recalculate domain rules', () {
    final source = productionDartSources()[_activePlayerSyncPath]!;

    expect(source, isNot(contains('FogOfWarService')));
    expect(source, isNot(contains('DiplomaticContact')));
    expect(source, isNot(contains('withDiscoveredDiplomaticContacts')));
  });
}
