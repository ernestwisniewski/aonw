import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile(int col, int row) => TileData(
  col: col,
  row: row,
  terrains: const [TerrainType.plains],
  resources: const [],
  height: 0,
);

FogVisibilityQuery _visibility({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogVisibilityQuery(
    playerId: 'player_1',
    state: FogOfWarState.empty.updatePlayer(
      PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    ),
  );
}

void main() {
  group('UnitMovementVisibilityRules', () {
    test('allows movement planning through visible and discovered tiles', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final visibleTile = _tile(6, 0);
      final discoveredTile = _tile(7, 0);
      final visibility = _visibility(
        discovered: {const HexCoordinate(col: 7, row: 0)},
        visible: {const HexCoordinate(col: 6, row: 0)},
      );

      expect(
        UnitMovementVisibilityRules.canPlanThroughTile(
          unit: unit,
          tile: visibleTile,
          visibility: visibility,
        ),
        isTrue,
      );
      expect(
        UnitMovementVisibilityRules.canPlanThroughTile(
          unit: unit,
          tile: discoveredTile,
          visibility: visibility,
        ),
        isTrue,
      );
    });

    test('allows hidden tiles only inside the scouting pathing range', () {
      final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final visibility = _visibility();

      expect(
        UnitMovementVisibilityRules.canPlanThroughTile(
          unit: unit,
          tile: _tile(3, 0),
          visibility: visibility,
        ),
        isTrue,
      );
      expect(
        UnitMovementVisibilityRules.canPlanThroughTile(
          unit: unit,
          tile: _tile(4, 0),
          visibility: visibility,
        ),
        isFalse,
      );
    });
  });
}
