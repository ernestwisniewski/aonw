import 'package:flutter/material.dart';

/// Single source of RGB values for HUD/UI/Flame canvas.
///
/// Adding a color here is the only legal way to introduce a new color into
/// the game's UI surface. `GameUiTheme` re-exports these. Architecture tests
/// fail if literal `Color(0xFF...)` appears outside this file (with a small
/// whitelist for typography defaults).
abstract final class HudPalette {
  // Backgrounds (warm dark navy).
  static const Color bg = Color(0xFF0A0A0E);
  static const Color surface = Color(0xFF101620);
  static const Color surfaceDeep = Color(0xFF1A2030);
  static const Color chipSurface = Color(0xFF1E2738);
  static const Color chipSurfaceDim = Color(0xFF27384C);
  static const Color card = Color(0xFF131B26);
  static const Color cardAccent = Color(0xFF1E2738);

  // Gold (warm).
  static const Color gold = Color(0xFFD2A856);
  static const Color goldLight = Color(0xFFF0DCAE);
  static const Color goldDark = Color(0xFF8C6926);

  // Copper (hover/glow).
  static const Color copper = Color(0xFFB47A4E);
  static const Color copperDeep = Color(0xFF7A4A28);

  // Semantic.
  static const Color success = Color(0xFF6CC07A);
  static const Color successLight = Color(0xFFC9F4B9);
  static const Color successDim = Color(0xFF3F7A4B);
  static const Color successSubtle = Color(0xFF223B2A);
  static const Color warning = Color(0xFFF0C36A);
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerSubtle = Color(0xFF5A2425);
  static const Color info = Color(0xFF6FA8D6);

  // Domain accents.
  static const Color scienceAccent = Color(0xFF9FC7B5);
  static const Color resourcesAccent = Color(0xFFD6A56B);
  static const Color sectionLabel = Color(0xFF8C6926);
  static const Color tradeRoute = Color(0xFFB7C0C6);
  static const Color tradeRouteGlow = Color(0xFF6D7780);

  // Text.
  static const Color textPrimary = Color(0xFFF0EDE6);
  static const Color textSecondary = Color(0xFFA0A5B2);
  static const Color textTertiary = Color(0xFF747787);
  static const Color textBright = Color(0xFFF8F2E4);
  static const Color textMuted = Color(0xFFEBD9B0);
}
