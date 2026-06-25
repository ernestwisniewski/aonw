import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudPalette', () {
    test('exposes warm-theme RGB values from spec 2026-05-06', () {
      expect(HudPalette.bg, const Color(0xFF0A0A0E));
      expect(HudPalette.surface, const Color(0xFF101620));
      expect(HudPalette.surfaceDeep, const Color(0xFF1A2030));
      expect(HudPalette.gold, const Color(0xFFD2A856));
      expect(HudPalette.goldLight, const Color(0xFFF0DCAE));
      expect(HudPalette.copper, const Color(0xFFB47A4E));
      expect(HudPalette.copperDeep, const Color(0xFF7A4A28));
      expect(HudPalette.success, const Color(0xFF6CC07A));
      expect(HudPalette.successLight, const Color(0xFFC9F4B9));
      expect(HudPalette.warning, const Color(0xFFF0C36A));
      expect(HudPalette.danger, const Color(0xFFC0392B));
    });

    test('text colors match warm-theme spec', () {
      expect(HudPalette.textPrimary, const Color(0xFFF0EDE6));
      expect(HudPalette.textSecondary, const Color(0xFFA0A5B2));
      expect(HudPalette.textBright, const Color(0xFFF8F2E4));
    });
  });
}
