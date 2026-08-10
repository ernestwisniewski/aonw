part of 'game_options_overlay.dart';

class GameOptionsOverlay extends ConsumerStatefulWidget {
  final GameSession session;
  final GameSave? gameSave;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final HexDisplaySettings displaySettings;
  final VoidCallback onToggleTerrain;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleHeightBadge;
  final VoidCallback onToggleCitySites;
  final VoidCallback onToggleCityGrowth;
  final VoidCallback onToggleHexBorders;
  final VoidCallback onToggleHeightWalls;
  final ValueChanged<Color>? onHexBorderColorChanged;
  final ValueChanged<Color>? onWallTintColorChanged;
  final VoidCallback? onResetHexBorderColor;
  final VoidCallback? onResetWallTintColor;
  final bool showDiceRollTest;
  final VoidCallback? onToggleDiceRollTest;
  final VoidCallback? onResignMatch;
  final bool resigning;
  final Widget? closedContent;
  final ValueChanged<bool>? onOverlayPanelActiveChanged;

  const GameOptionsOverlay({
    required this.session,
    this.gameSave,
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.displaySettings,
    required this.onToggleTerrain,
    required this.onToggleResources,
    required this.onToggleHeightBadge,
    required this.onToggleCitySites,
    required this.onToggleCityGrowth,
    required this.onToggleHexBorders,
    required this.onToggleHeightWalls,
    this.onHexBorderColorChanged,
    this.onWallTintColorChanged,
    this.onResetHexBorderColor,
    this.onResetWallTintColor,
    this.showDiceRollTest = false,
    this.onToggleDiceRollTest,
    this.onResignMatch,
    this.resigning = false,
    this.closedContent,
    this.onOverlayPanelActiveChanged,
    super.key,
  });

  @override
  ConsumerState<GameOptionsOverlay> createState() => _GameOptionsOverlayState();
}
