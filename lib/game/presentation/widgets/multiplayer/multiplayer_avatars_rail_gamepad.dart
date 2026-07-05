part of 'multiplayer_avatars_rail.dart';

extension _MultiplayerAvatarsRailOverlayGamepad
    on _MultiplayerAvatarsRailOverlayState {
  void _handleAvatarTapped(
    BuildContext context, {
    required GameSave gameSave,
    required GameState? gameState,
    required String activePlayerId,
    required String playerId,
  }) {
    if (playerId == activePlayerId || gameState == null) {
      unawaited(
        ref
            .read(gameCommandControllerProvider.notifier)
            .jumpToPlayerStart(playerId),
      );
      return;
    }
    final mapData = ref
        .read(_MultiplayerAvatarsRailOverlayState._mapDataProvider(gameSave))
        .value;
    if (mapData == null) return;
    if (!MultiplayerAvatarsRail._hasDiplomaticContact(
      gameState: gameState,
      diplomacy: gameState.diplomacy,
      playerId: activePlayerId,
      targetPlayerId: playerId,
    )) {
      return;
    }
    unawaited(
      _showDiplomacyPopup(
        context,
        gameSave: gameSave,
        gameState: gameState,
        mapData: mapData,
        activePlayerId: activePlayerId,
        targetPlayerId: playerId,
      ),
    );
  }

  Future<void> _showDiplomacyPopup(
    BuildContext context, {
    required GameSave gameSave,
    required GameState gameState,
    required MapData mapData,
    required String activePlayerId,
    required String targetPlayerId,
  }) async {
    _setPopupInputCaptured(true);
    try {
      await showDiplomacyPlayerModal(
        context,
        gameSave: gameSave,
        gameState: gameState,
        mapData: mapData,
        activePlayerId: activePlayerId,
        targetPlayerId: targetPlayerId,
        gamepadInputListenable: widget.gamepadInputListenable,
        onCommand: ref.read(gameCommandControllerProvider.notifier).dispatch,
      );
    } finally {
      _setPopupInputCaptured(false);
    }
  }

  Future<void> _showRequestedPlayersSheet({
    required MultiplayerStatusSheetRequest next,
    required GameSave gameSave,
    required GameState? gameState,
    required DiplomacyState diplomacy,
    required String activePlayerId,
  }) async {
    _setPopupInputCaptured(true);
    try {
      await MultiplayerAvatarsRail.showPlayersSheet(
        context,
        gameSave: next.save,
        activePlayerId: next.activePlayerId,
        diplomacy: diplomacy,
        gameState: gameState,
        sheetRouteKey: _requestedStatusSheetKey,
        gamepadInputListenable: widget.gamepadInputListenable,
        onAvatarTapped: (playerId) => _handleAvatarTapped(
          context,
          gameSave: gameSave,
          gameState: gameState,
          activePlayerId: activePlayerId,
          playerId: playerId,
        ),
      );
    } finally {
      _setPopupInputCaptured(false);
    }
  }

  List<HudGamepadFocusTarget> _playerGamepadFocusTargets({
    required AppLocalizations l10n,
    required GameSave gameSave,
    required GameState? gameState,
    required String activePlayerId,
  }) {
    return [
      for (final player in gameSave.players)
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.rightPlayers,
          id: HudGamepadFocusTargetIds.playerAvatar(player.id),
          label: GameDisplayNames.player(l10n, player),
          onActivate: () => _handleAvatarTapped(
            context,
            gameSave: gameSave,
            gameState: gameState,
            activePlayerId: activePlayerId,
            playerId: player.id,
          ),
        ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.rightPlayers,
        id: HudGamepadFocusTargetIds.playerStatusSheet,
        label: l10n.multiplayerStatusTooltip,
        onActivate: () {
          ref
              .read(multiplayerStatusSheetRequestProvider.notifier)
              .request(save: gameSave, activePlayerId: activePlayerId);
        },
      ),
    ];
  }

  void _syncGamepadFocusTargets(List<HudGamepadFocusTarget> targets) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(hudGamepadFocusTargetRegistryProvider.notifier)
          .setSource('multiplayerAvatarsRail', targets);
    });
  }

  void _setPopupInputCaptured(bool captured) {
    ref
        .read(hudGamepadPopupInputCaptureProvider.notifier)
        .setCaptured(captured);
  }
}
