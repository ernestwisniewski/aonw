import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

/// Semantic tones for chips, pills, badges, and small HUD labels.
enum ChipTone {
  neutral,
  accent,
  warning,
  danger,
  success;

  ChipToneSpec get spec => switch (this) {
    ChipTone.neutral => ChipToneSpec(
      background: HudPalette.surface.withAlpha(96),
      border: HudPalette.textSecondary.withAlpha(110),
      foreground: HudPalette.textSecondary,
    ),
    ChipTone.accent => ChipToneSpec(
      background: HudPalette.surface.withAlpha(96),
      border: HudPalette.goldLight.withAlpha(110),
      foreground: HudPalette.goldLight,
    ),
    ChipTone.warning => ChipToneSpec(
      background: HudPalette.surface.withAlpha(96),
      border: HudPalette.warning.withAlpha(135),
      foreground: HudPalette.warning,
    ),
    ChipTone.danger => ChipToneSpec(
      background: HudPalette.surface.withAlpha(96),
      border: HudPalette.danger.withAlpha(135),
      foreground: HudPalette.danger,
    ),
    ChipTone.success => ChipToneSpec(
      background: HudPalette.surface.withAlpha(96),
      border: HudPalette.success.withAlpha(135),
      foreground: HudPalette.success,
    ),
  };
}

class ChipToneSpec {
  const ChipToneSpec({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
