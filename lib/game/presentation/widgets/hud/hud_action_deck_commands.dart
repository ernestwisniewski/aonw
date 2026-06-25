part of 'hud_action_deck.dart';

extension _HudActionDeckCommands on _HudActionDeckState {
  GameState? _currentGameState() {
    return ref.read(gameStateProvider(widget.gameSave.id)).value ??
        widget.gameState;
  }

  void _detachTroop(TroopType troopType) {
    ref.read(hudCommandDispatcherProvider).detachTroop(troopType);
  }

  void _selectWorkerImprovement(String unitId, FieldImprovementType type) {
    ref
        .read(hudCommandDispatcherProvider)
        .selectWorkerImprovement(unitId, type);
  }

  void _confirmWorkerImprovement(String unitId) {
    ref.read(hudCommandDispatcherProvider).confirmWorkerImprovement(unitId);
  }

  void _cancelWorkerActionSelection(String unitId) {
    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .dispatch(CancelWorkerActionSelectionCommand(unitId)),
    );
  }

  void _confirmCityExpansionSelection() {
    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .confirmCityExpansionSelection(_currentGameState()),
    );
  }

  void _cancelCityExpansionSelection() {
    ref
        .read(hudCommandDispatcherProvider)
        .cancelCityExpansionSelection(_currentGameState());
  }

  void _nextAction() {
    _clearActionCompletionPulse();
    _autoTurnFlowPrimed = true;
    _autoTurnFlowAdvancedThisTurn = true;
    _pausedManualAutoTargetKey = null;
    final state = _currentGameState();
    _clearDismissedResearchActionForManualRequest(state);
    _rememberCurrentAutoTurnFlowSignature();
    if (state != null && _closeCityExpansionSelectionBeforeNextAction(state)) {
      return;
    }
    if (state != null && _focusBlockingManualDecision(state)) {
      return;
    }
    _runNextActionAndQueue();
  }

  void _selectTurnAction(int actionIndex) {
    _clearActionCompletionPulse();
    _autoTurnFlowPrimed = true;
    _autoTurnFlowAdvancedThisTurn = true;
    _pausedManualAutoTargetKey = null;
    final state = _currentGameState();
    _clearDismissedResearchActionForManualRequest(state);
    _rememberCurrentAutoTurnFlowSignature();
    unawaited(
      _runNextAction(actionIndex: actionIndex).whenComplete(() {
        if (mounted) _queueAutoTurnFlow();
      }),
    );
  }

  void _clearDismissedResearchActionForManualRequest(GameState? state) {
    if (state == null) return;
    _clearDismissedResearchAction(_researchActionKey(state));
  }

  void _runNextActionAndQueue() {
    unawaited(
      _runNextAction().whenComplete(() {
        if (mounted) _queueAutoTurnFlow();
      }),
    );
  }

  bool _closeCityExpansionSelectionBeforeNextAction(GameState state) {
    final pendingAction = state.pendingAction;
    if (pendingAction is! PendingCityExpansionSelection ||
        pendingAction.ownerPlayerId != widget.activePlayerId) {
      return false;
    }

    final dispatcher = ref.read(hudCommandDispatcherProvider);
    unawaited(
      dispatcher.confirmCityExpansionSelection(state).whenComplete(() {
        if (!mounted) return;
        _runNextActionAndQueue();
      }),
    );
    return true;
  }

  bool _focusBlockingManualDecision(GameState state) {
    final dispatcher = ref.read(hudCommandDispatcherProvider);
    final cityFoundingDraft = state.cityFoundingDraft;
    if (cityFoundingDraft != null) {
      unawaited(dispatcher.focusUnitMapTarget(cityFoundingDraft.unitId));
      return true;
    }

    if (state.movePreview != null) {
      final selectedUnit = state.selectedUnit;
      if (selectedUnit != null) {
        unawaited(dispatcher.focusUnitMapTarget(selectedUnit.id));
      }
      return true;
    }

    final pendingAction = state.pendingAction;
    if (pendingAction != null &&
        pendingAction.ownerPlayerId == widget.activePlayerId &&
        pendingAction is! PendingUnitTurnSkip) {
      if (pendingAction is! PendingResearchSelection) {
        _focusPendingManualAction(pendingAction, dispatcher);
        return true;
      }
    }

    if (_restoreSelectedCityProduction(state, dispatcher)) return true;
    return false;
  }

  void _focusPendingManualAction(
    PendingPlayerAction pendingAction,
    HudCommandDispatcher dispatcher,
  ) {
    switch (pendingAction) {
      case PendingAttackTargeting(:final attackerUnitId):
        unawaited(dispatcher.focusUnitMapTarget(attackerUnitId));
      case PendingWorkerActionSelection(:final unitId):
        unawaited(dispatcher.focusUnitMapTarget(unitId));
      case PendingMerchantTradeRouteSelection(:final unitId):
        unawaited(dispatcher.focusUnitMapTarget(unitId));
      case PendingMerchantMoveToCitySelection(:final unitId):
        unawaited(dispatcher.focusUnitMapTarget(unitId));
      case PendingCommanderMergeSelection(:final commanderUnitId):
        unawaited(dispatcher.focusUnitMapTarget(commanderUnitId));
      case PendingCityWorkedHexSelection(:final cityId):
        unawaited(dispatcher.focusCityMapTarget(cityId));
      case PendingCityExpansionSelection(:final cityId):
        unawaited(dispatcher.focusCityMapTarget(cityId));
      case PendingResearchSelection() || PendingUnitTurnSkip():
        return;
    }
  }

  bool _restoreSelectedCityProduction(
    GameState state,
    HudCommandDispatcher dispatcher,
  ) {
    if (widget.cityProductionPanelOpen && widget.remainingActionCount > 1) {
      return false;
    }

    final selectedCity = state.selection?.city;
    if (selectedCity == null ||
        selectedCity.ownerPlayerId != widget.activePlayerId ||
        selectedCity.productionQueue != null) {
      return false;
    }

    if (state.pendingAction != null) {
      unawaited(
        dispatcher.dispatch(SelectCityCommand(selectedCity.id)).then((_) {
          if (!mounted) return;
          unawaited(dispatcher.focusCityMapTarget(selectedCity.id));
          dispatcher.openCityProductionPanel(state: _currentGameState());
        }),
      );
    } else {
      unawaited(dispatcher.focusCityMapTarget(selectedCity.id));
      dispatcher.openCityProductionPanel(state: state);
    }
    return true;
  }

  void _endTurn() {
    _clearActionCompletionPulse();
    _autoTurnFlowPrimed = true;
    _autoTurnFlowAdvancedThisTurn = true;
    _rememberCurrentAutoTurnFlowSignature();
    unawaited(_runEndTurn());
  }

  Future<void> _runNextAction({int? actionIndex}) {
    return ref
        .read(hudCommandDispatcherProvider)
        .focusNextAction(
          activePlayerId: widget.activePlayerId,
          currentState: _currentGameState,
          preferredObjectiveAdvice: widget.nextActionObjectiveAdvice,
          actionIndex: actionIndex,
        );
  }

  Future<void> _runEndTurn() {
    return ref
        .read(hudCommandDispatcherProvider)
        .endTurn(
          animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
          gameSave: widget.gameSave,
          activePlayerId: widget.activePlayerId,
          readyToEndTurn: widget.readyToEndTurn,
          currentState: _currentGameState,
          preferredObjectiveAdvice: widget.nextActionObjectiveAdvice,
        );
  }
}
