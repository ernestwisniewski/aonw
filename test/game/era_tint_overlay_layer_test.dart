import 'package:aonw/game/presentation/engine/rendering_layers/era_tint_overlay_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 2,
  rows: 1,
  tiles: [
    for (var col = 0; col < 2; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

PlayerResearchState _research(Set<TechnologyId> unlocked) {
  return PlayerResearchState(unlockedTechnologyIds: unlocked);
}

void main() {
  group('EraTintOverlayLayer', () {
    test('resolves the highest unlocked technology era', () {
      expect(
        EraTintOverlayLayer.dominantEraFor(PlayerResearchState.empty),
        TechnologyEra.foundation,
      );
      expect(
        EraTintOverlayLayer.dominantEraFor(
          _research({TechnologyId.agriculture, TechnologyId.machinery}),
        ),
        TechnologyEra.industry,
      );
      expect(
        EraTintOverlayLayer.dominantEraFor(
          _research({TechnologyId.machinery, TechnologyId.strategy}),
        ),
        TechnologyEra.strategy,
      );
    });

    test('keeps expansion visually neutral', () {
      expect(
        EraTintOverlay.colorForEra(TechnologyEra.expansion).toARGB32(),
        0x00000000,
      );
    });

    test('queues and updates the overlay on the same parent', () {
      final map = _map();
      final parent = PositionComponent();
      final layer = EraTintOverlayLayer();
      void sync(PlayerResearchState playerResearch) {
        layer.sync(
          parent: parent,
          mapData: map,
          playerResearch: playerResearch,
        );
      }

      sync(PlayerResearchState.empty);
      expect(parent.children.whereType<EraTintOverlayLayer>(), hasLength(1));
      final overlay = layer.componentForTesting!;
      sync(_research({TechnologyId.machinery}));

      expect(layer.componentForTesting, same(overlay));
      expect(overlay.era, TechnologyEra.industry);
      expect(overlay.tilePathCountForTesting, map.tiles.length);
      expect(overlay.boundsForTesting.isEmpty, isFalse);
    });

    test('clears the overlay for the neutral expansion era', () {
      final map = _map();
      final parent = PositionComponent();
      final layer = EraTintOverlayLayer();
      void sync(PlayerResearchState playerResearch) {
        layer.sync(
          parent: parent,
          mapData: map,
          playerResearch: playerResearch,
        );
      }

      sync(PlayerResearchState.empty);
      sync(_research({TechnologyId.storage}));

      expect(parent.children.whereType<EraTintOverlayLayer>(), hasLength(1));
      expect(layer.componentForTesting, isNull);
    });
  });
}
