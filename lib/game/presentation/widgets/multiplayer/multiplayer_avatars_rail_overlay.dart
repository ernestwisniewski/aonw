part of 'multiplayer_avatars_rail.dart';

class MultiplayerAvatarsRailOverlay extends ConsumerStatefulWidget {
  static const double rightOffset = 12;
  static const double compactRightOffset = 8;

  const MultiplayerAvatarsRailOverlay({
    required this.gameSave,
    this.gamepadInputListenable,
    super.key,
  });

  final GameSave gameSave;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  @override
  ConsumerState<MultiplayerAvatarsRailOverlay> createState() =>
      _MultiplayerAvatarsRailOverlayState();
}

class _MultiplayerAvatarsRailOverlayState
    extends ConsumerState<MultiplayerAvatarsRailOverlay> {
  final GlobalKey _requestedStatusSheetKey = GlobalKey();

  @override
  void didUpdateWidget(covariant MultiplayerAvatarsRailOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final save = widget.gameSave;
    if (save.id != oldWidget.gameSave.id ||
        save.gameMode != GameMode.multiplayer ||
        save.turn > oldWidget.gameSave.turn) {
      _dismissRequestedStatusSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameSave = widget.gameSave;
    if (gameSave.gameMode != GameMode.multiplayer || gameSave.players.isEmpty) {
      _syncGamepadFocusTargets(const []);
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.watch(gamePlayerControlControllerProvider),
      save: gameSave,
    );
    final gameState = ref.watch(gameStateProvider(gameSave.id)).value;
    ref.watch(activeGameSessionProvider);
    final diplomacy = gameState?.diplomacy ?? DiplomacyState.empty;
    _listenForStatusSheetRequests(
      gameSave: gameSave,
      gameState: gameState,
      diplomacy: diplomacy,
      activePlayerId: playerControl.activePlayerId,
    );
    final size = MediaQuery.sizeOf(context);
    final compact = MultiplayerAvatarsRailMetrics.useCompactLayout(
      width: size.width,
      height: size.height,
    );
    final focusedTargetId = ref.watch(
      hudGamepadFocusControllerProvider.select(
        (state) => state.active ? state.targetId : null,
      ),
    );
    _syncGamepadFocusTargets(
      _playerGamepadFocusTargets(
        l10n: l10n,
        gameSave: gameSave,
        gameState: gameState,
        activePlayerId: playerControl.activePlayerId,
      ),
    );
    final safePadding = MediaQuery.paddingOf(context);
    return Positioned(
      top: safePadding.top + _topOffset(compact),
      right: safePadding.right + _rightOffset(compact),
      child: MultiplayerAvatarsRail(
        gameSave: gameSave,
        activePlayerId: playerControl.activePlayerId,
        diplomacy: diplomacy,
        gameState: gameState,
        gamepadFocusedTargetId: focusedTargetId,
        gamepadInputListenable: widget.gamepadInputListenable,
        onGamepadSheetOpenChanged: (captured) => _setPopupInputCaptured(
          captured,
          sourceId: 'multiplayerAvatarsRail.fullListSheet',
        ),
        onAvatarTapped: (playerId) => _handleAvatarTapped(
          context,
          gameSave: gameSave,
          gameState: gameState,
          activePlayerId: playerControl.activePlayerId,
          playerId: playerId,
        ),
      ),
    );
  }

  void _listenForStatusSheetRequests({
    required GameSave gameSave,
    required GameClientState? gameState,
    required DiplomacyState diplomacy,
    required String activePlayerId,
  }) {
    ref.listen<MultiplayerStatusSheetRequest?>(
      multiplayerStatusSheetRequestProvider,
      (previous, next) {
        if (next == null || next.save.id != gameSave.id) return;
        ref
            .read(multiplayerStatusSheetRequestProvider.notifier)
            .consume(next.id);
        final sheetState =
            ref.read(gameStateProvider(next.save.id)).value ?? gameState;
        final sheetDiplomacy = sheetState?.diplomacy ?? diplomacy;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted || _requestIsStale(next)) return;
          unawaited(
            _showRequestedPlayersSheet(
              next: next,
              gameSave: gameSave,
              gameState: sheetState,
              diplomacy: sheetDiplomacy,
              activePlayerId: activePlayerId,
            ),
          );
        });
      },
    );
  }

  static double _topOffset(bool compact) => compact
      ? HudSideMenuMetrics.compactTopOffset
      : HudSideMenuMetrics.topOffset;

  static double _rightOffset(bool compact) => compact
      ? MultiplayerAvatarsRailOverlay.compactRightOffset
      : MultiplayerAvatarsRailOverlay.rightOffset;

  bool _requestIsStale(MultiplayerStatusSheetRequest request) =>
      widget.gameSave.id != request.save.id ||
      widget.gameSave.gameMode != GameMode.multiplayer ||
      widget.gameSave.turn > request.save.turn;

  void _dismissRequestedStatusSheet() {
    final sheetContext = _requestedStatusSheetKey.currentContext;
    if (sheetContext == null || !sheetContext.mounted) return;
    unawaited(Navigator.of(sheetContext).maybePop());
  }
}
