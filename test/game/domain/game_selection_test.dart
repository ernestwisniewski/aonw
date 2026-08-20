import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/tile_terrain_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSelection tile snapshot', () {
    test('freezes values borrowed through MapTileView', () {
      final terrains = <TerrainType>[TerrainType.grassland];
      final resources = <ResourceType>[ResourceType.wheat, ResourceType.oil];
      final source = _MutableTile(
        col: 2,
        row: 3,
        height: 1,
        terrains: terrains,
        resources: resources,
      );

      final selection = GameSelection.tile(source);
      terrains[0] = TerrainType.desert;
      resources.clear();
      source
        ..col = 8
        ..row = 9
        ..height = 4;

      final snapshot = selection.tile!;
      expect(snapshot.col, 2);
      expect(snapshot.row, 3);
      expect(snapshot.height, 1);
      expect(snapshot.terrains, [TerrainType.grassland]);
      expect(snapshot.resources, [ResourceType.wheat, ResourceType.oil]);
      expect(
        () => snapshot.terrains.add(TerrainType.forest),
        throwsUnsupportedError,
      );
      expect(
        () => snapshot.resources.add(ResourceType.iron),
        throwsUnsupportedError,
      );
    });

    test('filters a copy and reuses an already-visible snapshot', () {
      final source = _MutableTile(
        col: 2,
        row: 3,
        height: 1,
        terrains: [TerrainType.grassland],
        resources: [ResourceType.wheat, ResourceType.oil],
      );
      final selection = GameSelection.tile(source);

      final visible = selection.withVisibleResources(
        playerId: 'p1',
        research: ResearchState.empty,
      );

      expect(visible, isNot(same(selection)));
      expect(selection.tile!.resources, [ResourceType.wheat, ResourceType.oil]);
      expect(visible.tile!.resources, [ResourceType.wheat]);
      expect(
        visible.withVisibleResources(
          playerId: 'p1',
          research: ResearchState.empty,
        ),
        same(visible),
      );
    });
  });
}

final class _MutableTile implements MapTileView {
  _MutableTile({
    required this.col,
    required this.row,
    required this.height,
    required this.terrains,
    required this.resources,
  });

  @override
  int col;

  @override
  int row;

  @override
  int height;

  final List<TerrainType> terrains;

  @override
  TileTerrainSemantics get terrain =>
      TileTerrainSemantics.fromMovementProfile(terrains);

  @override
  final List<ResourceType> resources;
}
