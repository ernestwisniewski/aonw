import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SurfaceElevation', () {
    test('flat resolves to the quiet surface treatment', () {
      final decoration = SurfaceElevation.flat.decoration();

      expect(decoration.color, HudPalette.surface.withAlpha(210));
      expect(decoration.border, isA<Border>());
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.first.blurRadius, 12);
    });

    test('raised resolves to the primary panel treatment', () {
      final decoration = SurfaceElevation.raised.decoration();

      expect(decoration.color, HudPalette.surface.withAlpha(230));
      expect(decoration.boxShadow!.first.blurRadius, 18);
    });

    test('floating resolves to the old pill/floating surface treatment', () {
      final decoration = SurfaceElevation.floating.decoration();

      expect(decoration.color, HudPalette.bg.withAlpha(215));
    });

    test('modal resolves to the active emphasized treatment', () {
      final decoration = SurfaceElevation.modal.decoration(
        glowColor: HudPalette.copper,
      );

      expect(decoration.color, HudPalette.gold.withAlpha(235));
      expect(decoration.boxShadow!.length, 2);
    });

    test('decoration accepts shape and border emphasis overrides', () {
      final decoration = SurfaceElevation.flat.decoration(
        shape: SurfaceShape.pill,
        border: BorderEmphasis.strong,
      );
      final border = decoration.border! as Border;

      expect(decoration.borderRadius, SurfaceShape.pill.borderRadius);
      expect(border.top.color, HudPalette.gold.withAlpha(160));
    });

    test('decoration accepts accent color override', () {
      final decoration = SurfaceElevation.flat.decoration(
        accent: HudPalette.warning,
      );
      final border = decoration.border! as Border;

      expect(border.top.color, HudPalette.warning.withAlpha(60));
    });

    test('decoration without shadow drops boxShadow', () {
      final decoration = SurfaceElevation.flat.decoration(includeShadow: false);

      expect(decoration.boxShadow, isNull);
    });

    test('gradient fill clears solid color', () {
      final decoration = SurfaceElevation.raised.decoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF111111)],
        ),
      );

      expect(decoration.color, isNull);
      expect(decoration.gradient, isA<LinearGradient>());
    });

    test(
      'fill returns the surface background with default or custom alpha',
      () {
        expect(SurfaceElevation.flat.fill(), HudPalette.surface.withAlpha(210));
        expect(
          SurfaceElevation.flat.fill(alpha: 100),
          HudPalette.surface.withAlpha(100),
        );
      },
    );

    test('strokeColor and shadows expose non-decoration primitives', () {
      expect(
        SurfaceElevation.flat.strokeColor(
          accent: HudPalette.copper,
          border: BorderEmphasis.active,
        ),
        HudPalette.copper.withAlpha(220),
      );

      final shadows = SurfaceElevation.modal.shadows(
        glowColor: HudPalette.copper,
        glowAlpha: 80,
      );
      expect(shadows.length, 2);
      expect(shadows[1].color, HudPalette.copper.withAlpha(80));
    });

    test('bandDecoration applies a tokenized bottom border', () {
      final decoration = SurfaceElevation.raised.bandDecoration(
        borderColor: HudPalette.gold,
        border: BorderEmphasis.regular,
      );
      final border = decoration.border! as Border;

      expect(decoration.color, HudPalette.surface.withAlpha(230));
      expect(border.bottom.color, HudPalette.gold.withAlpha(110));
      expect(border.top, BorderSide.none);
    });
  });
}
