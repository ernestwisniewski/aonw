part of 'hud_action_deck.dart';

typedef _HudUnitOrderPredicate = bool Function(GameUnit unit);

final class _HudAutoAdvanceContext {
  const _HudAutoAdvanceContext({
    required this.activePlayerCanAct,
    required this.activePlayerUsesAutoTurnFlow,
    required this.panelOpen,
    required this.mapInspectionActive,
    required this.activePlayerFinishedTurn,
    required this.unitAnimationInProgress,
    required this.readyToEndTurn,
    required this.remainingActionCount,
    required this.autoTurnFlowEnabled,
    required this.autoActionFlowEnabled,
    required this.force,
    required this.manualAutoTargetPaused,
    required this.inspectingResolvedCityWhileUnitNeedsOrder,
    required this.researchActionDismissed,
    required this.waitsForManualDecision,
    required this.autoTurnFlowCanStart,
  });

  final bool activePlayerCanAct;
  final bool activePlayerUsesAutoTurnFlow;
  final bool panelOpen;
  final bool mapInspectionActive;
  final bool activePlayerFinishedTurn;
  final bool unitAnimationInProgress;
  final bool readyToEndTurn;
  final int remainingActionCount;
  final bool autoTurnFlowEnabled;
  final bool autoActionFlowEnabled;
  final bool force;
  final bool manualAutoTargetPaused;
  final bool inspectingResolvedCityWhileUnitNeedsOrder;
  final bool researchActionDismissed;
  final bool waitsForManualDecision;
  final bool autoTurnFlowCanStart;

  bool get activeTurnIsAvailable {
    return activePlayerCanAct &&
        activePlayerUsesAutoTurnFlow &&
        !activePlayerFinishedTurn;
  }

  bool get hudIsIdle {
    return !panelOpen && !mapInspectionActive && !unitAnimationInProgress;
  }

  bool get currentStepIsEnabled {
    return readyToEndTurn ? autoTurnFlowEnabled : autoActionFlowEnabled;
  }

  bool get hasActionBudget {
    return readyToEndTurn || remainingActionCount > 0;
  }

  bool get manualBypassesAreClear {
    return force ||
        (!manualAutoTargetPaused &&
            !inspectingResolvedCityWhileUnitNeedsOrder &&
            !researchActionDismissed);
  }

  bool get canStartCurrentStep {
    return force || readyToEndTurn || autoTurnFlowCanStart;
  }
}

final class _HudAutoAdvancePolicy {
  const _HudAutoAdvancePolicy();

  bool canAdvance(_HudAutoAdvanceContext context) {
    return context.activeTurnIsAvailable &&
        context.hudIsIdle &&
        context.hasActionBudget &&
        context.currentStepIsEnabled &&
        context.manualBypassesAreClear &&
        !context.waitsForManualDecision &&
        context.canStartCurrentStep;
  }
}

final class _HudManualDecisionPolicy {
  const _HudManualDecisionPolicy({
    required this.activePlayerId,
    required this.unitNeedsManualOrder,
    required this.canAutoOpenResearchAction,
  });

  final String activePlayerId;
  final _HudUnitOrderPredicate unitNeedsManualOrder;
  final bool Function(GameState state) canAutoOpenResearchAction;

  bool waitsForManualDecision(GameState state) {
    return state.cityFoundingDraft != null ||
        state.movePreview != null ||
        _pendingActionRequiresManualDecision(state) ||
        _selectedUnitNeedsManualOrder(state.selectedUnit) ||
        _selectedCityNeedsProduction(state.selection?.city);
  }

  bool _pendingActionRequiresManualDecision(GameState state) {
    return switch (state.pendingAction) {
      null || PendingUnitTurnSkip() => false,
      PendingResearchSelection(:final ownerPlayerId)
          when ownerPlayerId == activePlayerId &&
              canAutoOpenResearchAction(state) =>
        false,
      PendingPlayerAction(:final ownerPlayerId) =>
        ownerPlayerId == activePlayerId,
    };
  }

  bool _selectedUnitNeedsManualOrder(GameUnit? unit) {
    return unit != null &&
        unit.ownerPlayerId == activePlayerId &&
        unitNeedsManualOrder(unit);
  }

  bool _selectedCityNeedsProduction(GameCity? city) {
    return city != null &&
        city.ownerPlayerId == activePlayerId &&
        city.productionQueue == null;
  }
}

final class _HudResolvedSelectionPolicy {
  const _HudResolvedSelectionPolicy({
    required this.activePlayerId,
    required this.unitNeedsManualOrder,
  });

  final String activePlayerId;
  final _HudUnitOrderPredicate unitNeedsManualOrder;

  bool hasResolvedSelection(GameState state) {
    return _selectedUnitIsResolved(state.selectedUnit) ||
        _selectedCityIsResolved(state.selection?.city);
  }

  bool _selectedUnitIsResolved(GameUnit? unit) {
    return unit != null &&
        unit.ownerPlayerId == activePlayerId &&
        !unitNeedsManualOrder(unit);
  }

  bool _selectedCityIsResolved(GameCity? city) {
    return city != null &&
        city.ownerPlayerId == activePlayerId &&
        city.productionQueue != null;
  }
}

final class _HudAutoStartCandidatePolicy {
  const _HudAutoStartCandidatePolicy({
    required this.activePlayerId,
    required this.unitNeedsManualOrder,
  });

  final String activePlayerId;
  final _HudUnitOrderPredicate unitNeedsManualOrder;

  bool hasActionCandidate(GameState state) {
    if (_hasManualInteractionInProgress(state)) return false;
    return _hasUnitNeedingOrders(state) || _hasCityNeedingProduction(state);
  }

  bool _hasUnitNeedingOrders(GameState state) {
    return state.units.any(
      (unit) =>
          unit.ownerPlayerId == activePlayerId && unitNeedsManualOrder(unit),
    );
  }

  bool _hasCityNeedingProduction(GameState state) {
    return state.cities.any(
      (city) =>
          city.ownerPlayerId == activePlayerId && city.productionQueue == null,
    );
  }
}

final class _HudResolvedCityInspectionPolicy {
  const _HudResolvedCityInspectionPolicy({
    required this.activePlayerId,
    required this.unitNeedsManualOrder,
  });

  final String activePlayerId;
  final _HudUnitOrderPredicate unitNeedsManualOrder;

  bool isInspectingResolvedCityWhileUnitNeedsOrder(GameState state) {
    return _selectedCityIsResolved(state.selection?.city) &&
        state.units.any(
          (unit) =>
              unit.ownerPlayerId == activePlayerId &&
              unitNeedsManualOrder(unit),
        );
  }

  bool _selectedCityIsResolved(GameCity? city) {
    return city != null &&
        city.ownerPlayerId == activePlayerId &&
        city.productionQueue != null;
  }
}

bool _hasManualInteractionInProgress(GameState state) {
  return state.pendingAction != null ||
      state.cityFoundingDraft != null ||
      state.movePreview != null;
}
