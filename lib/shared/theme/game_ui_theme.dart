import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

abstract final class GameUiTheme {
  static const String headingFont = 'Cinzel';
  static const String bodyFont = 'Lato';

  static const Color bg = HudPalette.bg;
  static const Color surface = HudPalette.surface;
  static const Color surfaceDeep = HudPalette.surfaceDeep;
  static const Color chipSurface = HudPalette.chipSurface;
  static const Color chipSurfaceDim = HudPalette.chipSurfaceDim;
  static const Color card = HudPalette.card;
  static const Color cardAccent = HudPalette.cardAccent;
  static const Color border = HudPalette.gold;
  static const Color accent = HudPalette.gold;
  static const Color accentLight = HudPalette.goldLight;
  static const Color accentDark = HudPalette.goldDark;
  static const Color gold = HudPalette.gold;
  static const Color goldLight = HudPalette.goldLight;
  static const Color goldDark = HudPalette.goldDark;
  static const Color copper = HudPalette.copper;
  static const Color copperDeep = HudPalette.copperDeep;
  static const Color danger = HudPalette.danger;
  static const Color dangerSubtle = HudPalette.dangerSubtle;
  static const Color warning = HudPalette.warning;
  static const Color success = HudPalette.success;
  static const Color successDim = HudPalette.successDim;
  static const Color successSubtle = HudPalette.successSubtle;
  static const Color info = HudPalette.info;
  static const Color scienceAccent = HudPalette.scienceAccent;
  static const Color resourcesAccent = HudPalette.resourcesAccent;
  static const Color sectionLabel = HudPalette.sectionLabel;
  static const Color textPrimary = HudPalette.textPrimary;
  static const Color textSecondary = HudPalette.textSecondary;
  static const Color textTertiary = HudPalette.textTertiary;
  static const Color textBright = HudPalette.textBright;
  static const Color textMuted = HudPalette.textMuted;

  static const double radiusFrame = 2;
  static const double radiusCard = 10;
  static const double radiusPill = 999;
  static const double radiusChip = 14;
  static const double radiusButton = 12;

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static const TextStyle screenTitle = TextStyle(
    color: goldLight,
    fontFamily: headingFont,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  static const TextStyle brandTitle = TextStyle(
    color: gold,
    fontFamily: headingFont,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  static const TextStyle brandSubtitle = TextStyle(
    color: goldLight,
    fontFamily: headingFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static const TextStyle labelSmall = TextStyle(
    color: gold,
    fontFamily: headingFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle toolbarLabel = TextStyle(
    color: Color(0xB4EBD9B0),
    fontFamily: headingFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    fontFeatures: tabularFigures,
  );

  static const TextStyle chipLabel = TextStyle(
    color: textSecondary,
    fontFamily: bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle sectionHeader = TextStyle(
    color: gold,
    fontFamily: headingFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle bodySmall = TextStyle(
    color: textSecondary,
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle body = TextStyle(
    color: textSecondary,
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle bodyStrong = TextStyle(
    color: textPrimary,
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle cardTitle = TextStyle(
    color: goldLight,
    fontFamily: headingFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle cardMeta = TextStyle(
    color: textSecondary,
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle actionLabel = TextStyle(
    fontFamily: headingFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle menuButton = TextStyle(
    fontFamily: headingFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static const TextStyle inputText = TextStyle(
    color: textPrimary,
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  static BorderRadius get frameBorderRadius =>
      BorderRadius.circular(radiusFrame);

  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);

  static BorderRadius get pillBorderRadius => BorderRadius.circular(radiusPill);

  static BorderRadius get chipBorderRadius => BorderRadius.circular(radiusChip);

  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(radiusButton);

  static BorderRadius get borderRadius => cardBorderRadius;

  static LinearGradient panelSurfaceGradient() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101620), Color(0xFF1A1A1F)],
  );

  static LinearGradient surfaceOverlayGradient({
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
    int topAlpha = 232,
    int bottomAlpha = 192,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [surface.withAlpha(topAlpha), surface.withAlpha(bottomAlpha)],
    );
  }

  static ButtonStyle textButtonStyle({
    Color foreground = textSecondary,
    EdgeInsetsGeometry? padding,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foreground,
      padding: padding,
      textStyle: actionLabel,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );
  }

  static ButtonStyle outlinedButtonStyle({
    Color foreground = textSecondary,
    EdgeInsetsGeometry? padding,
  }) {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: gold),
      foregroundColor: foreground,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: actionLabel,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );
  }

  static ButtonStyle primaryButtonStyle({
    Color background = gold,
    Color foreground = bg,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withAlpha(80),
      elevation: 0,
      textStyle: menuButton,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );
  }

  static InputDecoration textFieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textSecondary),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: textSecondary),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: textPrimary),
      ),
    );
  }
}

abstract final class GameMotion {
  static const Duration snap = Duration(milliseconds: 120);
  static const Duration fade = Duration(milliseconds: 200);
  static const Duration slide = Duration(milliseconds: 240);
  static const Duration scene = Duration(milliseconds: 350);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve stateChange = Curves.easeInOutCubic;
}
