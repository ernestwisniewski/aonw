import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/turn_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

void main() {
  group('TurnReducer', () {
    late MapData mapData;

    setUp(() {
      mapData = _map(5, 5);
    });

    test('advanceCitiesForPlayer processes city turns', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [
          CityHex(col: 2, row: 2),
          CityHex(col: 1, row: 2),
          CityHex(col: 3, row: 2),
          CityHex(col: 2, row: 1),
          CityHex(col: 2, row: 3),
          CityHex(col: 1, row: 1),
          CityHex(col: 3, row: 1),
        ],
        population: 1,
      );
      const state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
      );

      // CityTurnProcessor should have processed the city
      expect(result.state.cities, isNotEmpty);
    });

    test('advanceCitiesForPlayer advances active research', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        population: 1,
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final result = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
      );

      expect(
        result.state.research
            .forPlayer('player_1')
            .progressFor(TechnologyId.agriculture),
        2,
      );
    });

    test('advanceCitiesForPlayer adds units when a city produces one', () {
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
        population: 1,
        productionQueue: CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 0,
        ),
      );
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
        cityRuleset: cityRuleset,
      );

      expect(result.state.units, hasLength(1));
      expect(result.state.units.single.type, GameUnitType.warrior);
    });

    test('advanceCitiesForPlayer completes active research', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        population: 1,
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
              progressByTechnologyId: {TechnologyId.agriculture: 7},
            ),
          },
        ),
      );

      final result = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
      );

      final playerResearch = result.state.research.forPlayer('player_1');
      expect(playerResearch.hasUnlocked(TechnologyId.agriculture), isTrue);
      expect(playerResearch.activeTechnologyId, isNull);
    });

    test('advanceCitiesForPlayer does not process other player cities', () {
      const city = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Other City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        population: 1,
      );
      const state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
      );

      // No cities for player_1 — city/unit/field data unchanged, but TurnEndedEvent
      // is still emitted and fog is always recomputed.
      expect(result.state.cities, equals(state.cities));
      expect(result.state.units, equals(state.units));
    });

    test('FocusNextPendingActionCommand finds unit with MP', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 2,
        row: 2,
      );
      final state = GameState(units: [commander], activePlayerId: 'player_1');

      final result = TurnReducer.focusNextPendingAction(
        state,
        'player_1',
        mapData,
      );

      expect(result.state.selection?.unit?.id, commander.id);
      expect(result.state.moveCommandActive, isTrue);
      expect(result.uiEffects.whereType<JumpCameraEffect>().single.col, 2);
      expect(result.uiEffects.whereType<JumpCameraEffect>().single.row, 2);
    });

    test(
      'focusNextPendingAction prioritizes combat units that can see an enemy',
      () {
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 1,
        );
        final patrol = GameUnit.produced(
          id: 'warrior_patrol',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        );
        final engaged = GameUnit.produced(
          id: 'warrior_engaged',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 4,
          row: 3,
        );
        final enemy = GameUnit.produced(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 4,
          row: 4,
        );
        final state = GameState(
          units: [worker, patrol, engaged, enemy],
          activePlayerId: 'player_1',
        );

        final result = TurnReducer.focusNextPendingAction(
          state,
          'player_1',
          mapData,
        );

        expect(result.state.selection?.unit?.id, engaged.id);
        expect(result.uiEffects.whereType<JumpCameraEffect>().single.col, 4);
        expect(result.uiEffects.whereType<JumpCameraEffect>().single.row, 3);
      },
    );

    test(
      'focusNextPendingAction follows improve-field advice before normal combat order',
      () {
        final warrior = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        );
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 2,
          row: 2,
        );
        final state = GameState(
          units: [warrior, worker],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(
            warrior,
            tile: mapData.tileAt(warrior.col, warrior.row),
          ),
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final result = TurnReducer.focusNextPendingAction(
          state,
          'player_1',
          mapData,
          preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
        );

        expect(result.state.selection?.unit?.id, worker.id);
        final jump = result.uiEffects.whereType<JumpCameraEffect>().single;
        expect(jump.col, worker.col);
        expect(jump.row, worker.row);
      },
    );

    test(
      'focusNextPendingAction follows production advice before loose unit orders',
      () {
        final warrior = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          controlledHexes: [CityHex(col: 2, row: 2)],
          productionQueue: null,
        );
        final state = GameState(
          units: [warrior],
          cities: [city],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final result = TurnReducer.focusNextPendingAction(
          state,
          'player_1',
          mapData,
          preferredObjectiveAdvice: GameObjectiveAdvice.constructBuilding,
        );

        expect(result.state.selection?.city?.id, city.id);
        final jump = result.uiEffects.whereType<JumpCameraEffect>().single;
        expect(jump.col, city.center.col);
        expect(jump.row, city.center.row);
      },
    );

    test(
      'focusNextPendingAction cycles after current action matches advice',
      () {
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 1,
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          controlledHexes: [CityHex(col: 2, row: 2)],
          productionQueue: null,
        );
        final state = GameState(
          units: [worker],
          cities: [city],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(
            worker,
            tile: mapData.tileAt(worker.col, worker.row),
          ),
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final result = TurnReducer.focusNextPendingAction(
          state,
          'player_1',
          mapData,
          preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
        );

        expect(result.state.selection?.city?.id, city.id);
      },
    );

    test('focusNextPendingAction skips unit with zero MP', () {
      final commander = GameUnit(
        id: 'commander_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        name: GameUnitType.commander.defaultNameToken,
        col: 2,
        row: 2,
        movementPoints: 0,
      );
      final state = GameState(
        units: [commander],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final result = TurnReducer.focusNextPendingAction(
        state,
        'player_1',
        mapData,
      );

      // No city without production queue either — unchanged
      expect(result.state, same(state));
    });

    test(
      'focusNextPendingAction falls back to city without production queue',
      () {
        // Commander with 0 MP — skipped
        final commander = GameUnit(
          id: 'commander_player_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.commander,
          name: GameUnitType.commander.defaultNameToken,
          col: 0,
          row: 0,
          movementPoints: 0,
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 2, row: 2),
          controlledHexes: [CityHex(col: 2, row: 2)],
          population: 1,
          productionQueue: null, // no queue
        );
        final state = GameState(
          units: [commander],
          cities: [city],
          activePlayerId: 'player_1',
        );

        final result = TurnReducer.focusNextPendingAction(
          state,
          'player_1',
          mapData,
        );

        expect(result.state.selection?.city?.id, city.id);
        expect(result.uiEffects.whereType<JumpCameraEffect>().single.col, 2);
      },
    );

    test('focusNextPendingAction falls back to research selection', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        population: 1,
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final state = GameState(cities: [city], activePlayerId: 'player_1');

      final result = TurnReducer.focusNextPendingAction(
        state,
        'player_1',
        mapData,
      );

      expect(
        result.state.pendingAction,
        const PendingResearchSelection(ownerPlayerId: 'player_1'),
      );
      expect(result.uiEffects, isEmpty);
    });

    test('focusNextPendingAction cycles through turn actions', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        productionQueue: null,
      );
      final state = GameState(
        units: [unit],
        cities: [city],
        activePlayerId: 'player_1',
      );

      final first = TurnReducer.focusNextPendingAction(
        state,
        'player_1',
        mapData,
      );
      final second = TurnReducer.focusNextPendingAction(
        first.state,
        'player_1',
        mapData,
      );
      final third = TurnReducer.focusNextPendingAction(
        second.state,
        'player_1',
        mapData,
      );
      final fourth = TurnReducer.focusNextPendingAction(
        third.state,
        'player_1',
        mapData,
      );

      expect(first.state.selection?.unit?.id, unit.id);
      expect(second.state.selection?.city?.id, city.id);
      expect(
        third.state.pendingAction,
        const PendingResearchSelection(ownerPlayerId: 'player_1'),
      );
      expect(fourth.state.selection?.unit?.id, unit.id);
    });

    test('focusTurnStartAction always starts from first ranked action', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        productionQueue: null,
      );
      final state = GameState(
        units: [unit],
        cities: [city],
        activePlayerId: 'player_1',
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0xFF4a7fc4,
        ),
      );

      final result = TurnReducer.focusTurnStartAction(
        state,
        'player_1',
        mapData,
      );

      expect(result.state.selection?.unit?.id, unit.id);
      expect(result.state.moveCommandActive, isTrue);
      final jump = result.uiEffects.whereType<JumpCameraEffect>().single;
      expect(jump.col, 1);
      expect(jump.row, 1);
    });

    test(
      'focusTurnStartAction emits production bubbles without focusing active city queues',
      () {
        final cityRuleset = CityRulesets.standard.copyWith(
          units: {
            ...CityRulesets.standard.units,
            GameUnitType.worker: const UnitProductionDefinition(
              type: GameUnitType.worker,
              productionCost: 5,
            ),
          },
        );
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 1, row: 1),
          population: 1,
          productionQueue: CityProductionQueue.unit(
            unitType: GameUnitType.worker,
            investedProduction: 1,
          ),
        );
        final state = GameState(
          cities: [city],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final result = TurnReducer.focusTurnStartAction(
          state,
          'player_1',
          mapData,
          cityRuleset: cityRuleset,
        );

        expect(result.state, state);
        expect(result.uiEffects.whereType<JumpCameraEffect>(), isEmpty);
        final effect = result.uiEffects
            .whereType<ShowCityProductionBubbleEffect>()
            .single;
        expect(effect.target, const UnitProductionTarget(GameUnitType.worker));
        expect(effect.col, 1);
        expect(effect.row, 1);
        expect(effect.turnsRemaining, 6);
        expect(effect.delay, const Duration(milliseconds: 120));
      },
    );

    test(
      'focusTurnStartAction keeps exhausted selected unit when only city queues report progress',
      () {
        final unit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        ).copyWith(movementPoints: 0);
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 3, row: 3),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
        );
        final state = GameState(
          units: [unit],
          cities: [city],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(
            unit,
            tile: mapData.tileAt(unit.col, unit.row),
          ),
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final result = TurnReducer.focusTurnStartAction(
          state,
          'player_1',
          mapData,
        );

        expect(result.state.selection?.unit?.id, unit.id);
        expect(result.uiEffects.whereType<JumpCameraEffect>(), isEmpty);
        expect(
          result.uiEffects.whereType<ShowCityProductionBubbleEffect>(),
          hasLength(1),
        );
      },
    );

    test(
      'focusTurnStartAction keeps camera focus before production bubble',
      () {
        final unit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 3, row: 3),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
        );
        final state = GameState(
          units: [unit],
          cities: [city],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final result = TurnReducer.focusTurnStartAction(
          state,
          'player_1',
          mapData,
        );

        expect(result.uiEffects[0], isA<JumpCameraEffect>());
        expect(result.uiEffects[1], isA<ShowCityProductionBubbleEffect>());
      },
    );

    test(
      'focusTurnStartAction keeps research pending without jumping to production city',
      () {
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 3, row: 3),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
        );
        final state = GameState(cities: [city], activePlayerId: 'player_1');

        final result = TurnReducer.focusTurnStartAction(
          state,
          'player_1',
          mapData,
        );

        expect(
          result.state.pendingAction,
          const PendingResearchSelection(ownerPlayerId: 'player_1'),
        );
        expect(result.uiEffects.whereType<JumpCameraEffect>(), isEmpty);
        expect(
          result.uiEffects.whereType<ShowCityProductionBubbleEffect>(),
          hasLength(1),
        );
      },
    );

    test('pendingTurnActionCount matches cycle actions', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        productionQueue: null,
      );
      final state = GameState(
        units: [unit],
        cities: [city],
        activePlayerId: 'player_1',
      );

      expect(TurnReducer.pendingTurnActionCount(state, 'player_1', mapData), 3);
    });

    test('merchant with assigned trade route is not a pending unit action', () {
      final merchant =
          GameUnit.produced(
            id: 'merchant_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            col: 1,
            row: 1,
          ).copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_1',
              destinationCityId: 'city_2',
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 1,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 1,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
        productionQueue: null,
      );
      final state = GameState(
        units: [merchant],
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final targets = TurnReducer.pendingTurnActionTargets(
        state,
        'player_1',
        mapData,
      );

      expect(targets.whereType<UnitTurnActionTarget>(), isEmpty);
      expect(targets, hasLength(1));
      expect(targets.single, isA<CityProductionTurnActionTarget>());
    });

    test(
      'focusNextPendingAction includes each available unit in the cycle',
      () {
        final firstUnit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        final secondUnit = GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 2,
        );
        final state = GameState(
          units: [firstUnit, secondUnit],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        );

        final first = TurnReducer.focusNextPendingAction(
          state,
          'player_1',
          mapData,
        );
        final second = TurnReducer.focusNextPendingAction(
          first.state,
          'player_1',
          mapData,
        );

        expect(first.state.selection?.unit?.id, firstUnit.id);
        expect(second.state.selection?.unit?.id, secondUnit.id);
      },
    );

    test('focusNextPendingAction is unchanged when research is active', () {
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        population: 1,
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          },
        ),
      );

      final result = TurnReducer.focusNextPendingAction(
        state,
        'player_1',
        mapData,
      );

      expect(result.state, state);
      expect(result.uiEffects, isEmpty);
    });
  });
}
