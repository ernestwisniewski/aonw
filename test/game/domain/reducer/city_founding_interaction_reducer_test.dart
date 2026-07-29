import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MapData mapData;
  late GameUnit settler;
  late GameState state;

  setUp(() {
    mapData = _map7x7();
    settler = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 3,
      row: 3,
      army: const [ArmyTroop(type: TroopType.settler, count: 1)],
    );
    state = GameState(
      units: [settler],
      activePlayerId: 'player_1',
      interaction: GameInteractionState(
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

    test('cancel clears the draft and preserves unrelated state', () {
      final started = CityFoundingReducer.startCityFounding(state, mapData);
      final cancelled = CityFoundingReducer.cancelCityFounding(started);

      expect(cancelled.cityFoundingDraft, isNull);
      expect(cancelled.units.single, same(started.units.single));
      expect(cancelled.activePlayerId, started.activePlayerId);
    });
  });
}

MapData _map7x7() => MapData(
  cols: 7,
  rows: 7,
  tiles: [
    for (var row = 0; row < 7; row++)
      for (var col = 0; col < 7; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
