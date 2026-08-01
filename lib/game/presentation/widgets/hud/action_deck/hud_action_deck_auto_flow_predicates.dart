part of 'hud_action_deck.dart';

extension _HudActionDeckAutoFlowPredicates on _HudActionDeckState {
  bool _canAutoAdvance(GameClientState? state, {bool force = false}) {
    if (state == null) return false;

    final context = _HudAutoAdvanceContext(
      activePlayerCanAct: widget.activePlayerCanAct,
      activePlayerUsesAutoTurnFlow: _activePlayerUsesAutoTurnFlow(),
      panelOpen: widget.panelOpen,
      mapInspectionActive: ref.read(mapInspectionControllerProvider).active,
      modalTransitionInProgress: _modalTransitionInProgress,
      activePlayerFinishedTurn:
          widget.gameSave.playerStates[widget.activePlayerId] ==
          PlayerTurnState.finished,
      unitAnimationInProgress:
          widget.animatingUnitIdsListenable.value.isNotEmpty,
      readyToEndTurn: widget.readyToEndTurn,
      remainingActionCount: widget.remainingActionCount,
      autoTurnFlowEnabled: _autoTurnFlowEnabled,
      autoActionFlowEnabled: _autoActionFlowEnabled,
      force: force,
      manualAutoTargetPaused: _pausedManualAutoTargetKey != null,
      inspectingResolvedCityWithPendingActions:
          _isInspectingResolvedCityWithPendingActions(state),
      resolvedCityCompletionCanAdvance: _resolvedCityCompletionCanAdvance(
        state,
      ),
      researchActionDismissed: _researchActionDismissed(state),
      waitsForManualDecision: _waitsForManualDecision(state),
      autoTurnFlowCanStart: _autoTurnFlowCanStartFrom(state),
    );

    return const _HudAutoAdvancePolicy().canAdvance(context);
  }

  bool _autoTurnFlowCanStartFrom(GameClientState state) {
    return _autoTurnFlowPrimed ||
        _autoTurnFlowAdvancedThisTurn ||
        _hasResolvedActiveSelection(state) ||
        _hasUnitOrCityActionToStartAuto(state);
  }

  bool _activePlayerUsesAutoTurnFlow() {
    return widget.gameSave.players.any(
      (player) =>
          player.id == widget.activePlayerId && player.kind == PlayerKind.human,
    );
  }

  String? _manualAutoTargetKey(GameClientState state) {
    return _HudManualAutoTarget.resolve(
      state: state,
      activePlayerId: widget.activePlayerId,
      unitNeedsManualOrder: _unitNeedsManualOrder,
    )?.storageKey;
  }

  bool _manualAutoTargetStillNeedsOrder(
    GameClientState state,
    String targetKey,
  ) {
    return _HudManualAutoTarget.parse(targetKey)?.stillNeedsOrder(
          state: state,
          activePlayerId: widget.activePlayerId,
          unitNeedsManualOrder: _unitNeedsManualOrder,
        ) ??
        false;
  }

  bool _waitsForManualDecision(GameClientState state) {
    return _HudManualDecisionPolicy(
      activePlayerId: widget.activePlayerId,
      unitNeedsManualOrder: _unitNeedsManualOrder,
      canAutoOpenResearchAction: _canAutoOpenResearchAction,
    ).waitsForManualDecision(state);
  }

  bool _hasResolvedActiveSelection(GameClientState state) {
    return _HudResolvedSelectionPolicy(
      activePlayerId: widget.activePlayerId,
      unitNeedsManualOrder: _unitNeedsManualOrder,
    ).hasResolvedSelection(state);
  }

  bool _hasUnitOrCityActionToStartAuto(GameClientState state) {
    return _HudAutoStartCandidatePolicy(
      activePlayerId: widget.activePlayerId,
      unitNeedsManualOrder: _unitNeedsManualOrder,
    ).hasActionCandidate(state);
  }

  bool _isInspectingResolvedCityWithPendingActions(GameClientState state) {
    return _HudResolvedCityInspectionPolicy(
      activePlayerId: widget.activePlayerId,
    ).isInspectingResolvedCityWithPendingActions(
      state,
      pendingActionCount: widget.remainingActionCount,
    );
  }

  bool _resolvedCityCompletionCanAdvance(GameClientState state) {
    final selectedCity = state.selection?.city;
    return selectedCity != null &&
        _completedManualCityTargetKey ==
            _HudManualAutoTarget.city(selectedCity.id).storageKey;
  }

  bool _canAutoOpenResearchAction(GameClientState state) {
    final key = _researchActionKey(state);
    return key != null && !_researchActionDismissed(state);
  }

  bool _researchActionDismissed(GameClientState state) {
    final key = _researchActionKey(state);
    return key != null &&
        ref.read(hudResearchAutoPromptControllerProvider).contains(key);
  }

  String? _researchActionKey([GameClientState? stateOverride]) {
    return _HudResearchAutoPromptPolicy(
      remainingActionCount: widget.remainingActionCount,
      activePlayerId: widget.activePlayerId,
      technologyRuleset: widget.technologyRuleset,
      gameSave: widget.gameSave,
    ).actionKeyFor(stateOverride ?? widget.gameState);
  }

  void _dismissResearchAction(String key) {
    ref.read(hudResearchAutoPromptControllerProvider.notifier).dismiss(key);
  }

  void _clearDismissedResearchAction(String? key) {
    if (key == null) return;
    ref.read(hudResearchAutoPromptControllerProvider.notifier).clear(key);
  }

  bool _unitNeedsManualOrder(GameUnit unit) {
    return UnitTurnActionRules.needsManualOrder(
      unit,
      playerId: widget.activePlayerId,
    );
  }

  String _autoTurnFlowSignature(GameClientState state) {
    return _HudAutoFlowSignatureBuilder(
      activePlayerId: widget.activePlayerId,
      unitNeedsManualOrder: _unitNeedsManualOrder,
    ).signatureFor(
      state: state,
      gameSave: widget.gameSave,
      readyToEndTurn: widget.readyToEndTurn,
      remainingActionCount: widget.remainingActionCount,
    );
  }
}
