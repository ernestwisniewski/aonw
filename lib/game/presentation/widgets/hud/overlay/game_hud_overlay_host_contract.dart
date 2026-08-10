part of 'game_hud_overlay_host.dart';

class GameHudOverlayHost extends ConsumerStatefulWidget {
  final GameSession session;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;
  final ValueListenable<bool> initialCameraFocusReadyListenable;
  final ValueListenable<GamepadInputSnapshot> gamepadInputListenable;
  final GameSave gameSave;
  final bool optionsOverlayOpenOverride;

  const GameHudOverlayHost({
    required this.session,
    required this.animatingUnitIdsListenable,
    required this.initialCameraFocusReadyListenable,
    this.gamepadInputListenable =
        const AlwaysStoppedAnimation<GamepadInputSnapshot>(
          GamepadInputSnapshot.empty,
        ),
    required this.gameSave,
    this.optionsOverlayOpenOverride = false,
    super.key,
  });

  @override
  ConsumerState<GameHudOverlayHost> createState() => _GameHudOverlayHostState();
}
