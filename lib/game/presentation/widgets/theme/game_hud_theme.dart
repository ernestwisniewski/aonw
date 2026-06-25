import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

abstract final class GameHudTheme {
  static const double buttonHeightCompact = 48;
  static const double buttonHeightNormal = 48;

  static const double panelMinHeightCompact = 68;
  static const double panelMinHeightNormal = 78;

  static const double buttonRadius = GameUiTheme.radiusButton;
  static const double panelRadius = GameUiTheme.radiusCard;

  static const double iconTileSizeCompact = 56.0;
  static const double iconTileSizeNormal = 72.0;
  static const double iconTileSize = iconTileSizeNormal;
  static const double iconTileRadius = GameUiTheme.radiusCard;

  static const double actionButtonWidthCompact = 50;
  static const double actionButtonWidthNormal = 52;
  static const double endTurnButtonWidthCompact = 96;
  static const double endTurnButtonWidthNormal = 136;
  static const double actionIconSize = GameIconSize.regular;

  static const double collapsedActionSize = 36;
  static const double collapsedActionIconSize = GameIconSize.small;
  static const double collapsedActionSpacing = 6;
  static const double collapsedActionBorderWidth = 1.4;

  static const double toolbarHeaderHeight = 28;
  static const double toolbarHorizontalPadding = 12;
  static const double toolbarActionGap = 10;

  static const int accentBgAlpha = 10;
  static const int accentBorderAlpha = 120;
  static const int accentIconBgAlpha = 40;

  static const int toolbarSurfaceAlpha = 242;
  static const int actionBgAlpha = 185;
  static const int actionActiveBgAlpha = 225;
  static const int actionBorderAlpha = 190;
  static const int actionActiveBorderAlpha = 245;
  static const int actionShadowAlpha = 56;
  static const int actionActiveShadowAlpha = 96;

  static const Color surface = GameUiTheme.surface;
  static const Color border = GameUiTheme.border;
  static const Color chipSurface = GameUiTheme.chipSurface;
  static const Color accentFallback = GameUiTheme.accent;
  static const Color textBright = GameUiTheme.textBright;
  static const Color textMuted = GameUiTheme.textMuted;
  static const Color textSecondary = GameUiTheme.textSecondary;
  static const Color success = GameUiTheme.success;
  static const Color successDim = GameUiTheme.successDim;
  static const Color info = GameUiTheme.info;
  static const Color scienceAccent = GameUiTheme.scienceAccent;
  static const Color resourcesAccent = GameUiTheme.resourcesAccent;

  static const Color colorWarning = GameUiTheme.warning;
  static const Color colorSubtle = GameUiTheme.goldLight;
  static const Color colorNeutral = Color(0xFF6f7480);
  static const Color colorWaiting = Color(0xFF555566);

  static const TextStyle buttonTopLabel = TextStyle(
    color: GameUiTheme.goldLight,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle buttonLabel = TextStyle(
    color: GameUiTheme.goldLight,
    fontFamily: GameUiTheme.headingFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle buttonLargeNum = TextStyle(
    color: GameUiTheme.goldLight,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle foundingStatusLabel = TextStyle(
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle playerPill = TextStyle(
    color: GameUiTheme.goldLight,
    fontFamily: GameUiTheme.headingFont,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle selectionTitle = TextStyle(
    color: GameUiTheme.goldLight,
    fontFamily: GameUiTheme.headingFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle selectionSubtitle = TextStyle(
    color: textMuted,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle selectionChip = TextStyle(
    color: textSecondary,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle selectionTag = TextStyle(
    color: textMuted,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle selectionToggle = TextStyle(
    color: textMuted,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );

  static const TextStyle yieldValue = TextStyle(
    color: textBright,
    fontFamily: GameUiTheme.bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: GameUiTheme.tabularFigures,
  );
}
