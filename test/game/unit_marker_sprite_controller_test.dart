import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_sprite_controller.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitMarkerSpriteController', () {
    test('swaps sprite availability when unit type changes', () {
      final controller = UnitMarkerSpriteController(GameUnitType.commander);

      expect(controller.hasSpriteAsset, isTrue);
      expect(controller.currentColumn, 0);

      expect(controller.setUnitType(GameUnitType.archer), isTrue);
      expect(controller.hasSpriteAsset, isTrue);
      expect(controller.currentColumn, 0);

      expect(controller.setUnitType(GameUnitType.worker), isTrue);
      expect(controller.hasSpriteAsset, isTrue);
      controller.playWork();
      expect(controller.action, UnitSpriteAction.work);
    });

    test('keeps direction and advances idle inside sprite controller', () {
      final controller = UnitMarkerSpriteController(GameUnitType.commander);
      int columnAfter(VoidCallback command) {
        command();
        return controller.currentColumn;
      }

      expect(
        columnAfter(
          () => controller.playWalkToward(
            from: Vector2.zero(),
            to: Vector2(10, 0),
          ),
        ),
        0,
      );
      expect(columnAfter(controller.playIdle), 0);
      expect(columnAfter(() => controller.update(0.55)), 0);
      expect(columnAfter(() => controller.update(0.20)), 0);
      expect(columnAfter(() => controller.update(0.15)), 1);
    });
  });
}
