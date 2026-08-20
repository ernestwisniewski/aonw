part of 'multiplayer_avatars_rail.dart';

extension _MultiplayerAvatarsRailOverlayGamepad
    on _MultiplayerAvatarsRailOverlayState {
  bool get _avatarInputBlocked =>
      ref.read(gamePlayerControlControllerProvider).phase.blocksHumanInput;

  void _handleAvatarTapped(
    BuildContext context, {
    required GameSave gameSave,
    required GameClientState? gameState,
    required String activePlayerId,
    required String playerId,
  }) {
    if (_avatarInputBlocked) return;
    if (playerId == activePlayerId || gameState == null) {
      unawaited(
        ref
            .read(gameCommandControllerProvider.notifier)
            .jumpToPlayerStart(playerId),
      );
      return;
    }
    final mapData = ref.read(activeGameSessionProvider)?.mapData;
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
    required GameClientState gameState,
    required WorldMap mapData,
    required String activePlayerId,
    required String targetPlayerId,
  }) async {
    _setPopupInputCaptured(true, sourceId: 'multiplayerAvatarsRail.diplomacy');
    try {
      await showDiplomacyPlayerModal(
        context,
        gameSave: gameSave,
        gameState: gameState,
        mapData: mapData,
        activePlayerId: activePlayerId,
        targetPlayerId: targetPlayerId,
        gamepadInputListenable: widget.gamepadInputListenable,
        onCommand: ref.read(hudCommandDispatcherProvider).dispatchTransition,
      );
    } finally {
      _setPopupInputCaptured(
        false,
        sourceId: 'multiplayerAvatarsRail.diplomacy',
      );
    }
  }

  Future<void> _showRequestedPlayersSheet({
    required MultiplayerStatusSheetRequest next,
    required GameSave gameSave,
    required GameClientState? gameState,
    required DiplomacyState diplomacy,
    required String activePlayerId,
  }) async {
    _setPopupInputCaptured(
      true,
      sourceId: 'multiplayerAvatarsRail.requestedSheet',
    );
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
      _setPopupInputCaptured(
        false,
        sourceId: 'multiplayerAvatarsRail.requestedSheet',
      );
    }
  }

  List<HudGamepadFocusTarget> _playerGamepadFocusTargets({
    required AppLocalizations l10n,
    required GameSave gameSave,
    required GameClientState? gameState,
    required String activePlayerId,
  }) {
    if (_avatarInputBlocked) return const [];
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
          activationKey: Object.hash(
            gameSave.id,
            activePlayerId,
            gameState,
            player.id,
          ),
        ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.rightPlayers,
        id: HudGamepadFocusTargetIds.playerStatusSheet,
        label: l10n.multiplayerStatusTooltip,
        onActivate: () {
          if (_avatarInputBlocked) return;
          ref
              .read(multiplayerStatusSheetRequestProvider.notifier)
              .request(save: gameSave, activePlayerId: activePlayerId);
        },
        activationKey: Object.hash(
          gameSave.id,
          activePlayerId,
          gameState,
          'statusSheet',
        ),
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

  void _setPopupInputCaptured(bool captured, {required String sourceId}) {
    ref
        .read(hudGamepadPopupInputCaptureProvider.notifier)
        .setSourceCaptured(sourceId, captured);
  }
}
