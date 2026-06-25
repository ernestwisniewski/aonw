import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_cache.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_catalog.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FieldImprovementMarker', () {
    test('loads the improvement atlases', () async {
      for (final assetPath in FieldImprovementSpriteCatalog.assetPaths) {
        final image = await FieldImprovementSpriteCache.load(assetPath);

        expect(image.width, greaterThan(0), reason: assetPath);
        expect(image.height, greaterThan(0), reason: assetPath);
      }
    });

    test('uses the field improvement atlas footprint', () async {
      final image = await FieldImprovementSpriteCache.load(
        FieldImprovementSpriteCatalog.assetPathFor(
          FieldImprovementType.orchard,
        ),
      );
      const capStyle = BoardAssetCapStyles.improvement;
      final marker = FieldImprovementMarker(
        position: Vector2.zero(),
        type: FieldImprovementType.orchard,
        eraColumn: 1,
      );

      expect(
        marker.markerSizeForTesting.x,
        closeTo(capStyle.componentSize.width, 0.0001),
      );
      expect(
        marker.markerSizeForTesting.y,
        closeTo(capStyle.componentSize.height, 0.0001),
      );
      expect(marker.anchor, Anchor.center);
      expect(marker.sourceInsetForTesting, 0);
      expect(marker.boardCapStyleForTesting, capStyle);
      expect(marker.adjustmentIdForTesting, 'field-improvement.orchard.era-1');
      expect(marker.assetPathForTesting, 'assets/sprites/improvements1.jpg');
      expect(
        marker.sourceRectForTesting(image),
        ui.Rect.fromLTWH(
          (2 * image.width / FieldImprovementSpriteCatalog.sheetColumns)
              .roundToDouble(),
          (image.height / FieldImprovementSpriteCatalog.sheetRows)
              .roundToDouble(),
          ((3 * image.width / FieldImprovementSpriteCatalog.sheetColumns)
                      .round() -
                  (2 * image.width / FieldImprovementSpriteCatalog.sheetColumns)
                      .round())
              .toDouble(),
          ((2 * image.height / FieldImprovementSpriteCatalog.sheetRows)
                      .round() -
                  (image.height / FieldImprovementSpriteCatalog.sheetRows)
                      .round())
              .toDouble(),
        ),
      );
    });

    test('clips the improvement sprite to a smaller board cap', () {
      final marker = FieldImprovementMarker(
        position: Vector2.zero(),
        type: FieldImprovementType.uraniumMine,
        eraColumn: 1,
      );
      const capStyle = BoardAssetCapStyles.improvement;
      final bounds = marker.spriteBoundsForTesting;
      final clip = marker.spriteClipPathForTesting;

      expect(bounds.width, capStyle.topSize.width);
      expect(bounds.height, capStyle.topSize.height);
      expect(clip.contains(bounds.center), isTrue);
      expect(clip.contains(bounds.topLeft), isFalse);
      expect(
        capStyle.topSize.width,
        lessThan(BoardAssetCapStyles.city.topSize.width),
      );
      expect(
        capStyle.topSize.height,
        lessThan(BoardAssetCapStyles.city.topSize.height),
      );
    });

    test('uses a silver rim that brightens when selected', () {
      final marker = FieldImprovementMarker(
        position: Vector2.zero(),
        type: FieldImprovementType.farm,
        eraColumn: 0,
      );

      expect(marker.selectedForTesting, isFalse);
      expect(
        marker.rimColorForTesting,
        BoardAssetCapStyles.improvement.rimColor,
      );
      expect(BoardAssetCapStyles.improvement.rimColor, const Color(0xFFC8CCD2));
      expect(
        BoardAssetCapStyles.improvement.rimShadowColor,
        const Color(0xFF666C75),
      );

      marker.selected = true;

      expect(marker.selectedForTesting, isTrue);
      expect(marker.rimColorForTesting, isNot(Colors.white));
      expect(marker.rimColorForTesting, const Color(0xFFF1F4F8));
      expect(marker.rimShadowColorForTesting, const Color(0xFF9AA2AE));
      expect(
        marker.rimColorForTesting.computeLuminance(),
        greaterThan(
          BoardAssetCapStyles.improvement.rimColor.computeLuminance(),
        ),
      );
      expect(
        marker.rimShadowColorForTesting.computeLuminance(),
        greaterThan(
          BoardAssetCapStyles.improvement.rimShadowColor.computeLuminance(),
        ),
      );
    });
  });

  group('FieldImprovementMarkerLayer', () {
    test(
      'selects atlas row and era column from improvement owner research',
      () {
        final layer = FieldImprovementMarkerLayer();
        final parent = Component();
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 2, row: 1)],
        );
        const improvement = FieldImprovement(
          hex: CityHex(col: 2, row: 1),
          type: FieldImprovementType.coalShaft,
          builtByCityId: 'city_1',
        );
        final research = ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.coalMining},
            ),
          },
        );

        layer.sync(
          parent: parent,
          improvements: const [improvement],
          cities: const [city],
          research: research,
        );

        expect(layer.markerCountForTesting, 1);
        expect(
          parent.children.query<FieldImprovementMarkerLayer>(),
          hasLength(1),
        );
        expect(parent.children.query<FieldImprovementMarker>(), hasLength(1));
        expect(
          layer.markerTypeForTesting(2, 1),
          FieldImprovementType.coalShaft,
        );
        expect(layer.markerEraColumnForTesting(2, 1), 2);
        expect(
          layer.markerPriorityForTesting(2, 1),
          lessThan(18 + 1 * 1000 + 2),
        );
      },
    );

    test('anchors improvement markers to the projected hex top face', () {
      final layer = FieldImprovementMarkerLayer();
      final parent = Component();
      const improvement = FieldImprovement(
        hex: CityHex(col: 2, row: 1),
        type: FieldImprovementType.farm,
      );
      final tileCenter = HexGeometry.tilePosition(
        col: improvement.hex.col,
        row: improvement.hex.row,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      final expectedTopFaceY =
          (tileCenter.y +
              HexTileMetrics.topCenterAnchorOffsetY(
                MapConfig.defaultConfig.hexRadius,
              )) *
          HexGrid.perspectiveY;

      layer.sync(
        parent: parent,
        improvements: const [improvement],
        cities: const [],
      );

      final position = layer.markerPositionForTesting(2, 1)!;
      expect(position.x, closeTo(tileCenter.x, 0.0001));
      expect(position.y, closeTo(expectedTopFaceY, 0.0001));
    });

    test('marks only the selected improvement with the brighter rim', () {
      final layer = FieldImprovementMarkerLayer();
      final parent = Component();
      const farm = FieldImprovement(
        hex: CityHex(col: 1, row: 0),
        type: FieldImprovementType.farm,
      );
      const mine = FieldImprovement(
        hex: CityHex(col: 2, row: 0),
        type: FieldImprovementType.mine,
      );

      layer.sync(
        parent: parent,
        improvements: const [farm, mine],
        cities: const [],
        selectedHex: farm.hex,
      );

      expect(layer.markerSelectedForTesting(1, 0), isTrue);
      expect(layer.markerSelectedForTesting(2, 0), isFalse);
      expect(layer.markerRimColorForTesting(1, 0), isNot(Colors.white));
      expect(
        layer.markerRimColorForTesting(1, 0)!.computeLuminance(),
        greaterThan(
          BoardAssetCapStyles.improvement.rimColor.computeLuminance(),
        ),
      );

      layer.sync(
        parent: parent,
        improvements: const [farm, mine],
        cities: const [],
        selectedHex: null,
      );

      expect(layer.markerSelectedForTesting(1, 0), isFalse);
      expect(
        layer.markerRimColorForTesting(1, 0),
        BoardAssetCapStyles.improvement.rimColor,
      );
    });
  });
}
