import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  group('TracingMctsSimulator sequential city economy parity', () {
    test('carries excavation artifacts and snapshot into the next command', () {
      final state = DomainState.snapshot(
        units: [_scout('scout_1'), _scout('scout_2')],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.map(col: 1, row: 0),
          ),
        ],
        fogOfWar: _visibleFog(),
      );
      const commands = <DomainCommand>[
        StartArtifactExcavationCommand('scout_1'),
        StartArtifactExcavationCommand('scout_2'),
      ];

      final canonical = _resolveEngineSequence(state, commands);
      final simulated = _simulateCommands(state, commands);

      expect(canonical.accepted, [true, false]);
      expect(_unit(simulated, 'scout_1').excavatingArtifactId, 'artifact_1');
      expect(_unit(simulated, 'scout_2').excavatingArtifactId, isNull);
      expect(simulated.view.artifacts, canonical.state.artifacts);
      expect(simulated.view.engineSnapshot, canonical.snapshot);
    });

    test('carries resource trade agreement into duplicate validation', () {
      final mapData = _resourceTradeMapData();
      final state = DomainState.snapshot(
        playerGold: const {'player_1': 8},
        cities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Exporter',
            center: CityHex(col: 2, row: 0),
          ),
        ],
        fogOfWar: _visibleFog(),
        research: _researchWithMany({
          'player_2': {TechnologyId.animalHusbandry},
        }),
      );
      const commands = <DomainCommand>[
        OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
          agreementId: 'trade_1',
        ),
        OpenResourceTradeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
          agreementId: 'trade_2',
        ),
      ];

      final canonical = _resolveEngineSequence(
        state,
        commands,
        mapData: mapData,
      );
      final simulated = _simulateCommands(state, commands, mapData: mapData);

      expect(canonical.accepted, [true, false]);
      expect(
        simulated.view.resourceTradeAgreements,
        canonical.state.resourceTradeAgreements,
      );
      expect(simulated.view.resourceTradeAgreements, hasLength(1));
      expect(simulated.view.engineSnapshot, canonical.snapshot);
    });

    test('carries rushed wonder registry and gold into the next command', () {
      final wonderCost = CityProductionRules.wonderProductionCost(
        WonderType.greatLibrary,
      );
      final state = DomainState.snapshot(
        playerGold: const {'player_1': 10},
        cities: [
          _city(
            id: 'city_1',
            productionQueue: CityProductionQueue.wonder(
              wonderType: WonderType.greatLibrary,
              investedProduction: wonderCost - 1,
            ),
          ),
          _city(id: 'city_2', col: 2),
        ],
        fogOfWar: _visibleFog(),
        research: _researchWithMany({
          'player_1': {TechnologyId.writing},
        }),
      );
      const commands = <DomainCommand>[
        RushProductionCommand('city_1'),
        StartWonderCommand('city_2', WonderType.greatLibrary),
      ];

      final canonical = _resolveEngineSequence(state, commands);
      final simulated = _simulateCommands(state, commands);

      expect(canonical.accepted, [true, false]);
      expect(simulated.view.ownGold, canonical.state.playerGold['player_1']);
      expect(simulated.view.ownGold, 8);
      expect(simulated.view.wonderRegistry, canonical.state.wonderRegistry);
      expect(
        simulated.view.wonderRegistry.ownerOf(WonderType.greatLibrary),
        'player_1',
      );
      expect(simulated.view.engineSnapshot, canonical.snapshot);
    });
  });
}

SimulatedState _simulateCommands(
  DomainState initialState,
  List<DomainCommand> commands, {
  WorldMap? mapData,
}) {
  final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
  final engineSnapshot = MctsSimulatorParityFixtures.engineSnapshot(
    initialState,
  );
  var simulated = SimulatedState.fromView(
    GameView.fromDomainState(
      engineSnapshot.domain,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: actualMapData,
      ruleset: GameRuleset.defaults,
      engineSnapshot: engineSnapshot,
    ),
    maxPlanningDepth: commands.length + 1,
  );
  for (final command in commands) {
    simulated = const TracingMctsSimulator().applyAction(
      simulated,
      CommandMctsAction(command),
    );
  }
  return simulated;
}

({DomainState state, CanonicalGameSnapshot snapshot, List<bool> accepted})
_resolveEngineSequence(
  DomainState initialState,
  List<DomainCommand> commands, {
  WorldMap? mapData,
}) {
  final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
  var snapshot = MctsSimulatorParityFixtures.engineSnapshot(initialState);
  var state = snapshot.domain;
  final accepted = <bool>[];
  for (var index = 0; index < commands.length; index++) {
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: snapshot,
      state: state,
      command: commands[index],
      actorPlayerId: 'player_1',
      commandTick: index + 1,
      mapView: actualMapData,
      ruleset: GameRuleset.defaults,
    );
    accepted.add(result.accepted);
    state = result.state;
    snapshot = result.snapshot;
  }
  return (state: state, snapshot: snapshot, accepted: accepted);
}

GameUnit _unit(SimulatedState state, String id) {
  return state.ownUnits.singleWhere((unit) => unit.id == id);
}

GameCity _city({
  required String id,
  int col = 1,
  CityProductionQueue? productionQueue,
}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: col, row: 0),
    productionQueue: productionQueue,
  );
}

GameUnit _scout(String id) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    col: 1,
    row: 0,
  );
}

ResearchState _researchWithMany(
  Map<String, Set<TechnologyId>> technologiesByPlayerId,
) {
  return ResearchState(
    players: {
      for (final entry in technologiesByPlayerId.entries)
        entry.key: PlayerResearchState(unlockedTechnologyIds: entry.value),
    },
  );
}

FogOfWarState _visibleFog() {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
        },
      ),
    },
  );
}

WorldMap _resourceTradeMapData() {
  return WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 2,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [ResourceType.horses],
        height: 0,
      ),
    ],
  );
}
