import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tracks the logical hex anchor for stacked and moving units', () {
    final parent = PositionComponent();
    final warrior = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 2,
      row: 1,
    );
    final merchant = GameUnit.produced(
      id: 'merchant_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.merchant,
      col: 2,
      row: 1,
    );
    final layer =
        UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF)
          ..sync(
            parent: parent,
            units: [warrior, merchant],
            selectedUnitId: null,
            cityTiles: const {(col: 2, row: 1)},
          );

    expect(
      layer.hexAnchorWorldPositionForUnit(warrior.id),
      UnitMarkerLayer.worldPositionFor(2, 1),
    );
    expect(
      layer.hexAnchorWorldPositionForUnit(merchant.id),
      UnitMarkerLayer.worldPositionFor(2, 1),
    );

    layer.preparePendingMoveOrigin(warrior.id, col: 3, row: 1);

    expect(
      layer.hexAnchorWorldPositionForUnit(warrior.id),
      UnitMarkerLayer.worldPositionFor(3, 1),
    );
  });
}

WorldMap _map() => WorldMap(
  cols: 4,
  rows: 2,
  tiles: [
    for (var row = 0; row < 2; row++)
      for (var col = 0; col < 4; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
