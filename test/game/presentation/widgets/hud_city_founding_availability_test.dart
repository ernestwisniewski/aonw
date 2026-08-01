import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/city/hud_city_founding_availability.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudCityFoundingAvailability', () {
    test('allows controlled settler on a valid tile', () {
      final settler = _settler(ownerPlayerId: 'player_1');
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [settler],
        interaction: InteractionState(selection: GameSelection.unit(settler)),
      );

      expect(
        HudCityFoundingAvailability.canStart(
          state: state,
          mapTiles: _mapData(),
        ),
        isTrue,
      );
    });

    test('rejects missing state or missing selected unit', () {
      expect(
        HudCityFoundingAvailability.canStart(state: null, mapTiles: _mapData()),
        isFalse,
      );
      expect(
        HudCityFoundingAvailability.canStart(
          state: GameClientState(activePlayerId: 'player_1'),
          mapTiles: _mapData(),
        ),
        isFalse,
      );
    });

    test('rejects unit controlled by another active player', () {
      final settler = _settler(ownerPlayerId: 'player_2');
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [settler],
        interaction: InteractionState(selection: GameSelection.unit(settler)),
      );

      expect(
        HudCityFoundingAvailability.canStart(
          state: state,
          mapTiles: _mapData(),
        ),
        isFalse,
      );
    });

    test('rejects selected settler outside map data', () {
      final settler = _settler(ownerPlayerId: 'player_1', col: 8, row: 8);
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [settler],
        interaction: InteractionState(selection: GameSelection.unit(settler)),
      );

      expect(
        HudCityFoundingAvailability.canStart(
          state: state,
          mapTiles: _mapData(),
        ),
        isFalse,
      );
    });
  });
}

GameUnit _settler({required String ownerPlayerId, int col = 0, int row = 0}) {
  return GameUnit.produced(
    id: 'settler_$ownerPlayerId',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.settler,
    col: col,
    row: row,
  );
}

WorldMap _mapData() {
  return WorldMap(
    cols: 2,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 2; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
