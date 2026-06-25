import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

TurnContext _context({
  required GameState state,
  MapData? mapData,
  GameRuleset ruleset = GameRuleset.defaults,
  String playerId = 'player_1',
  List<GameEvent> events = const [],
}) {
  return TurnContext(
    state: state,
    mapData: mapData ?? _map(5, 5),
    ruleset: ruleset,
    playerId: playerId,
    events: events,
  );
}

void main() {
  group('turn processing phases', () {
    test('CityProcessingPhase produces units and emits city events', () {
      final cityRuleset = CityRulesets.standard.copyWith(
        units: {
          ...CityRulesets.standard.units,
          GameUnitType.warrior: const UnitProductionDefinition(
            type: GameUnitType.warrior,
            productionCost: 1,
          ),
        },
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [CityHex(col: 1, row: 2)],
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 0,
        ),
      );

      final next = const CityProcessingPhase().apply(
        _context(
          state: GameState(cities: [city]),
          ruleset: GameRuleset(
            city: cityRuleset,
            technology: TechnologyRulesets.standard,
          ),
        ),
      );

      expect(next.state.units, hasLength(1));
      expect(next.state.units.single.type, GameUnitType.warrior);
      expect(next.events.single, isA<CityProducedUnitEvent>());
    });

    test('CityProcessingPhase adds city gold to player treasury', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        buildings: {CityBuildingType.merchantHall},
      );

      final next = const CityProcessingPhase().apply(
        _context(
          state: const GameState(cities: [city], playerGold: {'player_1': 3}),
        ),
      );

      expect(next.state.playerGold['player_1'], 5);
    });

    test('CityProcessingPhase converts wealth project into gold', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );

      final next = const CityProcessingPhase().apply(
        _context(
          state: GameState(cities: [city], playerGold: const {'player_1': 3}),
        ),
      );

      expect(next.state.playerGold['player_1'], 4);
      expect(
        next.state.cities.single.productionQueue,
        CityProductionQueue.project(projectType: CityProjectType.wealth),
      );
    });

    test('CityProcessingPhase subtracts unit upkeep from city gold', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        buildings: {CityBuildingType.merchantHall},
      );
      final units = [
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: GameUnitType.settler.defaultNameToken,
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 0,
          row: 1,
        ),
        GameUnit(
          id: 'archer_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.archer,
          name: GameUnitType.archer.defaultNameToken,
          col: 0,
          row: 2,
        ),
        GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 1,
          row: 0,
        ),
        GameUnit(
          id: 'worker_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 1,
          row: 1,
        ),
      ];

      final next = const CityProcessingPhase().apply(
        _context(
          state: GameState(
            cities: const [city],
            units: units,
            playerGold: const {'player_1': 3},
          ),
        ),
      );

      expect(next.state.playerGold['player_1'], 4);
    });

    test('CityProcessingPhase slowly regenerates damaged city HP', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        hitPoints: 10,
      );

      final next = const CityProcessingPhase().apply(
        _context(state: const GameState(cities: [city])),
      );

      expect(next.state.cities.single.hitPoints, 11);
    });

    test('CityProcessingPhase clears stored city HP at full health', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        hitPoints: 15,
      );

      final next = const CityProcessingPhase().apply(
        _context(state: const GameState(cities: [city])),
      );

      expect(next.state.cities.single.hitPoints, isNull);
    });

    test(
      'CityProcessingPhase skips HP recovery for a city attacked this turn',
      () {
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          hitPoints: 10,
        );

        final next = const CityProcessingPhase().apply(
          _context(
            state: const GameState(cities: [city]),
            events: [
              CombatResolvedEvent(
                attackerUnitId: 'attacker_1',
                defenderUnitId: 'city_1',
                outcome: CombatOutcome(
                  attackerUnitId: 'attacker_1',
                  defenderUnitId: 'city_1',
                  attackerHpAfter: 8,
                  defenderHpAfter: 10,
                  attackerKilled: false,
                  defenderKilled: false,
                ),
              ),
            ],
          ),
        );

        expect(next.state.cities.single.hitPoints, 10);
      },
    );

    test(
      'ResearchProcessingPhase advances active research and emits events',
      () {
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          population: 1,
        );
        final state = GameState(
          cities: [city],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final next = const ResearchProcessingPhase().apply(
          _context(state: state),
        );

        expect(
          next.state.research
              .forPlayer('player_1')
              .progressFor(TechnologyId.agriculture),
          2,
        );
        expect(next.events, contains(isA<ResearchPointsGainedEvent>()));
      },
    );

    test('research project bonus flows from city processing into research', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        population: 1,
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.research,
        ),
      );
      final state = GameState(
        cities: [city],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final afterCities = const CityProcessingPhase().apply(
        _context(state: state),
      );
      final afterResearch = const ResearchProcessingPhase().apply(afterCities);

      expect(afterCities.bonusScience.total, 1);
      expect(
        afterResearch.state.research
            .forPlayer('player_1')
            .progressFor(TechnologyId.agriculture),
        3,
      );
      expect(afterResearch.bonusScience, ScienceYieldBreakdown.empty);
    });

    test(
      'CombatResolutionPhase resolves intended attacks and clears ledger',
      () {
        final attacker = GameUnit(
          id: 'attacker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 0,
          row: 0,
        );
        final defender = GameUnit(
          id: 'defender_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 1,
          row: 0,
        );
        final state = GameState(
          units: [attacker, defender],
          intendedAttacks: const [
            IntendedAttack(
              attackerUnitId: 'attacker_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 4,
              declaringPlayerId: 'player_1',
            ),
          ],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  const HexCoordinate(col: 0, row: 0),
                  const HexCoordinate(col: 1, row: 0),
                },
              ),
            },
          ),
        );

        final next = const CombatResolutionPhase().apply(
          _context(
            state: state,
            mapData: _map(3, 3),
            ruleset: const GameRuleset(
              city: CityRulesets.standard,
              combat: CombatRuleset(
                resolutionMode: CombatResolutionMode.simultaneous,
                varianceRange: 0,
              ),
              technology: TechnologyRulesets.standard,
            ),
          ).copyWith(save: _save(playerStates: const {})),
        );

        expect(next.state.intendedAttacks, isEmpty);
        expect(
          next.state.units.singleWhere((u) => u.id == 'attacker_1').hitPoints,
          9,
        );
        expect(
          next.state.units.singleWhere((u) => u.id == 'defender_1').hitPoints,
          9,
        );
        expect(
          next.state.diplomacy.statusBetween('player_1', 'player_2'),
          DiplomaticRelationStatus.hostile,
        );
        expect(next.events.whereType<UnitAttackedEvent>(), hasLength(1));
        expect(next.events.whereType<CombatResolvedEvent>(), hasLength(1));
        expect(
          next.uiEffects.whereType<PlayCombatAnimationEffect>(),
          hasLength(1),
        );
      },
    );

    test('WorkerProcessingPhase completes worker jobs and emits events', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 2,
        row: 2,
        workerBuildCharges: 2,
        workerJob: const WorkerJob(
          targetHex: CityHex(col: 2, row: 2),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 1,
          totalTurns: 1,
        ),
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 2, row: 2)],
      );

      final next = const WorkerProcessingPhase().apply(
        _context(
          state: GameState(units: [worker], cities: [city]),
        ),
      );

      expect(next.state.units.single.workerJob, isNull);
      expect(next.state.fieldImprovements, hasLength(1));
      expect(next.events.single, isA<WorkerCompletedJobEvent>());
    });

    test('CityFoundingProcessingPhase completes settler founding jobs', () {
      final settler =
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 2,
            row: 2,
          ).copyWithCityFoundingJob(
            CityFoundingJob(
              center: const CityHex(col: 2, row: 2),
              controlledHexes: const [
                CityHex(col: 2, row: 1),
                CityHex(col: 3, row: 2),
              ],
              remainingTurns: 1,
              totalTurns: 1,
            ),
          );

      final next = const CityFoundingProcessingPhase().apply(
        _context(
          state: GameState(units: [settler]),
          mapData: _map(5, 5),
        ),
      );

      expect(next.state.units, isEmpty);
      expect(next.state.cities, hasLength(1));
      expect(next.state.cities.single.center, const CityHex(col: 2, row: 2));
      expect(next.events.single, isA<CityFoundedEvent>());
    });

    test('FogRecomputePhase recomputes visibility', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
      );

      final next = const FogRecomputePhase().apply(
        _context(state: const GameState(cities: [city])),
      );

      expect(
        next.state.fogOfWar.isVisible(
          'player_1',
          const HexCoordinate(col: 2, row: 2),
        ),
        isTrue,
      );
    });

    test('SelectionRefreshPhase refreshes selected unit snapshot', () {
      final previousUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final updatedUnit = previousUnit.copyWith(col: 2, row: 2);
      final state = GameState(
        units: [updatedUnit],
        selection: GameSelection.unit(previousUnit),
      );

      final next = const SelectionRefreshPhase().apply(_context(state: state));

      expect(next.state.selection?.unit?.col, 2);
      expect(next.state.selection?.unit?.row, 2);
      expect(next.state.selection?.tile?.col, 2);
      expect(next.state.selection?.tile?.row, 2);
    });

    test('AdvanceTurnPhase marks a player finished on the save snapshot', () {
      final savedAt = DateTime.utc(2026, 4, 24, 12);
      final save = _save(
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );

      final next = const AdvanceTurnPhase().apply(
        _context(
          state: const GameState(),
          playerId: 'player_1',
        ).copyWith(save: save, savedAt: savedAt),
      );

      expect(next.save?.turn, 1);
      expect(next.save?.playerStates['player_1'], PlayerTurnState.finished);
      expect(next.save?.playerStates['player_2'], PlayerTurnState.active);
      expect(next.save?.savedAt, savedAt);
    });

    test(
      'AdvanceTurnPhase starts a new turn when all players are finished',
      () {
        final save = _save(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );

        final next = const AdvanceTurnPhase().advanceSave(
          save,
          playerId: 'player_2',
          savedAt: DateTime.utc(2026, 4, 24, 13),
        );

        expect(next.turn, 2);
        expect(next.playerStates.values, everyElement(PlayerTurnState.active));
      },
    );
  });
}

GameSave _save({required Map<String, PlayerTurnState> playerStates}) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
      Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050),
    ],
  );
}
