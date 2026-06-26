import 'dart:io';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildingSpriteCatalog', () {
    test('maps current building enum order to three generated atlas grids', () {
      expect(BuildingSpriteCatalog.columns, 5);
      expect(BuildingSpriteCatalog.rows, 4);
      expect(BuildingSpriteCatalog.slotsPerAtlas, 20);
      expect(BuildingSpriteCatalog.assetPaths, hasLength(3));

      final granary = BuildingSpriteCatalog.iconFor(CityBuildingType.granary);
      expect(granary.assetPath, BuildingSpriteCatalog.assetPaths[0]);
      expect(granary.column, 0);
      expect(granary.row, 0);

      final port = BuildingSpriteCatalog.iconFor(CityBuildingType.port);
      expect(port.assetPath, BuildingSpriteCatalog.assetPaths[0]);
      expect(port.column, 4);
      expect(port.row, 1);
      expect(
        BuildingSpriteCatalog.iconFor(CityBuildingType.port).sourceInset,
        0,
      );
      expect(
        BuildingSpriteCatalog.iconFor(CityBuildingType.port).adjustmentId,
        isNull,
      );
      expect(
        BuildingSpriteCatalog.iconFor(CityBuildingType.granary).cropToContent,
        isFalse,
      );

      final aqueduct = BuildingSpriteCatalog.iconFor(CityBuildingType.aqueduct);
      expect(aqueduct.assetPath, BuildingSpriteCatalog.assetPaths[0]);
      expect(aqueduct.column, 0);
      expect(aqueduct.row, 2);

      final monument = BuildingSpriteCatalog.iconFor(CityBuildingType.monument);
      expect(monument.assetPath, BuildingSpriteCatalog.assetPaths[0]);
      expect(monument.column, 4);
      expect(monument.row, 3);

      final archive = BuildingSpriteCatalog.iconFor(CityBuildingType.archive);
      expect(archive.assetPath, BuildingSpriteCatalog.assetPaths[1]);
      expect(archive.column, 0);
      expect(archive.row, 0);

      final warCollege = BuildingSpriteCatalog.iconFor(
        CityBuildingType.warCollege,
      );
      expect(warCollege.assetPath, BuildingSpriteCatalog.assetPaths[1]);
      expect(warCollege.column, 4);
      expect(warCollege.row, 3);

      final conscriptionOffice = BuildingSpriteCatalog.iconFor(
        CityBuildingType.conscriptionOffice,
      );
      expect(conscriptionOffice.assetPath, BuildingSpriteCatalog.assetPaths[2]);
      expect(conscriptionOffice.column, 0);
      expect(conscriptionOffice.row, 0);

      final worldFairGrounds = BuildingSpriteCatalog.iconFor(
        CityBuildingType.worldFairGrounds,
      );
      expect(worldFairGrounds.assetPath, BuildingSpriteCatalog.assetPaths[2]);
      expect(worldFairGrounds.column, 3);
      expect(worldFairGrounds.row, 3);
    });

    test('does not use asset adjustment ids for building icons', () {
      final data = BuildingSpriteCatalog.iconFor(CityBuildingType.granary);
      final catalog = const AnimationFrameAdjustmentCatalog.empty().withFrame(
        assetPath: data.assetPath,
        animationId: 'building.granary',
        frameIndex: 0,
        adjustment: const AnimationFrameAdjustment(cropLeft: 4),
      );

      expect(data.adjustmentId, isNull);
      expect(data.adjustmentFor(catalog), const AnimationFrameAdjustment());
    });
  });

  group('TechnologySpriteCatalog', () {
    test('uses prompt order instead of TechnologyId enum order', () {
      expect(
        TechnologySpriteCatalog.assetPath,
        'assets/sprites/technologies_atlas_8x7_512.png',
      );
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.agriculture).column,
        0,
      );
      expect(TechnologySpriteCatalog.iconFor(TechnologyId.agriculture).row, 0);
      expect(TechnologySpriteCatalog.iconFor(TechnologyId.mining).column, 1);
      expect(TechnologySpriteCatalog.iconFor(TechnologyId.mining).row, 0);
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.mining).sourceInset,
        2.0,
      );
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.mining).adjustmentId,
        isNull,
      );
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.agriculture).cropToContent,
        isFalse,
      );
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.woodworking).column,
        3,
      );
      expect(TechnologySpriteCatalog.iconFor(TechnologyId.woodworking).row, 0);
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.ironWorking).column,
        7,
      );
      expect(TechnologySpriteCatalog.iconFor(TechnologyId.ironWorking).row, 2);
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.specialization).column,
        7,
      );
      expect(
        TechnologySpriteCatalog.iconFor(TechnologyId.specialization).row,
        3,
      );
    });

    test('does not use asset adjustment ids for technology icons', () {
      final data = TechnologySpriteCatalog.iconFor(TechnologyId.agriculture);
      final catalog = const AnimationFrameAdjustmentCatalog.empty().withFrame(
        assetPath: TechnologySpriteCatalog.assetPath,
        animationId: 'technology.agriculture',
        frameIndex: 0,
        adjustment: const AnimationFrameAdjustment(offsetY: -3),
      );

      expect(data.adjustmentId, isNull);
      expect(data.adjustmentFor(catalog), const AnimationFrameAdjustment());
    });
  });

  group('FieldImprovementSpriteCatalog', () {
    test('uses prompt order instead of FieldImprovementType enum order', () {
      expect(
        FieldImprovementSpriteCatalog.rowForType(FieldImprovementType.farm),
        0,
      );
      expect(
        FieldImprovementSpriteCatalog.rowForType(
          FieldImprovementType.riverFarm,
        ),
        1,
      );
      expect(
        FieldImprovementSpriteCatalog.rowForType(FieldImprovementType.orchard),
        2,
      );
      expect(
        FieldImprovementSpriteCatalog.rowForType(FieldImprovementType.mine),
        3,
      );
      expect(
        FieldImprovementSpriteCatalog.rowForType(
          FieldImprovementType.uraniumMine,
        ),
        18,
      );
    });

    test('maps improvement types to restored source sheets', () {
      expect(
        FieldImprovementSpriteCatalog.assetPathFor(FieldImprovementType.farm),
        'assets/sprites/improvements1.jpg',
      );
      expect(
        FieldImprovementSpriteCatalog.assetPathFor(FieldImprovementType.mine),
        'assets/sprites/improvements2.jpg',
      );
      expect(
        FieldImprovementSpriteCatalog.assetPathFor(
          FieldImprovementType.uraniumMine,
        ),
        'assets/sprites/improvements4.jpg',
      );
      expect(
        FieldImprovementSpriteCatalog.sheetColumnForType(
          FieldImprovementType.uraniumMine,
        ),
        3,
      );
    });

    test('uses asset adjustment ids for field improvements', () {
      final assetPath = FieldImprovementSpriteCatalog.assetPathFor(
        FieldImprovementType.farm,
      );
      final catalog = const AnimationFrameAdjustmentCatalog.empty().withFrame(
        assetPath: assetPath,
        animationId: 'field-improvement.farm.era-2',
        frameIndex: 0,
        adjustment: const AnimationFrameAdjustment(offsetY: -3),
      );

      expect(
        catalog.adjustmentFor(
          assetPath: assetPath,
          animationId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
            type: FieldImprovementType.farm,
            eraColumn: 2,
          ),
          frameIndex: 0,
        ),
        const AnimationFrameAdjustment(offsetY: -3),
      );
    });
  });

  group('Sprite icon renderer', () {
    test(
      'UI widgets use sprite-specific factories instead of raw atlas icons',
      () {
        final allowedRawAtlasFiles = {
          'lib/game/presentation/widgets/theme/building_sprite_catalog.dart',
          'lib/game/presentation/widgets/theme/city_sprite_icon.dart',
          'lib/game/presentation/widgets/theme/field_improvement_sprite_icon.dart',
          'lib/game/presentation/widgets/theme/sprite_atlas_icon.dart',
          'lib/game/presentation/widgets/theme/technology_sprite_catalog.dart',
          'lib/game/presentation/widgets/theme/unit_sprite_icon.dart',
        };
        final offenders = <String>[];

        for (final file in Directory(
          'lib/game/presentation/widgets',
        ).listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          if (allowedRawAtlasFiles.contains(file.path)) continue;
          if (file.readAsStringSync().contains('SpriteAtlasIcon(')) {
            offenders.add(file.path);
          }
        }

        expect(offenders, isEmpty);
      },
    );

    testWidgets('unit icons use the shared centered atlas renderer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: UnitSpriteIcon(type: GameUnitType.worker, size: 48, column: 2),
        ),
      );

      final atlas = tester.widget<SpriteAtlasIcon>(
        find.byType(SpriteAtlasIcon),
      );
      expect(atlas.alignment, Alignment.center);
      expect(atlas.fit, BoxFit.contain);
      expect(atlas.data?.adjustmentId, 'idle');
      expect(atlas.data?.adjustmentFrameIndex, 2);
    });
  });
}
