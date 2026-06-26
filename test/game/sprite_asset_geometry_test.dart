import 'dart:io';
import 'dart:ui' as ui;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_sprite_catalog.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/assets/sprite_atlas_frame_bounds.dart';
import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';
import 'package:aonw/shared/assets/ui_image_cache.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprite asset geometry', () {
    test('sizes board caps within the projected default map hex top face', () {
      final hexRadius = MapConfig.defaultConfig.hexRadius;
      final projectedWidth = HexTileMetrics.width(hexRadius);
      final projectedHeight =
          hexRadius * HexTileGeometryLayout.sqrt3 * HexGrid.perspectiveY;
      const city = BoardAssetCapStyles.city;
      const improvement = BoardAssetCapStyles.improvement;

      expect(city.topSize.width, lessThan(projectedWidth));
      expect(city.componentSize.width, lessThan(projectedWidth));
      expect(city.componentSize.height, lessThan(projectedHeight));
      expect(city.componentSize.height, greaterThan(projectedHeight * 0.85));
      expect(improvement.topSize.width, lessThan(city.topSize.width));
      expect(improvement.topSize.height, lessThan(city.topSize.height));
      expect(
        improvement.componentSize.height,
        lessThan(city.componentSize.height),
      );
    });

    test(
      'clips every animated unit and city frame within its own atlas cell',
      () async {
        final checkedAssets = <String>{};

        for (final type in GameUnitType.values) {
          final definition = UnitSpriteCatalog.definitionFor(type)!;
          if (!checkedAssets.add(definition.assetPath)) continue;

          final image = await _loadImage(definition.assetPath);
          addTearDown(image.dispose);
          final imageSize = Vector2(
            image.width.toDouble(),
            image.height.toDouble(),
          );

          expect(
            image.width % definition.columns,
            0,
            reason: definition.assetPath,
          );
          expect(
            image.height % definition.rows,
            0,
            reason: definition.assetPath,
          );

          for (var row = 0; row < definition.rows; row++) {
            final action = UnitSpriteActionDefinition(
              row: row,
              frameDuration: 1,
            );
            for (var column = 0; column < definition.columns; column++) {
              final source = definition.sourceRectFor(
                imageSize: imageSize,
                action: action,
                column: column,
              );
              final cell = SpriteAtlasGeometry.cellRectFor(
                imageWidth: image.width,
                imageHeight: image.height,
                columns: definition.columns,
                rows: definition.rows,
                column: column,
                row: row,
              );

              _expectSourceInsideCell(
                source: source,
                cell: cell,
                inset: definition.sourceInset,
                reason: '${definition.assetPath} row=$row column=$column',
              );
            }
          }
        }

        final cityImage = await _loadImage(CitySpriteCatalog.assetPath);
        addTearDown(cityImage.dispose);
        expect(cityImage.width, CitySpriteCatalog.sourceImageWidth);
        expect(cityImage.height, CitySpriteCatalog.sourceImageHeight);
        expect(CitySpriteCatalog.columns, 6);
        expect(CitySpriteCatalog.rows, 4);

        for (final row in CitySpriteCatalog.visualLevels) {
          for (final profile in CitySpriteCatalog.technologyProfiles) {
            final source = CitySpriteCatalog.sourceRectFor(
              imageWidth: cityImage.width,
              imageHeight: cityImage.height,
              column: profile.index,
              row: row,
            );

            _expectSourceInsideCell(
              source: source,
              cell: SpriteAtlasGeometry.cellRectFor(
                imageWidth: cityImage.width,
                imageHeight: cityImage.height,
                columns: CitySpriteCatalog.columns,
                rows: CitySpriteCatalog.rows,
                column: row,
                row: profile.index,
              ),
              inset: CitySpriteCatalog.sourceInset,
              reason:
                  '${CitySpriteCatalog.assetPath} level=$row profile=${profile.name}',
            );
          }
        }

        expect(
          CitySpriteCatalog.sourceRectFor(
            imageWidth: cityImage.width,
            imageHeight: cityImage.height,
            row: 0,
            column: CitySpriteTechnologyProfile.growthCivic.index,
          ),
          const ui.Rect.fromLTRB(0, 0, 512, 320),
        );
        expect(
          CitySpriteCatalog.sourceRectFor(
            imageWidth: cityImage.width,
            imageHeight: cityImage.height,
            row: 5,
            column: CitySpriteTechnologyProfile.industryModern.index,
          ),
          const ui.Rect.fromLTRB(2560, 960, 3072, 1280),
        );
      },
    );

    test('uses integer cell boundaries for non-even icon atlases', () async {
      final buildingImages = <String, ui.Image>{};
      for (final assetPath in BuildingSpriteCatalog.assetPaths) {
        final image = await _loadImage(assetPath);
        addTearDown(image.dispose);
        buildingImages[assetPath] = image;
        expect(image.width, greaterThan(0), reason: assetPath);
        expect(image.height, greaterThan(0), reason: assetPath);

        final webpPath = assetPath.replaceFirst('.png', '.webp');
        final webpImage = await _loadImage(webpPath);
        addTearDown(webpImage.dispose);
        expect(webpImage.width, image.width, reason: webpPath);
        expect(webpImage.height, image.height, reason: webpPath);
      }

      for (final type in CityBuildingType.values) {
        final data = BuildingSpriteCatalog.iconFor(type);
        final buildingImage = buildingImages[data.assetPath]!;
        expect(data.column, lessThan(data.columns), reason: type.name);
        expect(data.row, lessThan(data.rows), reason: type.name);
        expect(data.sourceInset, 0, reason: type.name);
        expect(data.cropToContent, isFalse, reason: type.name);

        _expectSourceInsideCell(
          source: data.sourceRectFor(buildingImage),
          cell: SpriteAtlasGeometry.cellRectFor(
            imageWidth: buildingImage.width,
            imageHeight: buildingImage.height,
            columns: data.columns,
            rows: data.rows,
            column: data.column,
            row: data.row,
          ),
          inset: data.sourceInset,
          reason: '${data.assetPath} ${type.name}',
        );
      }

      final technologyImage = await _loadImage(
        TechnologySpriteCatalog.assetPath,
      );
      addTearDown(technologyImage.dispose);
      expect(technologyImage.width % TechnologySpriteCatalog.columns, 0);
      expect(technologyImage.height % TechnologySpriteCatalog.rows, 0);

      final technologyWebpPath = TechnologySpriteCatalog.assetPath.replaceFirst(
        '.png',
        '.webp',
      );
      final technologyWebpImage = await _loadImage(technologyWebpPath);
      addTearDown(technologyWebpImage.dispose);
      expect(technologyWebpImage.width, technologyImage.width);
      expect(technologyWebpImage.height, technologyImage.height);

      for (final id in TechnologyId.values) {
        final data = TechnologySpriteCatalog.iconFor(id);
        expect(data.column, lessThan(data.columns), reason: id.name);
        expect(data.row, lessThan(data.rows), reason: id.name);

        _expectSourceInsideCell(
          source: data.sourceRectFor(technologyImage),
          cell: SpriteAtlasGeometry.cellRectFor(
            imageWidth: technologyImage.width,
            imageHeight: technologyImage.height,
            columns: data.columns,
            rows: data.rows,
            column: data.column,
            row: data.row,
          ),
          inset: data.sourceInset,
          reason: '${TechnologySpriteCatalog.assetPath} ${id.name}',
        );
      }

      final improvementImages = <String, ui.Image>{};
      for (final assetPath in FieldImprovementSpriteCatalog.assetPaths) {
        final image = await _loadImage(assetPath);
        addTearDown(image.dispose);
        improvementImages[assetPath] = image;
        expect(image.width, greaterThan(0), reason: assetPath);
        expect(image.height, greaterThan(0), reason: assetPath);
      }

      for (final type in FieldImprovementSpriteCatalog.improvementTypes) {
        final assetPath = FieldImprovementSpriteCatalog.assetPathFor(type);
        final improvementImage = improvementImages[assetPath]!;
        for (final eraColumn in FieldImprovementSpriteCatalog.eraColumns) {
          final source = FieldImprovementSpriteCatalog.sourceRectFor(
            imageWidth: improvementImage.width,
            imageHeight: improvementImage.height,
            type: type,
            eraColumn: eraColumn,
          );
          final cell = SpriteAtlasGeometry.cellRectFor(
            imageWidth: improvementImage.width,
            imageHeight: improvementImage.height,
            columns: FieldImprovementSpriteCatalog.sheetColumns,
            rows: FieldImprovementSpriteCatalog.sheetRows,
            column: FieldImprovementSpriteCatalog.sheetColumnForType(type),
            row: eraColumn,
          );

          _expectSourceInsideCell(
            source: source,
            cell: cell,
            inset: FieldImprovementSpriteCatalog.sourceInset,
            reason: '$assetPath ${type.name} era=$eraColumn',
          );
        }
      }
    });

    test('prefers WebP PNG atlas variants when available', () async {
      addTearDown(UiImageCache.clearForTesting);
      addTearDown(HexIconCache.clearForTesting);

      final buildingAssetPath = BuildingSpriteCatalog.assetPaths.first;
      final buildingImage = await UiImageCache.load(buildingAssetPath);

      expect(buildingImage.width, 2560);
      expect(buildingImage.height, 2048);
      expect(
        UiImageCache.resolvedAssetPathForTesting(buildingAssetPath),
        buildingAssetPath.replaceFirst('.png', '.webp'),
      );

      final technologyImage = await UiImageCache.load(
        TechnologySpriteCatalog.assetPath,
      );

      expect(technologyImage.width, 2048);
      expect(technologyImage.height, 1792);
      expect(
        UiImageCache.resolvedAssetPathForTesting(
          TechnologySpriteCatalog.assetPath,
        ),
        TechnologySpriteCatalog.assetPath.replaceFirst('.png', '.webp'),
      );

      final cityImage = await HexIconCache.load(CitySpriteCatalog.assetPath);

      expect(cityImage.width, CitySpriteCatalog.sourceImageWidth);
      expect(cityImage.height, CitySpriteCatalog.sourceImageHeight);
      expect(
        HexIconCache.resolvedAssetPathForTesting(CitySpriteCatalog.assetPath),
        CitySpriteCatalog.assetPath,
      );
    });

    test('tightens UI sprite frames around visible frame content', () async {
      final definition = UnitSpriteCatalog.worker;
      final image = await _loadImage(definition.assetPath);
      addTearDown(image.dispose);
      final imageSize = Vector2(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final idle = definition.actionDefinition(UnitSpriteAction.idle);
      final source = definition.sourceRectFor(
        imageSize: imageSize,
        action: idle,
        column: 0,
      );

      final displayFrame = await SpriteAtlasFrameBoundsCache.frameRectFor(
        cacheKey: definition.assetPath,
        image: image,
        columns: definition.columns,
        rows: definition.rows,
        column: 0,
        row: idle.row,
        sourceInset: definition.sourceInset,
        contentPadding: 18,
      );

      expect(displayFrame.left, greaterThan(source.left));
      expect(displayFrame.top, greaterThan(source.top));
      expect(displayFrame.right, source.right);
      expect(displayFrame.bottom, source.bottom);
      expect(displayFrame.width, lessThan(source.width));
      expect(displayFrame.height, lessThan(source.height));
    });

    test('clips animated map unit frames to the authored render box', () async {
      final definition = UnitSpriteCatalog.worker;
      const adjustment = AnimationFrameAdjustment(
        offsetX: 6,
        offsetY: -4,
        cropLeft: 12,
        cropTop: 8,
        cropRight: -24,
        cropBottom: -18,
        scaleX: 1.15,
        scaleY: 1.1,
      );
      AnimationFrameAdjustmentCatalogCache.replace(
        AnimationFrameAdjustmentCatalog(
          frames: {
            AnimationFrameAdjustmentCatalog.frameKey(
              assetPath: definition.assetPath,
              animationId: UnitSpriteAction.idle.name,
              frameIndex: 0,
            ): adjustment,
          },
        ),
      );
      addTearDown(AnimationFrameAdjustmentCatalogCache.clearForTesting);

      final image = await _loadImage(definition.assetPath);
      addTearDown(image.dispose);
      final component = UnitSpriteComponent(definition);
      await component.setImage(image);

      final baseSource = definition.sourceRectFor(
        imageSize: Vector2(image.width.toDouble(), image.height.toDouble()),
        action: definition.actionDefinition(UnitSpriteAction.idle),
        column: 0,
      );
      final baseDestination =
          ui.Offset.zero &
          ui.Size(definition.normalSize.width, definition.normalSize.height);
      final expectedDestination = adjustment
          .adjustedDestinationFor(
            baseSource: baseSource,
            baseDestination: baseDestination,
          )
          .shift(
            adjustment.scaledOffset(
              baseSize: ui.Size(
                definition.normalSize.width,
                definition.normalSize.height,
              ),
              targetSize: baseDestination.size,
            ),
          );
      final geometry = component.renderGeometryForCurrentFrame();

      expect(geometry.source, adjustment.croppedSourceFor(baseSource));
      expect(geometry.destination, expectedDestination);
      expect(geometry.clipRect, baseDestination);
      expect(geometry.destination.right, greaterThan(geometry.clipRect.right));
      expect(
        geometry.destination.bottom,
        greaterThan(geometry.clipRect.bottom),
      );
    });
  });
}

Future<ui.Image> _loadImage(String assetPath) async {
  final bytes = await File(assetPath).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

void _expectSourceInsideCell({
  required ui.Rect source,
  required ui.Rect cell,
  required double inset,
  required String reason,
}) {
  final resolvedInset = SpriteAtlasGeometry.resolvedInsetFor(
    width: cell.width,
    height: cell.height,
    requestedInset: inset,
  );

  expect(source.left, cell.left + resolvedInset, reason: reason);
  expect(source.top, cell.top + resolvedInset, reason: reason);
  expect(source.right, cell.right - resolvedInset, reason: reason);
  expect(source.bottom, cell.bottom - resolvedInset, reason: reason);
  expect(source.left, source.left.roundToDouble(), reason: reason);
  expect(source.top, source.top.roundToDouble(), reason: reason);
  expect(source.right, source.right.roundToDouble(), reason: reason);
  expect(source.bottom, source.bottom.roundToDouble(), reason: reason);
}
