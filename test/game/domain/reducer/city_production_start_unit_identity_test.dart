import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  final rejectionCases =
      <
        ({
          String name,
          StartUnitProductionCommand command,
          GameCommandContext context,
        })
      >[
        (
          name: 'hotseat semantic rejection',
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.archer,
          ),
          context: const GameCommandContext(),
        ),
        (
          name: 'explicit foreign actor rejection',
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.warrior,
          ),
          context: const GameCommandContext(actorPlayerId: _otherPlayerId),
        ),
      ];

  for (final rejectionCase in rejectionCases) {
    test(
      '${rejectionCase.name} keeps the full state and interaction identity',
      () {
        final mapView = _mapView();
        final queue = CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 7,
        );
        final targetCity = _city(productionQueue: queue, productionOverflow: 9);
        final state = _stateWithSelection(
          cities: [targetCity],
          selectedCityId: targetCity.id,
          mapTiles: mapView,
        );
        final cities = state.cities;
        final city = cities.single;
        final interaction = state.interaction;
        final selection = state.selection;

        final result = _startUnit(
          state,
          rejectionCase.command,
          mapView,
          context: rejectionCase.context,
        );

        expect(result.events, isEmpty);
        expect(result.state, same(state));
        expect(result.state.cities, same(cities));
        expect(result.state.cities.single, same(city));
        expect(result.state.cities.single.productionQueue, same(queue));
        expect(result.state.interaction, same(interaction));
        expect(result.state.selection, same(selection));
      },
    );
  }

  test(
    'accepted replacement refreshes matching selection and shares unrelated state',
    () {
      final mapView = _mapView();
      final activeQueue = CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 7,
      );
      final targetCity = _city(
        productionQueue: activeQueue,
        productionOverflow: 13,
      );
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
      final cities = state.cities;
      final units = state.units;
      final research = state.research;
      final playerGold = state.playerGold;
      final interaction = state.interaction;
      final selection = state.selection;

      final result = _startUnit(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        mapView,
      );

      final updatedCity = result.state.cities.first;
      final updatedQueue = updatedCity.productionQueue;
      expect(result.events, isEmpty);
      expect(result.state, isNot(same(state)));
      expect(result.state.cities, isNot(same(cities)));
      expect(updatedCity, isNot(same(targetCity)));
      expect(updatedQueue, isNot(same(activeQueue)));
      expect(result.state.cities.last, same(unrelatedCity));
      expect(result.state.units, same(units));
      expect(result.state.research, same(research));
      expect(result.state.playerGold, same(playerGold));
      expect(
        updatedQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 7,
        ),
      );
      expect(updatedCity.productionOverflow, 13);
      expect(result.state.interaction, isNot(same(interaction)));
      expect(result.state.selection, isNot(same(selection)));
      expect(result.state.selection?.city, same(updatedCity));
      expect(result.state.moveCommandActive, isTrue);
    },
  );

  test('accepted replacement preserves another city selection identity', () {
    final mapView = _mapView();
    final targetCity = _city(
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 7,
      ),
      productionOverflow: 13,
    );
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

    final result = _startUnit(
      state,
      const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      mapView,
    );

    expect(result.events, isEmpty);
    expect(result.state, isNot(same(state)));
    expect(result.state.interaction, same(interaction));
    expect(result.state.selection, same(selection));
    expect(result.state.selection?.city, same(selectedCityInState));
    expect(result.state.cities.last, same(selectedCityInState));
    expect(
      result.state.cities.first.productionQueue?.target,
      const UnitProductionTarget(GameUnitType.warrior),
    );
  });

  test(
    'same target is an accepted value no-op with fresh local identities',
    () {
      final mapView = _mapView();
      final queue = CityProductionQueue.unit(
        unitType: GameUnitType.warrior,
        investedProduction: 5,
      );
      final targetCity = _city(productionQueue: queue, productionOverflow: 6);
      final state = _stateWithSelection(
        cities: [targetCity],
        selectedCityId: targetCity.id,
        mapTiles: mapView,
      );
      final cities = state.cities;
      final city = cities.single;
      final interaction = state.interaction;
      final selection = state.selection;

      final result = _startUnit(
        state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        mapView,
      );

      final updatedCity = result.state.cities.single;
      final updatedQueue = updatedCity.productionQueue;
      expect(result.events, isEmpty);
      expect(result.state, isNot(same(state)));
      expect(result.state.cities, isNot(same(cities)));
      expect(updatedCity, isNot(same(city)));
      expect(updatedCity, city);
      expect(updatedQueue, queue);
      expect(updatedQueue, isNot(same(queue)));
      expect(result.state.interaction, isNot(same(interaction)));
      expect(result.state.selection, isNot(same(selection)));
      expect(result.state.selection?.city, same(updatedCity));
      expect(result.state.selection?.cityYield, selection?.cityYield);
      expect(
        result.state.selection?.cityTileYieldBreakdown?.total,
        selection?.cityTileYieldBreakdown?.total,
      );
      expect(
        result.state.selection?.cityEconomy?.grossYield,
        selection?.cityEconomy?.grossYield,
      );
      expect(
        result.state.selection?.cityEconomy?.netYield,
        selection?.cityEconomy?.netYield,
      );
      expect(
        result.state.selection?.cityEconomy?.growthCost,
        selection?.cityEconomy?.growthCost,
      );
      expect(result.state.moveCommandActive, isTrue);
    },
  );
}

GameStateTransition _startUnit(
  GameState state,
  StartUnitProductionCommand command,
  MapReadView mapView, {
  GameCommandContext context = const GameCommandContext(),
}) {
  return CityProductionReducer.startUnitProduction(
    state,
    command,
    mapView,
    context: context,
  );
}

GameState _stateWithSelection({
  required List<GameCity> cities,
  required String selectedCityId,
  required MapTileLookup mapTiles,
}) {
  final state = GameState(
    playerColors: const {_playerId: 0xFF123456, _otherPlayerId: 0xFF654321},
    playerGold: const {_playerId: 41, _otherPlayerId: 23},
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
    activePlayerId: _playerId,
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
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
    playerGold: selectedState.playerGold,
    playerWarWeariness: selectedState.playerWarWeariness,
    playerStabilityNet: selectedState.playerStabilityNet,
    units: selectedState.units,
    cities: selectedState.cities,
    submittedPlayerIds: selectedState.submittedPlayerIds,
    timeoutStreaksByPlayerId: selectedState.timeoutStreaksByPlayerId,
  );
}

GameCity _city({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityHex center = const CityHex(col: 1, row: 1),
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    controlledHexes: [center],
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
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
