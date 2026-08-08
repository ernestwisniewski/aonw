import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WorldMap mapData;
  late GameUnit settler;
  late GameClientState state;

  setUp(() {
    mapData = _map7x7();
    settler = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 3,
      row: 3,
      army: const [ArmyTroop(type: TroopType.settler, count: 1)],
    );
    state = GameClientState(
      units: [settler],
      activePlayerId: 'player_1',
      interaction: InteractionState(
        selection: GameSelection.unit(settler),
        moveCommandActive: true,
      ),
    );
  });

  group('city founding interaction reducer', () {
    test('starts a presentation-only draft for a controllable settler', () {
      final next = CityFoundingReducer.startCityFounding(state, mapData);

      expect(next.cityFoundingDraft?.unitId, settler.id);
      expect(next.cityFoundingDraft?.ownerPlayerId, 'player_1');
      expect(next.cityFoundingDraft?.controlledHexes, isEmpty);
      expect(next.moveCommandActive, isFalse);
    });

    test('does not start a draft for a foreign settler', () {
      final foreign = settler.copyWith(ownerPlayerId: 'player_2');
      final foreignState = state
          .copyWith(units: [foreign], activePlayerId: 'player_1')
          .copyWithInteraction(selection: GameSelection.unit(foreign));

      expect(
        CityFoundingReducer.startCityFounding(foreignState, mapData),
        same(foreignState),
      );
    });

    test('tile taps toggle only valid draft territory', () {
      final started = CityFoundingReducer.startCityFounding(state, mapData);
      final added = CityFoundingReducer.toggleControlledHex(
        started,
        const TileTappedCommand(3, 2),
        mapData,
      );
      final removed = CityFoundingReducer.toggleControlledHex(
        added,
        const TileTappedCommand(3, 2),
        mapData,
      );

      expect(added.cityFoundingDraft?.controlledHexes, const [
        CityHex(col: 3, row: 2),
      ]);
      expect(removed.cityFoundingDraft?.controlledHexes, isEmpty);
    });

    test('only adds second-ring territory after a connected first choice', () {
      final started = CityFoundingReducer.startCityFounding(state, mapData);
      final disconnected = CityFoundingReducer.toggleControlledHex(
        started,
        const TileTappedCommand(5, 3),
        mapData,
      );
      final first = CityFoundingReducer.toggleControlledHex(
        started,
        const TileTappedCommand(4, 3),
        mapData,
      );
      final connected = CityFoundingReducer.toggleControlledHex(
        first,
        const TileTappedCommand(5, 3),
        mapData,
      );

      expect(disconnected, same(started));
      expect(connected.cityFoundingDraft?.controlledHexes, const [
        CityHex(col: 4, row: 3),
        CityHex(col: 5, row: 3),
      ]);
    });

    test('removing a bridge also removes territory disconnected by it', () {
      final started = CityFoundingReducer.startCityFounding(state, mapData);
      final first = CityFoundingReducer.toggleControlledHex(
        started,
        const TileTappedCommand(4, 3),
        mapData,
      );
      final second = CityFoundingReducer.toggleControlledHex(
        first,
        const TileTappedCommand(5, 3),
        mapData,
      );
      final removedBridge = CityFoundingReducer.toggleControlledHex(
        second,
        const TileTappedCommand(4, 3),
        mapData,
      );

      expect(removedBridge.cityFoundingDraft?.controlledHexes, isEmpty);
    });

    test('starts when the only valid territory is a two-step chain', () {
      final chainMap = _chainMap(includeSecondControlledHex: true);
      final chainSettler = GameUnit.produced(
        id: 'chain_settler',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 0,
        row: 0,
      );
      final chainState = GameClientState(
        units: [chainSettler],
        activePlayerId: 'player_1',
        interaction: InteractionState(
          selection: GameSelection.unit(chainSettler),
        ),
      );

      expect(
        CityFoundingReducer.startCityFounding(
          chainState,
          chainMap,
        ).cityFoundingDraft,
        isNotNull,
      );
      expect(
        CityFoundingReducer.startCityFounding(
          chainState,
          _chainMap(includeSecondControlledHex: false),
        ),
        same(chainState),
      );
    });

    test('cancel clears the draft and preserves unrelated state', () {
      final started = CityFoundingReducer.startCityFounding(state, mapData);
      final cancelled = CityFoundingReducer.cancelCityFounding(started);

      expect(cancelled.cityFoundingDraft, isNull);
      expect(cancelled.units.single, same(started.units.single));
      expect(cancelled.activePlayerId, started.activePlayerId);
    });
  });
}

WorldMap _map7x7() => WorldMap(
  cols: 7,
  rows: 7,
  tiles: [
    for (var row = 0; row < 7; row++)
      for (var col = 0; col < 7; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldMap _chainMap({required bool includeSecondControlledHex}) => WorldMap(
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < (includeSecondControlledHex ? 3 : 2); col++)
      WorldTile(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);
