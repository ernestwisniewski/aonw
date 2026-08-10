part of 'turn_action_hint.dart';

GameObjectiveAdvice? hudActiveScoreAdvice(
  List<GameObjectiveProgress> activeObjectives,
) {
  for (final objective in activeObjectives) {
    if (_isScorePressureObjective(objective.definition.id)) {
      return objective.advice;
    }
  }
  return null;
}

bool _isScorePressureObjective(GameObjectiveId id) {
  return id == GameObjectiveId.holdScoreLead ||
      id == GameObjectiveId.overtakeScoreLeader;
}

GameUnit? _unitNeedingOrders({
  required GameClientState gameState,
  required String activePlayerId,
  required GameObjectiveAdvice? scoreAdvice,
}) {
  final units = [
    for (final unit in gameState.units)
      if (unit.ownerPlayerId == activePlayerId &&
          UnitTurnActionRules.needsManualOrder(unit, playerId: activePlayerId))
        unit,
  ];
  if (units.isEmpty) return null;

  return _preferredUnitForAdvice(units, scoreAdvice) ?? units.first;
}

GameUnit? _preferredUnitForAdvice(
  List<GameUnit> units,
  GameObjectiveAdvice? scoreAdvice,
) {
  return switch (scoreAdvice) {
    GameObjectiveAdvice.improveField => _firstUnitOfType(
      units,
      GameUnitType.worker,
    ),
    GameObjectiveAdvice.foundCity || GameObjectiveAdvice.claimTerritory =>
      _firstUnitOfType(units, GameUnitType.settler),
    GameObjectiveAdvice.trainUnit || GameObjectiveAdvice.protectLead =>
      units.where((unit) => !_isCivilianUnit(unit.type)).firstOrNull,
    _ => null,
  };
}

GameUnit? _firstUnitOfType(List<GameUnit> units, GameUnitType type) {
  for (final unit in units) {
    if (unit.type == type) return unit;
  }
  return null;
}

String? _scoreCityHint(
  AppLocalizations l10n,
  GameCity city,
  GameObjectiveAdvice? scoreAdvice,
) {
  final cityName = GameDisplayNames.city(l10n, city);
  return switch (scoreAdvice) {
    GameObjectiveAdvice.constructBuilding =>
      l10n.turnHintConstructBuildingInCity(cityName),
    GameObjectiveAdvice.trainUnit => l10n.turnHintTrainUnitInCity(cityName),
    GameObjectiveAdvice.foundCity => l10n.turnHintPrepareSettlerInCity(
      cityName,
    ),
    GameObjectiveAdvice.growPopulation => l10n.turnHintGrowPopulationInCity(
      cityName,
    ),
    GameObjectiveAdvice.improveField => l10n.turnHintPrepareWorkerInCity(
      cityName,
    ),
    GameObjectiveAdvice.collectGold => l10n.turnHintCollectGoldInCity(cityName),
    GameObjectiveAdvice.protectLead => l10n.turnHintProtectLeadProductionInCity(
      cityName,
    ),
    _ => null,
  };
}

String? _scoreResearchHint(
  AppLocalizations l10n,
  GameObjectiveAdvice? scoreAdvice,
) {
  return switch (scoreAdvice) {
    GameObjectiveAdvice.unlockTechnology =>
      l10n.turnHintUnlockTechnologyForScore,
    GameObjectiveAdvice.protectLead => l10n.turnHintProtectLeadResearch,
    _ => null,
  };
}

String? _scoreObjectiveHint(
  AppLocalizations l10n,
  GameObjectiveProgress objective,
) {
  if (!_isScorePressureObjective(objective.definition.id)) return null;
  final advice = GameObjectiveLabels.advice(l10n, objective.advice);
  if (advice == null) return null;
  return l10n.turnHintObjectiveWithAdvice(
    GameObjectiveLabels.title(l10n, objective.definition.id),
    advice,
  );
}
