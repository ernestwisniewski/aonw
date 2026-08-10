part of 'hud_action_deck.dart';

extension _HudActionDeckAutoFlow on _HudActionDeckState {
  void _onAutoTurnFlowSignal() {
    _queueAutoTurnFlow();
  }

  void _setAutoTurnFlowEnabled(bool enabled) {
    if (_autoTurnFlowEnabled == enabled) return;
    _setAutoFlowState(() {
      _autoTurnFlowEnabled = enabled;
      if (enabled) {
        _pausedManualAutoTargetKey = null;
      }
      _lastAutoTurnFlowSignature = null;
    });
    _queueAutoTurnFlow(force: enabled);
  }

  void _setAutoActionFlowEnabled(bool enabled) {
    if (_autoActionFlowEnabled == enabled) return;
    _setAutoFlowState(() {
      _autoActionFlowEnabled = enabled;
      if (enabled) {
        _autoTurnFlowPrimed = true;
        _pausedManualAutoTargetKey = null;
      } else {
        _autoTurnFlowPrimed = false;
        _autoTurnFlowAdvancedThisTurn = false;
        _completedManualCityTargetKey = null;
      }
      if (enabled) _clearDismissedResearchAction(_researchActionKey());
      _lastAutoTurnFlowSignature = null;
    });
    _queueAutoTurnFlow(force: enabled);
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
    _completedManualCityTargetKey = null;
    _autoTurnFlowInFlight = true;
    if (!isEndingTurn) {
      _autoTurnFlowAdvancedThisTurn = true;
    }
    final flow = isEndingTurn ? _runEndTurn() : _runNextAutoAction();
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
    final contextKey =
        '${widget.gameSave.id}:${widget.activePlayerId}:${widget.gameSave.turn}';
    if (_autoTurnFlowContextKey != contextKey) {
      _autoTurnFlowContextKey = contextKey;
      _autoTurnFlowPrimed = false;
      _autoTurnFlowAdvancedThisTurn = false;
      _lastAutoTurnFlowSignature = null;
      _lastManualAutoTargetKey = null;
      _pausedManualAutoTargetKey = null;
      _completedManualCityTargetKey = null;
    }

    final state = widget.gameState;
    if (state == null) {
      _completedManualCityTargetKey = null;
      return;
    }
    _invalidateCompletedManualCityKey(state);
    final manualTargetKey = _manualAutoTargetKey(state);
    if (_lastManualAutoTargetKey != null && manualTargetKey == null) {
      final lastTargetKey = _lastManualAutoTargetKey!;
      if (_manualAutoTargetStillNeedsOrder(state, lastTargetKey)) {
        _pausedManualAutoTargetKey = lastTargetKey;
        _completedManualCityTargetKey = null;
      } else {
        _pausedManualAutoTargetKey = null;
        _completedManualCityTargetKey = _completedManualCityKey(lastTargetKey);
        _autoTurnFlowPrimed = true;
        _lastAutoTurnFlowSignature = null;
      }
    } else if (manualTargetKey != null) {
      _pausedManualAutoTargetKey = null;
      _completedManualCityTargetKey = null;
    } else {
      final pausedTargetKey = _pausedManualAutoTargetKey;
      if (pausedTargetKey != null &&
          !_manualAutoTargetStillNeedsOrder(state, pausedTargetKey)) {
        _pausedManualAutoTargetKey = null;
        _autoTurnFlowPrimed = true;
        _lastAutoTurnFlowSignature = null;
      }
    }
    _lastManualAutoTargetKey = manualTargetKey;
  }

  void _invalidateCompletedManualCityKey(GameClientState state) {
    final completedKey = _completedManualCityTargetKey;
    if (completedKey == null) return;
    final selectedCity = state.selection?.city;
    if (selectedCity == null ||
        completedKey != _HudManualAutoTarget.city(selectedCity.id).storageKey) {
      _completedManualCityTargetKey = null;
    }
  }

  String? _completedManualCityKey(String targetKey) {
    if (!_autoActionFlowEnabled) return null;
    final target = _HudManualAutoTarget.parse(targetKey);
    return target?.kind == _HudManualAutoTargetKind.city ? targetKey : null;
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
