part of 'player_control_provider.dart';

extension GamePlayerControlSynchronization on GamePlayerControlController {
  void syncWithSave(GameSave? save, {String? preferredPlayerId}) {
    final previous = _currentControl;
    final normalized = PlayerControlCoordinator.normalizeForPlayer(
      current: previous,
      save: save,
      preferredPlayerId: preferredPlayerId,
    );
    if (normalized.activePlayerId != previous.activePlayerId) {
      _clearTurnOpening();
    }
    _setAndSync(_withSavePhase(normalized, save: save, previous: previous));
  }

  void selectPlayer(GameSave? save, String playerId) {
    _clearTurnOpening();
    final previous = _currentControl;
    _setAndSync(
      _withSavePhase(
        PlayerControlCoordinator.selectPlayer(
          current: previous,
          save: save,
          playerId: playerId,
        ),
        save: save,
        previous: previous,
      ),
    );
  }

  PlayerControlState _withSavePhase(
    PlayerControlState next, {
    required GameSave? save,
    required PlayerControlState previous,
    NetworkSession? networkSession,
  }) {
    if (save == null) return next;
    final resolvedPhase = _phaseForSave(save, networkSession: networkSession);
    if (resolvedPhase != LocalSinglePlayerTurnPhase.notApplicable &&
        previous.activePlayerId == next.activePlayerId &&
        (previous.phase == LocalSinglePlayerTurnPhase.aiResolving ||
            previous.phase == LocalSinglePlayerTurnPhase.turnOpening)) {
      return next.copyWith(phase: previous.phase);
    }
    return next.copyWith(phase: resolvedPhase);
  }

  LocalSinglePlayerTurnPhase _phaseForSave(
    GameSave save, {
    NetworkSession? networkSession,
  }) {
    return LocalSinglePlayerTurnPhasePolicy.resolve(
      save: save,
      networkSession:
          networkSession ?? _providerRef.read(networkSessionProvider),
    );
  }

  void _invalidateSave(String saveId) {
    if (!_isMounted) return;
    _providerRef.invalidate(gameSaveSnapshotProvider(saveId));
  }

  void _setAndSync(PlayerControlState next) {
    if (_currentControl != next) {
      _currentControl = next;
    }
    unawaited(_syncGameState(next));
  }

  Future<void> _setAndSyncAndWait(PlayerControlState next) async {
    if (_currentControl != next) {
      _currentControl = next;
    }
    await _syncGameState(next);
  }

  Future<void> _syncGameState(PlayerControlState next) async {
    final logger = _providerRef.read(gameLoggerProvider);
    try {
      await _providerRef
          .read(
            gameStateProvider(
              _providerRef.read(activeGameSessionProvider)?.saveId ?? '',
            ).notifier,
          )
          .syncActivePlayer(playerId: next.activePlayerId, canAct: next.canAct);
    } catch (error, stackTrace) {
      logger.warn(
        'GamePlayerControlController',
        'game state sync failed',
        error,
        stackTrace,
      );
    }
  }

  Future<List<UiEffect>> _dispatchAndHandle(DomainCommand command) {
    return _providerRef
        .read(gameCommandControllerProvider.notifier)
        .dispatch(command);
  }
}
