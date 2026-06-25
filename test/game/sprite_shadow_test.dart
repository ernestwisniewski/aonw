import 'package:aonw/game/presentation/engine/rendering_layers/sprite_shadow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpriteShadow color presets', () {
    test(
      'city color is heavier than improvement which is heavier than unit',
      () {
        expect(
          SpriteShadow.cityColor.a,
          greaterThan(SpriteShadow.improvementColor.a),
        );
        expect(
          SpriteShadow.improvementColor.a,
          greaterThan(SpriteShadow.unitColor.a),
        );
      },
    );

    test('city color is 0x66000000', () {
      expect(SpriteShadow.cityColor.toARGB32(), 0x66000000);
    });

    test('improvement color is 0x5A000000', () {
      expect(SpriteShadow.improvementColor.toARGB32(), 0x5A000000);
    });

    test('unit color is unchanged 0x50000000', () {
      expect(SpriteShadow.unitColor.toARGB32(), 0x50000000);
    });
  });

  group('SpriteShadow.cityRect', () {
    test('produces a 60x14 ellipse centered 2px below the sprite bottom', () {
      const bottom = Offset(100, 200);
      final rect = SpriteShadow.cityRect(spriteBottomCenter: bottom);

      expect(rect.width, 60);
      expect(rect.height, 14);
      expect(rect.center.dx, 100);
      expect(rect.center.dy, 202);
    });
  });

  group('SpriteShadow.improvementRect', () {
    test('produces a 38x10 ellipse centered 2px below the sprite bottom', () {
      const bottom = Offset(50, 80);
      final rect = SpriteShadow.improvementRect(spriteBottomCenter: bottom);

      expect(rect.width, 38);
      expect(rect.height, 10);
      expect(rect.center.dx, 50);
      expect(rect.center.dy, 82);
    });
  });

  group('SpriteShadow.unitRect', () {
    test('returns the existing 24x8 normal preset', () {
      final rect = SpriteShadow.unitRect(
        center: const Offset(0, 0),
        onCity: false,
      );
      expect(rect.width, 24);
      expect(rect.height, 8);
    });
  });

  group('SpriteShadow.paint3d geometry', () {
    test('adds a larger down-right cast shadow behind the base ellipse', () {
      final base = SpriteShadow.unitRect(
        center: const Offset(16, 16),
        onCity: false,
      );
      final cast = SpriteShadow.castRectForTesting(base);

      expect(cast.width, greaterThan(base.width));
      expect(cast.height, greaterThan(base.height));
      expect(cast.center.dx, greaterThan(base.center.dx));
      expect(cast.center.dy, greaterThan(base.center.dy));
    });

    test('keeps the darkest contact shadow compact under the sprite', () {
      final base = SpriteShadow.cityRect(
        spriteBottomCenter: const Offset(100, 200),
      );
      final contact = SpriteShadow.contactRectForTesting(base);

      expect(contact.width, lessThan(base.width));
      expect(contact.height, lessThan(base.height));
      expect(contact.center.dx, base.center.dx);
      expect(contact.center.dy, greaterThan(base.center.dy));
    });

    test('uses softer outer alpha and stronger contact alpha', () {
      final cast = SpriteShadow.castColorForTesting(SpriteShadow.cityColor);
      final ambient = SpriteShadow.ambientColorForTesting(
        SpriteShadow.cityColor,
      );
      final contact = SpriteShadow.contactColorForTesting(
        SpriteShadow.cityColor,
      );

      expect(cast.a, lessThan(ambient.a));
      expect(ambient.a, lessThan(SpriteShadow.cityColor.a));
      expect(contact.a, greaterThan(SpriteShadow.cityColor.a));
    });
  });
}
