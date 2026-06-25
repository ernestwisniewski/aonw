import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/chip_tone.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HudPaint surface mirrors SurfaceElevation fill tokens', () {
    final paint = HudPaint.surface(SurfaceElevation.raised);

    expect(paint.style, PaintingStyle.fill);
    expect(paint.color.toARGB32(), SurfaceElevation.raised.fill().toARGB32());
  });

  test('HudPaint border applies border emphasis alpha', () {
    final paint = HudPaint.border(
      BorderEmphasis.strong,
      color: HudPalette.warning,
      strokeWidth: 2,
    );

    expect(paint.style, PaintingStyle.stroke);
    expect(paint.strokeWidth, 2);
    expect(
      paint.color.toARGB32(),
      HudPalette.warning.withAlpha(160).toARGB32(),
    );
  });

  test('HudPaint accent uses chip tone foreground with explicit alpha', () {
    final paint = HudPaint.accent(ChipTone.success, alpha: 38);

    expect(
      paint.color.toARGB32(),
      ChipTone.success.spec.foreground.withAlpha(38).toARGB32(),
    );
  });

  test('HudPaint colorFilter creates reusable filter paint', () {
    final paint = HudPaint.colorFilter(HudPalette.textBright, alpha: 72);

    expect(paint.colorFilter, isNotNull);
  });

  test('HudPaint matrixColorFilter creates reusable filter paint', () {
    final paint = HudPaint.matrixColorFilter(const [
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);

    expect(paint.colorFilter, isNotNull);
  });
}
