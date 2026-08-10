part of 'turn_reducer.dart';

int _nextTurnActionIndex({
  required _ClientState state,
  required String playerId,
  required List<_PendingTurnAction> actions,
  required GameObjectiveAdvice? preferredObjectiveAdvice,
  required int actionStep,
}) {
  final currentIndex = _currentTurnActionIndex(state, playerId, actions);
  final preferredIndex = _preferredTurnActionIndex(
    actions,
    preferredObjectiveAdvice,
  );
  final step = actionStep == 0 ? 1 : actionStep;
  final currentMatchesPreferred =
      currentIndex != -1 &&
      _turnActionMatchesAdvice(actions[currentIndex], preferredObjectiveAdvice);
  if (step > 0 && preferredIndex != -1 && !currentMatchesPreferred) {
    return preferredIndex;
  }
  if (currentIndex == -1) return step > 0 ? 0 : actions.length - 1;
  return _wrapTurnActionIndex(currentIndex + step, actions.length);
}

int _wrapTurnActionIndex(int index, int actionCount) {
  final wrapped = index.remainder(actionCount);
  return wrapped < 0 ? wrapped + actionCount : wrapped;
}

GameStateTransition _focusUnitAction(
  _ClientState state,
  GameUnit unit,
  MapTileLookup mapTiles,
) {
  final tile = mapTiles.tileAt(unit.col, unit.row);
  final newState = state.copyWithInteraction(
    moveCommandActive: state.canControlUnit(unit) && !unit.isMerchant,
    movePreview: null,
    cityFoundingDraft: null,
    pendingAction: null,
    selection: GameSelection.unit(unit, tile: tile),
  );

  return GameStateTransition(
    state: newState,
    uiEffects: _mapActionTargetEffects(unit.col, unit.row, unitId: unit.id),
  );
}

GameStateTransition _focusPendingTurnAction(
  _ClientState state,
  String playerId,
  _PendingTurnAction action,
  MapTileLookup mapTiles, {
  GameRuleset ruleset = GameRuleset.defaults,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return switch (action) {
    _PendingUnitAction(:final unit) => _focusUnitAction(state, unit, mapTiles),
    _PendingCityProductionAction(:final city) => _focusCityProductionAction(
      state,
      city,
      mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    ),
    _PendingResearchAction() => _focusResearchAction(state, playerId),
  };
}

GameStateTransition _focusCityProductionAction(
  _ClientState state,
  GameCity city,
  MapTileLookup mapTiles, {
  GameRuleset ruleset = GameRuleset.defaults,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  final newState = state.copyWithInteraction(
    moveCommandActive: false,
    movePreview: null,
    cityFoundingDraft: null,
    pendingAction: null,
    selection: CitySelectionProjector.project(
      state: state,
      city: city,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    ),
  );

  return GameStateTransition(
    state: newState,
    uiEffects: _mapActionTargetEffects(city.center.col, city.center.row),
  );
}

GameStateTransition _focusResearchAction(_ClientState state, String playerId) =>
    GameStateTransition(
      state: state.copyWithInteraction(
        moveCommandActive: false,
        movePreview: null,
        cityFoundingDraft: null,
        pendingAction: PendingResearchSelection(ownerPlayerId: playerId),
      ),
    );

int _currentTurnActionIndex(
  _ClientState state,
  String playerId,
  List<_PendingTurnAction> actions,
) {
  if (_researchSelectionIsCurrent(state, playerId)) {
    final index = actions.indexWhere(
      (action) => action is _PendingResearchAction,
    );
    if (index != -1) return index;
  }

  final unitId = _currentTurnActionUnitId(state, playerId);
  if (unitId != null) {
    final index = actions.indexWhere(
      (action) => action is _PendingUnitAction && action.unit.id == unitId,
    );
    if (index != -1) return index;
  }

  final cityId = _currentTurnActionCityId(state, playerId);
  if (cityId != null) {
    final index = actions.indexWhere(
      (action) =>
          action is _PendingCityProductionAction && action.city.id == cityId,
    );
    if (index != -1) return index;
  }

  return -1;
}

int _preferredTurnActionIndex(
  List<_PendingTurnAction> actions,
  GameObjectiveAdvice? preferredObjectiveAdvice,
) {
  if (preferredObjectiveAdvice == null) return -1;
  return actions.indexWhere(
    (action) => _turnActionMatchesAdvice(action, preferredObjectiveAdvice),
  );
}

bool _turnActionMatchesAdvice(
  _PendingTurnAction action,
  GameObjectiveAdvice? preferredObjectiveAdvice,
) {
  if (preferredObjectiveAdvice == null) return false;
  return switch (action) {
    _PendingUnitAction(:final unit) => _unitActionMatchesAdvice(
      unit,
      preferredObjectiveAdvice,
    ),
    _PendingCityProductionAction() => _cityActionMatchesAdvice(
      preferredObjectiveAdvice,
    ),
    _PendingResearchAction() => _researchActionMatchesAdvice(
      preferredObjectiveAdvice,
    ),
  };
}

bool _unitActionMatchesAdvice(
  GameUnit unit,
  GameObjectiveAdvice preferredObjectiveAdvice,
) {
  return switch (preferredObjectiveAdvice) {
    GameObjectiveAdvice.improveField => unit.type == GameUnitType.worker,
    GameObjectiveAdvice.foundCity ||
    GameObjectiveAdvice.claimTerritory => unit.type == GameUnitType.settler,
    GameObjectiveAdvice.trainUnit ||
    GameObjectiveAdvice.protectLead => UnitCombatStats.derive(unit).attack > 0,
    _ => false,
  };
}

bool _cityActionMatchesAdvice(GameObjectiveAdvice preferredObjectiveAdvice) {
  return switch (preferredObjectiveAdvice) {
    GameObjectiveAdvice.constructBuilding ||
    GameObjectiveAdvice.trainUnit ||
    GameObjectiveAdvice.foundCity ||
    GameObjectiveAdvice.growPopulation ||
    GameObjectiveAdvice.improveField ||
    GameObjectiveAdvice.claimTerritory ||
    GameObjectiveAdvice.collectGold ||
    GameObjectiveAdvice.protectLead => true,
    GameObjectiveAdvice.unlockTechnology => false,
  };
}

bool _researchActionMatchesAdvice(
  GameObjectiveAdvice preferredObjectiveAdvice,
) {
  return switch (preferredObjectiveAdvice) {
    GameObjectiveAdvice.unlockTechnology ||
    GameObjectiveAdvice.protectLead => true,
    _ => false,
  };
}

bool _researchSelectionIsCurrent(_ClientState state, String playerId) {
  return switch (state.pendingAction) {
    PendingResearchSelection(ownerPlayerId: final ownerPlayerId)
        when ownerPlayerId == playerId =>
      true,
    _ => false,
  };
}

String? _currentTurnActionUnitId(_ClientState state, String playerId) {
  switch (state.pendingAction) {
    case PendingAttackTargeting(
          ownerPlayerId: final ownerPlayerId,
          attackerUnitId: final attackerUnitId,
        )
        when ownerPlayerId == playerId:
      return attackerUnitId;
    case PendingWorkerActionSelection(
          ownerPlayerId: final ownerPlayerId,
          unitId: final unitId,
        )
        when ownerPlayerId == playerId:
      return unitId;
    default:
  }

  final cityFoundingDraft = state.cityFoundingDraft;
  if (cityFoundingDraft != null &&
      cityFoundingDraft.ownerPlayerId == playerId) {
    return cityFoundingDraft.unitId;
  }

  final selectedUnit = state.selection?.unit;
  if (selectedUnit != null && selectedUnit.ownerPlayerId == playerId) {
    return selectedUnit.id;
  }
  return null;
}

String? _currentTurnActionCityId(_ClientState state, String playerId) {
  switch (state.pendingAction) {
    case PendingCityWorkedHexSelection(
          ownerPlayerId: final ownerPlayerId,
          cityId: final cityId,
        )
        when ownerPlayerId == playerId:
      return cityId;
    case PendingCityExpansionSelection(
          ownerPlayerId: final ownerPlayerId,
          cityId: final cityId,
        )
        when ownerPlayerId == playerId:
      return cityId;
    default:
  }

  final selectedCity = state.selection?.city;
  if (selectedCity != null && selectedCity.ownerPlayerId == playerId) {
    return selectedCity.id;
  }
  return null;
}
