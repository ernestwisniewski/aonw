import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResearchReducer', () {
    final reducer = GameStateReducer(
      mapData: MapData(cols: 1, rows: 1, tiles: const []),
    );

    test('selects an available foundation technology', () {
      const state = GameState(activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
      );

      expect(
        result.state.research.forPlayer('player_1').activeTechnologyId,
        TechnologyId.agriculture,
      );
    });

    test('applies capped science overflow when selecting next technology', () {
      final state = GameState(
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
              scienceOverflow: 10,
            ),
          },
        ),
      );

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_1', TechnologyId.mining),
      );

      final playerResearch = result.state.research.forPlayer('player_1');
      expect(playerResearch.activeTechnologyId, TechnologyId.mining);
      expect(playerResearch.progressFor(TechnologyId.mining), 3);
      expect(playerResearch.scienceOverflow, 0);
    });

    test('selecting research clears research pending action', () {
      final state = const GameState(activePlayerId: 'player_1').copyWith(
        pendingAction: const PendingResearchSelection(
          ownerPlayerId: 'player_1',
        ),
      );

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
      );

      expect(result.state.pendingAction, isNull);
      expect(
        result.state.research.forPlayer('player_1').activeTechnologyId,
        TechnologyId.agriculture,
      );
    });

    test('cancel research selection clears matching pending action', () {
      final state = const GameState(activePlayerId: 'player_1').copyWith(
        pendingAction: const PendingResearchSelection(
          ownerPlayerId: 'player_1',
        ),
      );

      final result = reducer.reduce(
        state,
        const CancelResearchSelectionCommand('player_1'),
      );

      expect(result.state.pendingAction, isNull);
    });

    test('cancel research selection ignores other players pending action', () {
      final state = const GameState(activePlayerId: 'player_1').copyWith(
        pendingAction: const PendingResearchSelection(
          ownerPlayerId: 'player_2',
        ),
      );

      final result = reducer.reduce(
        state,
        const CancelResearchSelectionCommand('player_1'),
      );

      expect(result.state, state);
    });

    test('rejects technology with missing prerequisites', () {
      const state = GameState(activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_1', TechnologyId.storage),
      );

      expect(result.state, state);
    });

    test('rejects technology blocked by another unlocked technology', () {
      final reducer = GameStateReducer(
        mapData: MapData(cols: 1, rows: 1, tiles: const []),
        ruleset: GameRuleset(
          city: GameRuleset.defaults.city,
          technology: _rulesetWithTradeBlockedByMining(),
        ),
      );
      final state = GameState(
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {
                TechnologyId.agriculture,
                TechnologyId.mining,
              },
            ),
          },
        ),
      );

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_1', TechnologyId.trade),
      );

      expect(result.state, state);
    });

    test('rejects technology that is already unlocked', () {
      final state = GameState(
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
            ),
          },
        ),
      );

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
      );

      expect(result.state, state);
    });

    test('accepts actor context for the controlled player', () {
      const state = GameState(activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_2', TechnologyId.mining),
        context: const GameCommandContext(actorPlayerId: 'player_2'),
      );

      expect(
        result.state.research.forPlayer('player_2').activeTechnologyId,
        TechnologyId.mining,
      );
    });

    test('rejects actor context for a different player', () {
      const state = GameState(activePlayerId: 'player_1');

      final result = reducer.reduce(
        state,
        const SelectTechnologyCommand('player_2', TechnologyId.mining),
        context: const GameCommandContext(actorPlayerId: 'player_3'),
      );

      expect(result.state, state);
    });
  });
}

TechnologyRuleset _rulesetWithTradeBlockedByMining() {
  return TechnologyRuleset(
    science: TechnologyRulesets.standard.science,
    costs: TechnologyRulesets.standard.costs,
    technologies: {
      TechnologyId.agriculture: TechnologyRulesets.standard.definitionFor(
        TechnologyId.agriculture,
      ),
      TechnologyId.mining: TechnologyRulesets.standard.definitionFor(
        TechnologyId.mining,
      ),
      TechnologyId.trade: const TechnologyDefinition(
        id: TechnologyId.trade,
        name: 'Trade',
        description: 'Blocked test trade.',
        era: TechnologyEra.settlement,
        baseCost: 7,
        prerequisites: [TechnologyId.agriculture],
        blockedBy: [TechnologyId.mining],
        treePosition: TechnologyTreePosition(column: 1, row: 1),
      ),
    },
  );
}
