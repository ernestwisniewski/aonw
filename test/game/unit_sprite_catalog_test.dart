import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite_catalog.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitSpriteCatalog', () {
    test('maps available unit types to sprite asset definitions', () {
      for (final unitType in GameUnitType.values) {
        expect(
          UnitSpriteCatalog.definitionFor(unitType),
          isNotNull,
          reason: '${unitType.name} should have a sprite definition',
        );
      }
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.commander)?.assetPath,
        'assets/sprites/units/commander.png',
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.warrior)?.assetPath,
        'assets/sprites/units/warrior.png',
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.settler)?.assetPath,
        'assets/sprites/units/settler.png',
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.worker)?.assetPath,
        'assets/sprites/units/worker.png',
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.merchant)?.assetPath,
        'assets/sprites/units/merchant.png',
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.archer)?.assetPath,
        'assets/sprites/units/archer.png',
      );
      expect(
        UnitSpriteCatalog.definitionFor(GameUnitType.tank)?.assetPath,
        'assets/sprites/units/tank.png',
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
      expect(settlerWork.row, 2);
      expect(settlerWork.frameDuration, closeTo(0.22, 0.0001));
      expect(
        UnitSpriteCatalog.worker.actions,
        isNot(contains(UnitSpriteAction.attack)),
      );
      expect(work.row, 2);
      expect(work.frameDuration, closeTo(0.22, 0.0001));
      expect(
        UnitSpriteCatalog.merchant.actions,
        isNot(contains(UnitSpriteAction.attack)),
      );
      expect(merchantWork.row, 2);
      expect(merchantWork.frameDuration, closeTo(0.22, 0.0001));
    });

    test('insets atlas source frames to avoid neighboring sprite bleed', () {
      final definition = UnitSpriteCatalog.worker;
      final imageSize = Vector2(3264, 3264);
      final idle = definition.actionDefinition(UnitSpriteAction.idle);

      expect(
        definition.sourcePositionFor(
          imageSize: imageSize,
          action: idle,
          column: 0,
        ),
        Vector2(2, 2),
      );
      expect(definition.sourceSizeFor(imageSize), Vector2(540, 812));
    });
  });
}
