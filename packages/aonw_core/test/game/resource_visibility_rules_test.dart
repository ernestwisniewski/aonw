import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceVisibilityRules', () {
    test('keeps non-gated resources visible before research', () {
      expect(
        ResourceVisibilityRules.isRevealed(
          resource: ResourceType.iron,
          playerId: 'player_1',
          research: ResearchState.empty,
        ),
        isTrue,
      );
      expect(
        ResourceVisibilityRules.isRevealed(
          resource: ResourceType.wheat,
          playerId: 'player_1',
          research: ResearchState.empty,
        ),
        isTrue,
      );
    });

    test('reveals strategic resources at their technology gates', () {
      const playerId = 'player_1';
      final research = _researchWith({
        TechnologyId.animalHusbandry,
        TechnologyId.combustion,
      });

      expect(
        ResourceVisibilityRules.isRevealed(
          resource: ResourceType.horses,
          playerId: playerId,
          research: ResearchState.empty,
        ),
        isFalse,
      );
      expect(
        ResourceVisibilityRules.isRevealed(
          resource: ResourceType.horses,
          playerId: playerId,
          research: research,
        ),
        isTrue,
      );
      expect(
        ResourceVisibilityRules.isRevealed(
          resource: ResourceType.oil,
          playerId: playerId,
          research: research,
        ),
        isTrue,
      );
      expect(
        ResourceVisibilityRules.isRevealed(
          resource: ResourceType.uranium,
          playerId: playerId,
          research: research,
        ),
        isFalse,
      );
    });

    test('filters tile and map resources for the player research state', () {
      final mapData = MapData(
        cols: 2,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [ResourceType.horses, ResourceType.iron],
            height: 0,
          ),
          TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.desert],
            resources: [ResourceType.oil, ResourceType.wheat],
            height: 0,
          ),
        ],
        mapName: 'visibility_test',
      );

      final visibleMap = ResourceVisibilityRules.visibleMap(
        mapData: mapData,
        playerId: 'player_1',
        research: _researchWith({TechnologyId.animalHusbandry}),
      );

      expect(visibleMap.mapName, 'visibility_test');
      expect(visibleMap.tileAt(0, 0)?.resources, [
        ResourceType.horses,
        ResourceType.iron,
      ]);
      expect(visibleMap.tileAt(1, 0)?.resources, [ResourceType.wheat]);
      expect(mapData.tileAt(1, 0)?.resources, [
        ResourceType.oil,
        ResourceType.wheat,
      ]);
    });
  });
}

ResearchState _researchWith(Set<TechnologyId> technologyIds) {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(unlockedTechnologyIds: technologyIds),
    },
  );
}
