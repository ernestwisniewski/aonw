import 'package:aonw/shared/theme/chip_tone.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChipTone', () {
    test('neutral resolves to the subdued text palette', () {
      final spec = ChipTone.neutral.spec;

      expect(spec.foreground, HudPalette.textSecondary);
      expect(spec.background, HudPalette.surface.withAlpha(96));
      expect(spec.border, HudPalette.textSecondary.withAlpha(110));
    });

    test('accent resolves to gold-light foreground', () {
      expect(ChipTone.accent.spec.foreground, HudPalette.goldLight);
    });

    test('semantic tones use semantic foreground colors', () {
      expect(ChipTone.warning.spec.foreground, HudPalette.warning);
      expect(ChipTone.danger.spec.foreground, HudPalette.danger);
      expect(ChipTone.success.spec.foreground, HudPalette.success);
    });

    test('every tone exposes background, border, and foreground colors', () {
      for (final tone in ChipTone.values) {
        expect(tone.spec.background, isA<Color>());
        expect(tone.spec.border, isA<Color>());
        expect(tone.spec.foreground, isA<Color>());
      }
    });
  });
}
