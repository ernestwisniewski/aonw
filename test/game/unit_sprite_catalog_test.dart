import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite_catalog.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitSpriteCatalog', () {
    test('maps available unit types to semantic sprite definitions', () {
      for (final unitType in GameUnitType.values) {
        final definition = UnitSpriteCatalog.definitionFor(unitType);
        expect(definition, isNotNull);
        expect(definition!.spriteName, unitType.name);
      }
      expect(
        UnitSpriteCatalog.commander
            .sequenceIdFor(UnitSpriteAction.walk)
            .frame(5)
            .value,
        'unit.commander.walk.5',
      );
      expect(UnitSpriteCatalog.commander.normalSize.width, 64);
      expect(UnitSpriteCatalog.commander.normalSize.height, 86);
      expect(UnitSpriteCatalog.commander.smallSize.width, 42);
      expect(UnitSpriteCatalog.commander.smallSize.height, 57);
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.tank)?.normalSize.width,
        76,
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.tank)?.normalSize.height,
        72,
      );
      expect(
        UnitSpriteCatalog.definitions.keys,
        containsAll(GameUnitType.values),
      );
      expect(
        UnitSpriteCatalog.commander
            .actionDefinition(UnitSpriteAction.idle)
            .frameDuration,
        closeTo(0.9, 0.0001),
      );
      expect(
        UnitSpriteCatalog.worker
            .actionDefinition(UnitSpriteAction.idle)
            .frameDuration,
        closeTo(0.9, 0.0001),
      );
    });

    test('keeps civilian-specific work animation definition', () {
      final settlerWork = UnitSpriteCatalog.settler.actionDefinition(
        UnitSpriteAction.work,
      );
      final work = UnitSpriteCatalog.worker.actionDefinition(
        UnitSpriteAction.work,
      );
      final merchantWork = UnitSpriteCatalog.merchant.actionDefinition(
        UnitSpriteAction.work,
      );

      expect(
        UnitSpriteCatalog.settler.actions,
        isNot(contains(UnitSpriteAction.attack)),
      );
      expect(settlerWork.frameDuration, closeTo(0.22, 0.0001));
      expect(
        UnitSpriteCatalog.worker.actions,
        isNot(contains(UnitSpriteAction.attack)),
      );
      expect(work.frameDuration, closeTo(0.22, 0.0001));
      expect(
        UnitSpriteCatalog.merchant.actions,
        isNot(contains(UnitSpriteAction.attack)),
      );
      expect(merchantWork.frameDuration, closeTo(0.22, 0.0001));
    });

    test('matches every generated animation row and column to its source', () {
      final source =
          jsonDecode(
                File(
                  'tool/assets/asset_source_manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final generated =
          jsonDecode(
                File(
                  'assets/runtime/sprites/sprite_manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final generatedFrames = generated['frames'] as Map<String, dynamic>;

      for (final value in source['units'] as List<dynamic>) {
        final spec = value as Map<String, dynamic>;
        final name = spec['name'] as String;
        final rows = spec['rows'] as int;
        final animations = (spec['animations'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final unitType = GameUnitType.values.singleWhere(
          (type) => type.name == name,
        );
        final definition = UnitSpriteCatalog.definitionFor(unitType)!;

        expect(
          animations.map((animation) => animation['row']).toSet().length,
          lessThanOrEqualTo(rows),
          reason: name,
        );
        expect(
          definition.actions.keys.map((action) => action.name).toList(),
          animations.map((animation) => animation['action']).toList(),
          reason: '$name must retain its legacy animation row order',
        );
        for (final animation in animations) {
          final actionName = animation['action'] as String;
          final row = animation['row'] as int;
          final sourceColumns = (animation['sourceColumns'] as List<dynamic>)
              .cast<int>();
          final action = UnitSpriteAction.values.byName(actionName);
          expect(
            definition.actionDefinition(action).frameCount,
            sourceColumns.length,
          );
          for (
            var frameIndex = 0;
            frameIndex < sourceColumns.length;
            frameIndex++
          ) {
            final sourceColumn = sourceColumns[frameIndex];
            final id = 'unit.$name.$actionName.$frameIndex';
            final frame = generatedFrames[id] as Map<String, dynamic>?;
            expect(frame, isNotNull, reason: 'missing $id');
            expect(frame!['grid'], [sourceColumn, row], reason: id);
            expect(frame['index'], frameIndex, reason: id);
          }
        }
      }
    });
  });
}
