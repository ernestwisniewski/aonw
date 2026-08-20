part of 'player_control_provider.dart';

extension GamePlayerControlHandoff on GamePlayerControlController {
  Future<void> confirmHandoff(String playerId) async {
    final keepAlive = _providerRef.keepAlive();
    try {
      await _confirmHandoff(playerId);
    } finally {
      keepAlive.close();
    }
  }

  Future<void> _confirmHandoff(String playerId) async {
    _clearTurnOpening();
    final result = await _loadHandoffControl(
      playerId,
      failureMessage: 'confirm handoff failed',
    );
    if (!_isMounted || result == null) return;

    await _setAndSyncAndWait(result.nextControl);
  }

  Future<void> prepareHumanTurn(
    String playerId, {
    TurnOpeningLease? lease,
  }) async {
    if (!_ownsTurnOpening(lease)) return;
    final keepAlive = _providerRef.keepAlive();
    try {
      final result = await _loadHandoffControl(
        playerId,
        failureMessage: 'prepare human turn failed',
      );
      if (!_isMounted || result == null || !_ownsTurnOpening(lease)) return;

      _pendingHumanTurnRelease = result.nextControl.copyWith(
        phase: _phaseForSave(result.save),
      );
      await _setAndSyncAndWait(
        result.nextControl.copyWith(
          phase: LocalSinglePlayerTurnPhase.turnOpening,
        ),
      );
    } finally {
      keepAlive.close();
    }
  }

  void beginTurnOpening(String playerId, {TurnOpeningLease? lease}) {
    final control = _currentControl;
    if (!_isMounted || playerId.isEmpty || control.activePlayerId != playerId) {
      return;
    }
    _turnOpeningLease = lease;
    final save = _providerRef.read(gamePlayerControlSaveProvider);
    final persistedPhase = save == null
        ? LocalSinglePlayerTurnPhase.notApplicable
        : _phaseForSave(save);
    final fallbackPhase =
        persistedPhase == LocalSinglePlayerTurnPhase.notApplicable
        ? LocalSinglePlayerTurnPhase.notApplicable
        : LocalSinglePlayerTurnPhase.humanPlanning;
    _pendingHumanTurnRelease = control.copyWith(
      canAct: fallbackPhase == LocalSinglePlayerTurnPhase.humanPlanning
          ? true
          : control.canAct,
      phase: fallbackPhase,
    );
    _currentControl = control.copyWith(
      phase: LocalSinglePlayerTurnPhase.turnOpening,
    );
  }

  Future<void> releaseHumanTurn(
    String playerId, {
    TurnOpeningLease? lease,
  }) async {
    if (!_ownsTurnOpening(lease)) return;
    final control = _currentControl;
    if (!_isMounted ||
        control.activePlayerId != playerId ||
        control.phase != LocalSinglePlayerTurnPhase.turnOpening) {
      _clearTurnOpeningIfOwned(lease);
      return;
    }
    final pending = _pendingHumanTurnRelease;
    final save = _providerRef.read(gamePlayerControlSaveProvider);
    final next = pending?.activePlayerId == playerId
        ? pending!
        : control.copyWith(
            phase: save == null
                ? LocalSinglePlayerTurnPhase.notApplicable
                : _phaseForSave(save),
          );
    try {
      await _setAndSyncAndWait(next);
    } finally {
      _clearTurnOpeningIfOwned(lease);
    }
  }

  bool cancelTurnOpening(TurnOpeningLease lease) {
    if (!_isMounted || !_ownsTurnOpening(lease)) return false;
    _clearTurnOpening();
    final control = _currentControl;
    if (control.phase != LocalSinglePlayerTurnPhase.turnOpening) return true;

    final save = _providerRef.read(gamePlayerControlSaveProvider);
    final next = save == null
        ? control.copyWith(phase: LocalSinglePlayerTurnPhase.notApplicable)
        : PlayerControlCoordinator.normalizeForPlayer(
            current: control,
            save: save,
            preferredPlayerId: control.activePlayerId,
          ).copyWith(phase: _phaseForSave(save));
    _setAndSync(next);
    return true;
  }

  Future<ConfirmHandoffResult?> _loadHandoffControl(
    String playerId, {
    required String failureMessage,
  }) async {
    final session = _providerRef.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) return null;

    try {
      return await ConfirmHandoffUseCase(
        repository: _providerRef.read(gameRepositoryProvider),
      ).execute(
        saveId: session.saveId,
        current: _currentControl,
        playerId: playerId,
      );
    } catch (error, stackTrace) {
      if (_isMounted) {
        _providerRef
            .read(gameLoggerProvider)
            .warn(
              'GamePlayerControlController',
              failureMessage,
              error,
              stackTrace,
            );
      }
      return null;
    }
  }

  bool _ownsTurnOpening(TurnOpeningLease? lease) {
    return lease == null
        ? _turnOpeningLease == null
        : _turnOpeningLease == lease;
  }

  void _clearTurnOpeningIfOwned(TurnOpeningLease? lease) {
    if (_ownsTurnOpening(lease)) _clearTurnOpening();
  }

  void _clearTurnOpening() {
    _pendingHumanTurnRelease = null;
    _turnOpeningLease = null;
  }
}
