part of 'hud_action_deck.dart';

extension _HudActionDeckAutoFlow on _HudActionDeckState {
  void _onAutoTurnFlowSignal() {
    _queueAutoTurnFlow();
  }

  void _rememberCurrentAutoTurnFlowSignature() {
    final state = widget.gameState;
    _lastAutoTurnFlowSignature = state == null
        ? null
        : _autoTurnFlowSignature(state);
  }

  void _queueAutoTurnFlow({bool force = false}) {
    if ((!_autoActionFlowEnabled && !_autoTurnFlowEnabled) ||
        _autoTurnFlowQueued ||
        _autoTurnFlowInFlight ||
        !mounted) {
      return;
    }
    final state = widget.gameState;
    if (!_canAutoAdvance(state, force: force)) return;
    final signature = _autoTurnFlowSignature(state!);
    if (!force && signature == _lastAutoTurnFlowSignature) return;

    _autoTurnFlowQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runQueuedAutoTurnFlow(force: force);
    });
  }

  void _runQueuedAutoTurnFlow({required bool force}) {
    _autoTurnFlowQueued = false;
    if ((!_autoActionFlowEnabled && !_autoTurnFlowEnabled) ||
        _autoTurnFlowInFlight ||
        !mounted) {
      return;
    }
    final currentState = widget.gameState;
    if (!_canAutoAdvance(currentState, force: force)) return;
    final isEndingTurn = widget.readyToEndTurn;
    final currentSignature = _autoTurnFlowSignature(currentState!);
    if (!force && currentSignature == _lastAutoTurnFlowSignature) return;

    _lastAutoTurnFlowSignature = currentSignature;
    _autoTurnFlowInFlight = true;
    if (!isEndingTurn) {
      _autoTurnFlowAdvancedThisTurn = true;
    }
    final flow = isEndingTurn ? _runEndTurn() : _runNextAction();
    unawaited(
      flow.whenComplete(() {
        _autoTurnFlowInFlight = false;
        if (!mounted) return;
        if (isEndingTurn) {
          _autoTurnFlowPrimed = false;
          _autoTurnFlowAdvancedThisTurn = false;
          _lastAutoTurnFlowSignature = null;
          return;
        }
        _queueAutoTurnFlow();
      }),
    );
  }

  void _syncAutoTurnFlowAfterUpdate() {
    final contextKey = '${widget.activePlayerId}:${widget.gameSave.turn}';
    if (_autoTurnFlowContextKey != contextKey) {
      _autoTurnFlowContextKey = contextKey;
      _autoTurnFlowPrimed = false;
      _autoTurnFlowAdvancedThisTurn = false;
      _lastAutoTurnFlowSignature = null;
      _lastManualAutoTargetKey = null;
      _pausedManualAutoTargetKey = null;
    }

    final state = widget.gameState;
    final manualTargetKey = state == null ? null : _manualAutoTargetKey(state);
    if (_lastManualAutoTargetKey != null && manualTargetKey == null) {
      final lastTargetKey = _lastManualAutoTargetKey!;
      if (state != null &&
          _manualAutoTargetStillNeedsOrder(state, lastTargetKey)) {
        _pausedManualAutoTargetKey = lastTargetKey;
      } else {
        _pausedManualAutoTargetKey = null;
        _autoTurnFlowPrimed = true;
        _lastAutoTurnFlowSignature = null;
      }
    } else if (manualTargetKey != null) {
      _pausedManualAutoTargetKey = null;
    } else {
      final pausedTargetKey = _pausedManualAutoTargetKey;
      if (state == null ||
          (pausedTargetKey != null &&
              !_manualAutoTargetStillNeedsOrder(state, pausedTargetKey))) {
        _pausedManualAutoTargetKey = null;
        if (pausedTargetKey != null) {
          _autoTurnFlowPrimed = true;
          _lastAutoTurnFlowSignature = null;
        }
      }
    }
    _lastManualAutoTargetKey = manualTargetKey;
  }

  void _syncDismissedResearchAction(HudActionDeck oldWidget) {
    final state = widget.gameState;
    if (state == null) return;
    final key = _researchActionKey(state);
    if (key == null) return;

    final oldPendingAction = oldWidget.gameState?.pendingAction;
    final canceledResearchSelection =
        oldPendingAction is PendingResearchSelection &&
        oldPendingAction.ownerPlayerId == widget.activePlayerId &&
        state.pendingAction is! PendingResearchSelection;
    if (!canceledResearchSelection) return;

    _lastAutoTurnFlowSignature = _autoTurnFlowSignature(state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dismissResearchAction(key);
    });
  }
}
