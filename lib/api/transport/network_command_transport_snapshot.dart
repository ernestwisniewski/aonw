part of 'network_command_transport.dart';

extension _NetworkCommandTransportSnapshot on NetworkCommandTransport {
  Future<int?> _turnFor(String saveId) async {
    try {
      final snapshot = await gameRepository.load(saveId);
      final turn = snapshot.domain.turn;
      _lastKnownTurnBySaveId[saveId] = turn;
      _lastKnownOffsetBySaveId[saveId] = snapshot.eventLogOffset;
      return turn;
    } catch (_) {
      return _lastKnownTurnBySaveId[saveId];
    }
  }

  Future<CommandTransportResult> _reloadAfterStaleCommand({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
  }) async {
    final snapshot = await gameRepository.load(saveId);
    _remember(saveId, snapshot);
    final nextState = _stateFromSnapshot(
      snapshot: snapshot,
      currentState: currentState,
      command: command,
      interactionSource: currentState,
    );
    return CommandTransportResult(
      state: nextState,
      snapshot: snapshot,
      offset: snapshot.eventLogOffset,
      storedSnapshot: true,
    );
  }

  CommandTransportResult _snapshotRecoveryResult({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    required CanonicalGameSnapshot snapshot,
    required int offset,
  }) {
    _remember(saveId, snapshot, offset: offset);
    final nextState = _stateFromSnapshot(
      snapshot: snapshot,
      currentState: currentState,
      command: command,
      interactionSource: currentState,
    );
    return CommandTransportResult(
      state: nextState,
      snapshot: snapshot,
      offset: offset,
      storedSnapshot: true,
    );
  }

  int _effectiveOffset(int ackOffset, CanonicalGameSnapshot snapshot) {
    return snapshot.eventLogOffset > ackOffset
        ? snapshot.eventLogOffset
        : ackOffset;
  }

  void _remember(String saveId, CanonicalGameSnapshot snapshot, {int? offset}) {
    _lastKnownTurnBySaveId[saveId] = snapshot.domain.turn;
    _lastKnownOffsetBySaveId[saveId] = offset ?? snapshot.eventLogOffset;
  }

  bool _activePlayerCanActAfter({
    required GameClientState currentState,
    required DomainCommand command,
    required CanonicalGameSnapshot snapshot,
  }) {
    if (command case SubmitTurnCommand(
      :final playerId,
    ) when playerId == currentState.activePlayerId) {
      return !snapshot.domain.hasSubmitted(playerId);
    }
    return currentState.activePlayerCanAct;
  }

  GameClientState _stateFromSnapshot({
    required CanonicalGameSnapshot snapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required GameClientState interactionSource,
  }) {
    final authoritative = snapshot.toClientState(
      activePlayerId: currentState.activePlayerId,
      activePlayerCanAct: _activePlayerCanActAfter(
        currentState: currentState,
        command: command,
        snapshot: snapshot,
      ),
    );
    return MultiplayerInteractionReconciler.reconcile(
      authoritativeState: authoritative,
      interactionSource: interactionSource,
    );
  }
}
