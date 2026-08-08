import 'package:aonw/game/presentation/engine/rendering_layers/city/city_founding_preview_layer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview follows the dynamic connected selection frontier', () {
    final map = _map5x5();
    final layer = CityFoundingPreviewLayer(colorForPlayer: (_) => 0xff0000ff);
    final parent = Component();
    final emptyDraft = CityFoundingDraft(
      unitId: 'settler_1',
      ownerPlayerId: 'player_1',
      center: const CityHex(col: 2, row: 2),
    );

    layer.sync(
      parent: parent,
      draft: emptyDraft,
      mapData: map,
      cities: const [],
    );

    expect(
      layer.componentForTesting?.candidateHexes.map(
        (candidate) => candidate.hex,
      ),
      unorderedEquals(const [
        CityHex(col: 3, row: 1),
        CityHex(col: 3, row: 2),
        CityHex(col: 2, row: 3),
        CityHex(col: 1, row: 2),
        CityHex(col: 1, row: 1),
        CityHex(col: 2, row: 1),
      ]),
    );

    layer.sync(
      parent: parent,
      draft: emptyDraft.copyWith(
        controlledHexes: const [CityHex(col: 3, row: 2)],
      ),
      mapData: map,
      cities: const [],
    );

    final extended = layer.componentForTesting!.candidateHexes.map(
      (candidate) => candidate.hex,
    );
    expect(extended, contains(const CityHex(col: 4, row: 2)));
    expect(extended, isNot(contains(const CityHex(col: 4, row: 1))));

    layer.sync(
      parent: parent,
      draft: emptyDraft.copyWith(
        controlledHexes: const [
          CityHex(col: 3, row: 2),
          CityHex(col: 4, row: 2),
        ],
      ),
      mapData: map,
      cities: const [],
    );

    expect(layer.componentForTesting?.candidateHexes, isEmpty);
  });
}

WorldMap _map5x5() => WorldMap(
  cols: 5,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
