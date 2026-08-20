import 'dart:io';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/sprite_atlas_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/wonder_sprite_catalog.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('semantic sprite catalogs', () {
    test('maps every building to its stable frame ID', () {
      for (final type in CityBuildingType.values) {
        final data = BuildingSpriteCatalog.iconFor(type);
        expect(data.frameId.value, 'building.${type.name}');
        expect(data.cropToContent, isFalse);
        expect(data.adjustmentSequenceId, isNull);
      }
    });

    test('maps every technology to its stable frame ID', () {
      for (final id in TechnologyId.values) {
        final data = TechnologySpriteCatalog.iconFor(id);
        expect(data.frameId.value, 'technology.${id.name}');
        expect(data.cropToContent, isFalse);
        expect(data.adjustmentSequenceId, isNull);
      }
    });

    test('maps every wonder to its stable frame ID', () {
      for (final type in WonderType.values) {
        final data = WonderSpriteCatalog.iconFor(type);
        expect(data.frameId.value, 'wonder.${type.name}');
        expect(data.cropToContent, isFalse);
        expect(data.adjustmentSequenceId, isNull);
      }
    });

    test('maps every improvement and era to a named generated frame', () {
      for (final type in FieldImprovementType.values) {
        for (var era = 0; era < FieldImprovementSpriteCatalog.columns; era++) {
          final frameId = FieldImprovementSpriteCatalog.frameIdFor(
            type: type,
            eraColumn: era,
          );
          expect(frameId.value, 'improvement.${type.name}.$era');
          expect(
            FieldImprovementSpriteCatalog.sequenceIdFor(
              type: type,
              eraColumn: era,
            ).value,
            frameId.value,
          );
        }
      }
    });

    test('uses semantic adjustments without path-dependent aliases', () {
      const sequence = SpriteSequenceId('improvement.farm.2');
      final catalog = const AnimationFrameAdjustmentCatalog.empty().withFrame(
        sequenceId: sequence,
        frameIndex: 0,
        adjustment: const AnimationFrameAdjustment(offsetY: -3),
      );
      const data = SpriteAtlasIconData(
        frameId: SpriteFrameId('improvement.farm.2'),
        adjustmentSequenceId: sequence,
      );

      expect(
        data.adjustmentFor(catalog),
        const AnimationFrameAdjustment(offsetY: -3),
      );
    });
  });

  group('Sprite icon renderer', () {
    test('UI widgets use sprite-specific factories', () {
      final allowedRawAtlasFiles = {
        'lib/game/presentation/widgets/theme/building_sprite_catalog.dart',
        'lib/game/presentation/widgets/theme/city_sprite_icon.dart',
        'lib/game/presentation/widgets/theme/field_improvement_sprite_icon.dart',
        'lib/game/presentation/widgets/theme/sprite_atlas_icon.dart',
        'lib/game/presentation/widgets/theme/technology_sprite_catalog.dart',
        'lib/game/presentation/widgets/theme/unit_sprite_icon.dart',
        'lib/game/presentation/widgets/theme/wonder_sprite_catalog.dart',
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
    });

    testWidgets('unit icons preserve requested row and column semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: UnitSpriteIcon(
            type: GameUnitType.worker,
            size: 48,
            row: 2,
            column: 2,
          ),
        ),
      );

      final atlas = tester.widget<SpriteAtlasIcon>(
        find.byType(SpriteAtlasIcon),
      );
      expect(atlas.alignment, Alignment.center);
      expect(atlas.fit, BoxFit.contain);
      expect(atlas.data?.frameId.value, 'unit.worker.work.2');
      expect(atlas.data?.adjustmentSequenceId?.value, 'unit.worker.work');
      expect(atlas.data?.adjustmentFrameIndex, 2);
    });
  });
}
