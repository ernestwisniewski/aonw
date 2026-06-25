import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentResearchCommandResolver', () {
    test('selects an available technology for actor player', () {
      const state = PersistentGameState();

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand(
          'player_1',
          TechnologyId.agriculture,
        ),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.research.forPlayer('player_1').activeTechnologyId,
        TechnologyId.agriculture,
      );
    });

    test('clears matching research pending action', () {
      const state = PersistentGameState(
        runtimeState: GameRuntimeState(
          pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
        ),
      );

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand('player_1', TechnologyId.mining),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState.pendingAction, isNull);
    });

    test('rejects missing prerequisites', () {
      const state = PersistentGameState();

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand(
          'player_1',
          TechnologyId.storage,
        ),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'technology_not_available');
      expect(result.state, state);
    });

    test('rejects technology blocked by another unlocked technology', () {
      final state = PersistentGameState(
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

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand('player_1', TechnologyId.trade),
        actorPlayerId: 'player_1',
        ruleset: _rulesetWithTradeBlockedByMining(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'technology_not_available');
      expect(result.state, state);
    });

    test('rejects another player selection', () {
      const state = PersistentGameState();

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand(
          'player_2',
          TechnologyId.agriculture,
        ),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'technology_player_not_controlled');
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
