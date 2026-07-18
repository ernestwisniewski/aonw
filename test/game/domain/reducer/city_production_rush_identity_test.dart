import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

part 'city_production_rush_identity_test_support.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  final rejectionCases =
      <
        ({
          String name,
          String commandCityId,
          CityProductionQueue? queue,
          int gold,
          GameCommandContext context,
        })
      >[
        (
          name: 'missing city',
          commandCityId: 'missing_city',
          queue: _buildingQueue(),
          gold: 100,
          context: const GameCommandContext(),
        ),
        (
          name: 'foreign actor',
          commandCityId: 'city_1',
          queue: _buildingQueue(),
          gold: 100,
          context: const GameCommandContext(actorPlayerId: _otherPlayerId),
        ),
        (
          name: 'empty queue',
          commandCityId: 'city_1',
          queue: null,
          gold: 100,
          context: const GameCommandContext(),
        ),
        (
          name: 'unrushable project',
          commandCityId: 'city_1',
          queue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
          gold: 100,
          context: const GameCommandContext(),
        ),
        (
          name: 'insufficient treasury',
          commandCityId: 'city_1',
          queue: _buildingQueue(),
          gold: 1,
          context: const GameCommandContext(),
        ),
        (
          name: 'already complete queue',
          commandCityId: 'city_1',
          queue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: CityProductionRules.buildingProductionCost(
              CityBuildingType.granary,
            ),
          ),
          gold: 100,
          context: const GameCommandContext(),
        ),
      ];

  for (final rejectionCase in rejectionCases) {
    test(
      '${rejectionCase.name} rejection keeps full state and interaction identity',
      () {
        final mapView = _mapView();
        final city = _city(productionQueue: rejectionCase.queue);
        final state = _stateWithSelection(
          cities: [city],
          selectedCityId: city.id,
          mapTiles: mapView,
          gold: rejectionCase.gold,
        );

        final result = _rush(
          state,
          rejectionCase.commandCityId,
          mapView,
          context: rejectionCase.context,
        );

        _expectRejectedIdentity(result, state);
      },
    );
  }

  test(
    'accepted partial rush refreshes matching selection and shares other state',
    () {
      final mapView = _mapView();
      final queue = _buildingQueue();
      final targetCity = _city(productionQueue: queue);
      final unrelatedCity = _city(
        id: 'unrelated_city',
        ownerPlayerId: _otherPlayerId,
        center: const CityHex(col: 2, row: 2),
      );
      final state = _stateWithSelection(
        cities: [targetCity, unrelatedCity],
        selectedCityId: targetCity.id,
        mapTiles: mapView,
      );
      final interaction = state.interaction;
      final selection = state.selection;

      final result = _rush(state, targetCity.id, mapView);
      final updatedCity = result.state.cities.first;
      final updatedQueue = updatedCity.productionQueue!;

      expect(result.events, isEmpty);
      expect(result.state, isNot(same(state)));
      expect(result.state.cities, isNot(same(state.cities)));
      expect(updatedCity, isNot(same(targetCity)));
      expect(updatedQueue, isNot(same(queue)));
      expect(updatedQueue.target, queue.target);
      expect(updatedQueue.investedProduction, greaterThan(0));
      expect(
        updatedQueue.investedProduction,
        lessThan(CityProductionRules.targetCost(queue.target)),
      );
      expect(result.state.cities.last, same(unrelatedCity));
      expect(result.state.playerGold, isNot(same(state.playerGold)));
      expect(result.state.playerGold[_playerId], lessThan(100));
      expect(result.state.interaction, isNot(same(interaction)));
      expect(result.state.selection, isNot(same(selection)));
      expect(result.state.selection?.city, same(updatedCity));
      expect(result.state.moveCommandActive, isTrue);
      _expectSharedSlices(result.state, state);
    },
  );

  test('accepted rush preserves another city selection and interaction', () {
    final mapView = _mapView();
    final targetCity = _city(productionQueue: _buildingQueue());
    final selectedCity = _city(
      id: 'selected_city',
      center: const CityHex(col: 2, row: 2),
    );
    final state = _stateWithSelection(
      cities: [targetCity, selectedCity],
      selectedCityId: selectedCity.id,
      mapTiles: mapView,
    );
    final interaction = state.interaction;
    final selection = state.selection;
    final selectedCityInState = state.cities.last;

    final result = _rush(state, targetCity.id, mapView);

    expect(result.state, isNot(same(state)));
    expect(result.state.cities.first, isNot(same(targetCity)));
    expect(result.state.cities.last, same(selectedCityInState));
    expect(result.state.interaction, same(interaction));
    expect(result.state.selection, same(selection));
    expect(result.state.selection?.city, same(selectedCityInState));
  });

  test('building completion replaces only production-owned branches', () {
    final mapView = _mapView();
    final queue = CityProductionQueue.building(
      buildingType: CityBuildingType.granary,
      investedProduction:
          CityProductionRules.buildingProductionCost(CityBuildingType.granary) -
          1,
    );
    final targetCity = _city(productionQueue: queue);
    final unrelatedCity = _city(
      id: 'selected_city',
      center: const CityHex(col: 2, row: 2),
    );
    final state = _stateWithSelection(
      cities: [targetCity, unrelatedCity],
      selectedCityId: unrelatedCity.id,
      mapTiles: mapView,
    );

    final result = _rush(state, targetCity.id, mapView);
    final updatedCity = result.state.cities.first;
    final event = result.events.single as CityBuiltBuildingEvent;

    expect(updatedCity, isNot(same(targetCity)));
    expect(updatedCity.productionQueue, isNull);
    expect(updatedCity.buildings, contains(CityBuildingType.granary));
    expect(updatedCity.buildings, isNot(same(targetCity.buildings)));
    expect(result.state.cities.last, same(unrelatedCity));
    expect(result.state.units, same(state.units));
    expect(result.state.wonderRegistry, same(state.wonderRegistry));
    expect(result.state.interaction, same(state.interaction));
    expect(event.cityId, targetCity.id);
    expect(event.buildingType, CityBuildingType.granary);
    _expectSharedSlices(result.state, state);
  });

  test('unit completion appends a unit and shares existing entities', () {
    final mapView = _mapView();
    final queue = CityProductionQueue.unit(
      unitType: GameUnitType.warrior,
      investedProduction:
          CityProductionRules.unitProductionCost(GameUnitType.warrior) - 1,
    );
    final targetCity = _city(productionQueue: queue);
    final unrelatedCity = _city(
      id: 'selected_city',
      center: const CityHex(col: 2, row: 2),
    );
    final state = _stateWithSelection(
      cities: [targetCity, unrelatedCity],
      selectedCityId: unrelatedCity.id,
      mapTiles: mapView,
    );
    final existingUnit = state.units.single;

    final result = _rush(state, targetCity.id, mapView);
    final updatedCity = result.state.cities.first;
    final event = result.events.single as CityProducedUnitEvent;

    expect(updatedCity, isNot(same(targetCity)));
    expect(updatedCity.productionQueue, isNull);
    expect(result.state.cities.last, same(unrelatedCity));
    expect(result.state.units, isNot(same(state.units)));
    expect(result.state.units, hasLength(state.units.length + 1));
    expect(result.state.units.first, same(existingUnit));
    expect(result.state.units.last.id, event.producedUnitId);
    expect(result.state.units.last.type, GameUnitType.warrior);
    expect(result.state.wonderRegistry, same(state.wonderRegistry));
    expect(result.state.interaction, same(state.interaction));
    _expectSharedSlices(result.state, state, expectUnits: false);
  });

  test(
    'wonder completion updates only the registry and host city branches',
    () {
      final mapView = _mapView();
      final queue = CityProductionQueue.wonder(
        wonderType: WonderType.greatWall,
        investedProduction:
            CityProductionRules.wonderProductionCost(WonderType.greatWall) - 1,
      );
      final targetCity = _city(productionQueue: queue);
      final unrelatedCity = _city(
        id: 'selected_city',
        center: const CityHex(col: 2, row: 2),
      );
      final state = _stateWithSelection(
        cities: [targetCity, unrelatedCity],
        selectedCityId: unrelatedCity.id,
        mapTiles: mapView,
      );

      final result = _rush(state, targetCity.id, mapView);
      final updatedCity = result.state.cities.first;
      final event = result.events.single as CityBuiltWonderEvent;

      expect(updatedCity, isNot(same(targetCity)));
      expect(updatedCity.productionQueue, isNull);
      expect(updatedCity.wonders, contains(WonderType.greatWall));
      expect(updatedCity.wonders, isNot(same(targetCity.wonders)));
      expect(result.state.cities.last, same(unrelatedCity));
      expect(result.state.units, same(state.units));
      expect(result.state.research, same(state.research));
      expect(result.state.wonderRegistry, isNot(same(state.wonderRegistry)));
      expect(
        result.state.wonderRegistry.ownerOf(WonderType.greatWall),
        _playerId,
      );
      expect(result.state.interaction, same(state.interaction));
      expect(event.cityId, targetCity.id);
      expect(event.ownerPlayerId, _playerId);
      expect(event.wonderType, WonderType.greatWall);
      _expectSharedSlices(result.state, state, expectWonderRegistry: false);
    },
  );
}

CityProductionQueue _buildingQueue() {
  return CityProductionQueue.building(
    buildingType: CityBuildingType.workshop,
    investedProduction: 0,
  );
}

GameStateTransition _rush(
  GameState state,
  String cityId,
  MapTileLookup mapTiles, {
  GameCommandContext context = const GameCommandContext(),
}) {
  return CityProductionReducer.rushProduction(
    state,
    RushProductionCommand(cityId),
    mapTiles,
    context: context,
  );
}

void _expectRejectedIdentity(GameStateTransition result, GameState state) {
  final city = state.cities.single;
  final queue = city.productionQueue;
  expect(result.events, isEmpty);
  expect(result.state, same(state));
  expect(result.state.cities, same(state.cities));
  expect(result.state.cities.single, same(city));
  expect(result.state.cities.single.productionQueue, same(queue));
  expect(result.state.playerGold, same(state.playerGold));
  expect(result.state.units, same(state.units));
  expect(result.state.interaction, same(state.interaction));
  expect(result.state.selection, same(state.selection));
  expect(result.state.selection?.city, same(city));
}

GameState _stateWithSelection({
  required List<GameCity> cities,
  required String selectedCityId,
  required MapTileLookup mapTiles,
  int gold = 100,
}) {
  final state = GameState(
    playerColors: const {_playerId: 0xFF123456, _otherPlayerId: 0xFF654321},
    playerCountries: const {
      _playerId: PlayerCountry.poland,
      _otherPlayerId: PlayerCountry.netherlands,
    },
    playerGold: {_playerId: gold, _otherPlayerId: 23},
    playerWarWeariness: const {_playerId: 2, _otherPlayerId: 3},
    playerStabilityNet: const {_playerId: 4, _otherPlayerId: 5},
    units: [
      GameUnit.produced(
        id: 'unrelated_unit',
        ownerPlayerId: _otherPlayerId,
        type: GameUnitType.worker,
        col: 0,
        row: 0,
      ),
    ],
    cities: cities,
    artifacts: const [
      WorldArtifact(
        id: 'unrelated_artifact',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.map(col: 0, row: 2),
      ),
    ],
    fieldImprovements: const [
      FieldImprovement(
        hex: CityHex(col: 0, row: 2),
        type: FieldImprovementType.farm,
        builtByCityId: 'unrelated_city',
      ),
    ],
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'unrelated_unit',
        defenderCol: 2,
        defenderRow: 0,
        declaredAtTick: 7,
        declaringPlayerId: _otherPlayerId,
      ),
    ],
    resourceTradeAgreements: const [
      ResourceTradeAgreement(
        id: 'unrelated_trade',
        exporterPlayerId: _otherPlayerId,
        importerPlayerId: _playerId,
        resource: ResourceType.iron,
        goldPerTurn: 2,
        remainingTurns: 3,
      ),
    ],
    dominationHoldTurnsByPlayerId: const {_otherPlayerId: 4},
    culturalVictoryHoldTurnsByPlayerId: const {_otherPlayerId: 5},
    mapObjectiveHoldStatesByObjectiveId: const {
      'unrelated_objective': MapObjectiveHoldState(
        objectiveId: 'unrelated_objective',
        playerId: _otherPlayerId,
        holdTurns: 6,
      ),
    },
    activePlayerId: _playerId,
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
    afkPlayerIds: const {_otherPlayerId},
    kickedPlayerIds: const {'kicked_player'},
    turnStartedAt: DateTime.utc(2026, 7, 18),
    interaction: const GameInteractionState(moveCommandActive: true),
  );
  final selectedCity = state.cities.singleWhere(
    (city) => city.id == selectedCityId,
  );
  final selection = CitySelectionProjector.project(
    state: state,
    city: selectedCity,
    mapTiles: mapTiles,
    ruleset: GameRuleset.defaults,
  );
  final selectedState = state.copyWithInteraction(selection: selection);
  return selectedState.copyWith(
    playerColors: selectedState.playerColors,
    playerCountries: selectedState.playerCountries,
    playerGold: selectedState.playerGold,
    playerWarWeariness: selectedState.playerWarWeariness,
    playerStabilityNet: selectedState.playerStabilityNet,
    units: selectedState.units,
    cities: selectedState.cities,
    artifacts: selectedState.artifacts,
    fieldImprovements: selectedState.fieldImprovements,
    intendedAttacks: selectedState.intendedAttacks,
    resourceTradeAgreements: selectedState.resourceTradeAgreements,
    dominationHoldTurnsByPlayerId: selectedState.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        selectedState.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        selectedState.mapObjectiveHoldStatesByObjectiveId,
    submittedPlayerIds: selectedState.submittedPlayerIds,
    timeoutStreaksByPlayerId: selectedState.timeoutStreaksByPlayerId,
    afkPlayerIds: selectedState.afkPlayerIds,
    kickedPlayerIds: selectedState.kickedPlayerIds,
  );
}

GameCity _city({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityHex center = const CityHex(col: 1, row: 1),
  CityProductionQueue? productionQueue,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    controlledHexes: [center],
    productionQueue: productionQueue,
  );
}

MapReadView _mapView() {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 3,
      tiles: [
        for (var row = 0; row < 3; row++)
          for (var col = 0; col < 3; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
