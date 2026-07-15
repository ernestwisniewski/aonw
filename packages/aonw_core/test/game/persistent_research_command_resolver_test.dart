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
          mapObjectiveHoldStatesByObjectiveId: _mapObjectiveHoldStates,
          resourceTradeAgreements: _resourceTradeAgreements,
        ),
      );

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand('player_1', TechnologyId.mining),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState.pendingAction, isNull);
      _expectPersistentRuntimeSlices(result.state.runtimeState);
    });

    test('uses WorldMap resources when applying overflow to a technology', () {
      final state = PersistentGameState(
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'City',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        research: ResearchState(
          players: {'player_1': PlayerResearchState(scienceOverflow: 4)},
        ),
      );

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: state,
        command: const SelectTechnologyCommand(
          'player_1',
          TechnologyId.agriculture,
        ),
        actorPlayerId: 'player_1',
        mapTiles: _mapTilesWithWheat(),
      );

      final research = result.state.research.forPlayer('player_1');
      expect(result.accepted, isTrue);
      expect(research.activeTechnologyId, TechnologyId.agriculture);
      expect(research.progressFor(TechnologyId.agriculture), 2);
      expect(research.scienceOverflow, 0);
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

void _expectPersistentRuntimeSlices(GameRuntimeState runtimeState) {
  expect(
    runtimeState.mapObjectiveHoldStatesByObjectiveId,
    _mapObjectiveHoldStates,
  );
  expect(runtimeState.resourceTradeAgreements, _resourceTradeAgreements);
}

const _mapObjectiveHoldStates = <String, MapObjectiveHoldState>{
  'objective_1': MapObjectiveHoldState(
    objectiveId: 'objective_1',
    playerId: 'player_1',
    holdTurns: 2,
  ),
};

const _resourceTradeAgreements = <ResourceTradeAgreement>[
  ResourceTradeAgreement(
    id: 'trade_1',
    exporterPlayerId: 'player_2',
    importerPlayerId: 'player_1',
    resource: ResourceType.horses,
    goldPerTurn: 2,
    remainingTurns: 3,
  ),
];

MapTileLookup _mapTilesWithWheat() => WorldMapReadView(
  WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: col == 1 && row == 1
                ? const [ResourceType.wheat]
                : const [],
            height: 0,
          ),
    ],
  ),
);
