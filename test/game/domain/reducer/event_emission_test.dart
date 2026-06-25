import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/movement_reducer.dart';
import 'package:aonw/game/domain/reducer/turn_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
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

MapData _map7x7() => MapData(
  cols: 7,
  rows: 7,
  tiles: [
    for (int row = 0; row < 7; row++)
      for (int col = 0; col < 7; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameUnit _commander({int col = 0, int row = 0, int movementPoints = 3}) =>
    GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: col,
      row: row,
    ).copyWith(movementPoints: movementPoints);

GameUnit _settler({int col = 3, int row = 3}) => GameUnit.startingCommander(
  ownerPlayerId: 'player_1',
  col: col,
  row: row,
  army: const [ArmyTroop(type: TroopType.settler, count: 1)],
);
void main() {
  group('Event emission from reducers', () {
    test('MovementReducer.moveUnit emits UnitMovedEvent', () {
      final mapData = _map(5, 5);
      final unit = _commander(col: 2, row: 3);
      final state = GameState(units: [unit], activePlayerId: 'player_1');

      final command = MoveUnitCommand(unit.id, 3, 3);
      final transition = MovementReducer.moveUnit(state, command, mapData);

      expect(transition.events, hasLength(1));
      final event = transition.events.first;
      expect(event, isA<UnitMovedEvent>());
      final moved = event as UnitMovedEvent;
      expect(moved.unitId, equals(unit.id));
      expect(moved.fromCol, equals(2));
      expect(moved.fromRow, equals(3));
      expect(moved.toCol, equals(3));
      expect(moved.toRow, equals(3));
    });
    test('city founding job emits CityFoundedEvent on turn processing', () {
      final mapData = _map7x7();
      final settler = _settler(col: 3, row: 3);

      final stateWithUnit = GameState(
        playerCountries: const {'player_1': PlayerCountry.france},
        units: [settler],
        activePlayerId: 'player_1',
      ).copyWith(selection: GameSelection.unit(settler));

      final started = CityFoundingReducer.startCityFounding(
        stateWithUnit,
        mapData,
      );
      final stateWithDraft = started.copyWith(
        cityFoundingDraft: started.cityFoundingDraft!.copyWith(
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 4, row: 3),
          ],
        ),
      );

      expect(
        stateWithDraft.cityFoundingDraft,
        isNotNull,
        reason: 'Draft should be set after startCityFounding',
      );

      final scheduled = CityFoundingReducer.confirmCityFounding(
        stateWithDraft,
        mapData,
      );
      final transition = TurnReducer.advanceCitiesForPlayer(
        scheduled.state,
        'player_1',
        mapData,
      );

      final event = transition.events.whereType<CityFoundedEvent>().single;
      expect(event, isA<CityFoundedEvent>());
      expect(event.ownerPlayerId, equals('player_1'));
      expect(event.cityId, isNotEmpty);
      expect(transition.state.cities.single.name, 'Paris');
    });
    test('TurnReducer.advanceCitiesForPlayer emits TurnEndedEvent', () {
      final mapData = _map(5, 5);
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

      final transition = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
      );

      final turnEndedEvents = transition.events.whereType<TurnEndedEvent>();
      expect(turnEndedEvents, hasLength(1));
      expect(turnEndedEvents.first.playerId, equals('player_1'));
    });
    test('city turn pending claim emits CityClaimedHexEvent', () {
      final mapData = _map7x7();
      const cityId = 'city_1';
      const city = GameCity(
        id: cityId,
        ownerPlayerId: 'player_1',
        name: 'Testowo',
        center: CityHex(col: 3, row: 3),
        storedFood: 100,
      );
      const state = GameState(cities: [city], activePlayerId: 'player_1');

      final transition = TurnReducer.advanceCitiesForPlayer(
        state,
        'player_1',
        mapData,
      );

      final event = transition.events.whereType<CityClaimedHexEvent>().single;
      expect(event, isA<CityClaimedHexEvent>());
      expect(event.cityId, equals(cityId));
      final claimedHex = CityHex(col: event.col, row: event.row);
      expect(city.controlledHexes, isNot(contains(claimedHex)));
      expect(
        transition.state.cities.single.controlledHexes,
        contains(claimedHex),
      );
    });
    test(
      'TurnReducer.advanceCitiesForPlayer emits TurnEndedEvent even when nothing changed',
      () {
        final mapData = _map(5, 5);

        // State has no cities or units owned by 'player_2', so all processors
        // will return changed: false — exercising the no-change code path.
        const state = GameState(activePlayerId: 'player_2');

        final transition = TurnReducer.advanceCitiesForPlayer(
          state,
          'player_2',
          mapData,
        );

        final turnEndedEvents = transition.events.whereType<TurnEndedEvent>();
        expect(
          turnEndedEvents,
          hasLength(1),
          reason: 'TurnEndedEvent must be emitted regardless of data changes',
        );
        expect(turnEndedEvents.first.playerId, equals('player_2'));
      },
    );
  });
}
