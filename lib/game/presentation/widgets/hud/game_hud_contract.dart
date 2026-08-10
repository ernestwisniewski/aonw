part of 'game_hud.dart';

class GameHud extends ConsumerStatefulWidget {
  final GameSession session;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;
  final ValueListenable<bool> initialCameraFocusReadyListenable;
  final ValueListenable<GamepadInputSnapshot> gamepadInputListenable;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final FutureOr<void> Function() onClose;
  final GameSave? gameSave;
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
  final bool showEntryHandoff;
  final bool aiAutopilotEnabled;

  const GameHud({
    required this.session,
    required this.animatingUnitIdsListenable,
    this.initialCameraFocusReadyListenable = const AlwaysStoppedAnimation<bool>(
      true,
    ),
    this.gamepadInputListenable = const AlwaysStoppedAnimation(
      GamepadInputSnapshot.empty,
    ),
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.onClose,
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
    this.showEntryHandoff = true,
    this.aiAutopilotEnabled = false,
    this.gameSave,
    super.key,
  });

  @override
  ConsumerState<GameHud> createState() => _GameHudState();
}
