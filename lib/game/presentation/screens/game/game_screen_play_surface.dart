part of 'game_screen.dart';

class _GameRendererPlaySurface extends ConsumerWidget {
  const _GameRendererPlaySurface({
    required this.selection,
    required this.session,
    required this.gameSave,
    required this.renderer,
    required this.displaySettings,
    required this.loadingProgress,
    required this.gamepadInputListenable,
    required this.preloadFuture,
    required this.showDiceRollTestOverlay,
    required this.onToggleDiceRollTest,
    required this.onClose,
  });

  final MapSelection selection;
  final GameSession session;
  final GameSave? gameSave;
  final GameRenderer renderer;
  final HexDisplaySettings displaySettings;
  final ValueListenable<GameLoadingProgress> loadingProgress;
  final ValueListenable<GamepadInputSnapshot> gamepadInputListenable;
  final Future<void> preloadFuture;
  final bool showDiceRollTestOverlay;
  final VoidCallback onToggleDiceRollTest;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: ViewportGestureLayer(
            game: renderer,
            child: GameWidget(
              key: ValueKey(renderer),
              game: renderer,
              loadingBuilder: (_) =>
                  ValueListenableBuilder<GameLoadingProgress>(
                    valueListenable: loadingProgress,
                    builder: (context, progress, _) {
                      return GameLoadingPanel(progress: progress);
                    },
                  ),
            ),
          ),
        ),
        const Positioned.fill(child: GameMapVignetteOverlay()),
        if (showDiceRollTestOverlay)
          const Positioned.fill(child: DiceRollTestOverlay()),
        Positioned.fill(child: _buildHud(ref)),
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: _MultiplayerConnectionBanner(saveId: session.saveId),
        ),
        Positioned.fill(
          child: _GameStartupLoadingOverlay(
            saveId: session.saveId,
            multiplayer: session.gameMode == GameMode.multiplayer,
            preloadFuture: preloadFuture,
            rendererReady: renderer.readyListenable,
            initialCameraFocusReady: renderer.initialCameraFocusReadyListenable,
            loadingProgress: loadingProgress,
          ),
        ),
      ],
    );
  }

  Widget _buildHud(WidgetRef ref) {
    return GameHud(
      session: session,
      animatingUnitIdsListenable: renderer.animatingUnitIdsListenable,
      initialCameraFocusReadyListenable:
          renderer.initialCameraFocusReadyListenable,
      gamepadInputListenable: gamepadInputListenable,
      gameSave: gameSave,
      allowGraphicMode: session.imagePath != null,
      displaySettings: displaySettings,
      onToggleTerrain: () =>
          ref.read(hexDisplayProvider.notifier).toggleTerrain(),
      onToggleResources: () =>
          ref.read(hexDisplayProvider.notifier).toggleResources(),
      onToggleHeightBadge: () =>
          ref.read(hexDisplayProvider.notifier).toggleHeightBadge(),
      onToggleCitySites: () =>
          ref.read(hexDisplayProvider.notifier).toggleCitySites(),
      onToggleCityGrowth: () =>
          ref.read(hexDisplayProvider.notifier).toggleCityGrowth(),
      onToggleHexBorders: () => unawaited(
        ref
            .read(hexDisplayProvider.notifier)
            .setHexBordersVisibleForMap(
              selection,
              !displaySettings.hexBordersVisible,
            ),
      ),
      onToggleHeightWalls: () => unawaited(
        ref
            .read(hexDisplayProvider.notifier)
            .setHeightWallsVisibleForMap(
              selection,
              !displaySettings.heightWallsVisible,
            ),
      ),
      onHexBorderColorChanged: (color) => unawaited(
        ref
            .read(hexDisplayProvider.notifier)
            .setHexBorderColorForMap(selection, color),
      ),
      onWallTintColorChanged: (color) => unawaited(
        ref
            .read(hexDisplayProvider.notifier)
            .setWallTintColorForMap(selection, color),
      ),
      onResetHexBorderColor: () => unawaited(
        ref
            .read(hexDisplayProvider.notifier)
            .resetHexBorderColorForMap(selection),
      ),
      onResetWallTintColor: () => unawaited(
        ref
            .read(hexDisplayProvider.notifier)
            .resetWallTintColorForMap(selection),
      ),
      showDiceRollTest: showDiceRollTestOverlay,
      aiAutopilotEnabled: true,
      onToggleDiceRollTest: onToggleDiceRollTest,
      onClose: onClose,
      onViewModeChanged: (value) => _setViewMode(ref, value),
    );
  }

  void _setViewMode(WidgetRef ref, MapViewMode value) {
    if (value == MapViewMode.graphic && session.imagePath == null) return;
    ref
        .read(gameSessionProvider(selection, session.saveId).notifier)
        .setViewMode(value);
  }
}
