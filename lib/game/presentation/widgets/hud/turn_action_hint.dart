import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn_reducer.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

bool hudPlayerReadyToEndTurn({
  required GameState? gameState,
  required String activePlayerId,
  required TechnologyPanelViewModel technologyViewModel,
}) {
  if (gameState == null || activePlayerId.isEmpty) return false;
  final allUnitsReady = gameState.units
      .where((unit) => unit.ownerPlayerId == activePlayerId)
      .every(
        (unit) => !UnitTurnActionRules.needsManualOrder(
          unit,
          playerId: activePlayerId,
        ),
      );
  final allCitiesReady = gameState.cities
      .where((city) => city.ownerPlayerId == activePlayerId)
      .every((city) => city.productionQueue != null);
  return allUnitsReady &&
      allCitiesReady &&
      !hudNeedsResearchSelection(
        gameState: gameState,
        activePlayerId: activePlayerId,
        technologyViewModel: technologyViewModel,
      );
}

String? hudTurnHintLabel({
  required AppLocalizations l10n,
  required GameState? gameState,
  required String activePlayerId,
  required bool activePlayerCanAct,
  required bool actionsLocked,
  required bool readyToEndTurn,
  required TechnologyPanelViewModel technologyViewModel,
  required List<GameObjectiveProgress> activeObjectives,
}) {
  if (gameState == null || activePlayerId.isEmpty) return null;
  if (!activePlayerCanAct || readyToEndTurn || actionsLocked) return null;

  final scoreAdvice = hudActiveScoreAdvice(activeObjectives);
  final unitNeedingOrders = _unitNeedingOrders(
    gameState: gameState,
    activePlayerId: activePlayerId,
    scoreAdvice: scoreAdvice,
  );
  if (unitNeedingOrders != null) {
    final scoreHint = _scoreUnitHint(l10n, unitNeedingOrders, scoreAdvice);
    if (scoreHint != null) return scoreHint;
    return l10n.turnHintNextUnit(
      GameDisplayNames.unitType(l10n, unitNeedingOrders.type),
    );
  }

  final cityWithoutProduction = gameState.cities
      .where(
        (city) =>
            city.ownerPlayerId == activePlayerId &&
            city.productionQueue == null,
      )
      .firstOrNull;
  if (cityWithoutProduction != null) {
    final scoreHint = _scoreCityHint(l10n, cityWithoutProduction, scoreAdvice);
    if (scoreHint != null) return scoreHint;
    return l10n.turnHintNextCityProduction(
      GameDisplayNames.city(l10n, cityWithoutProduction),
    );
  }

  if (hudNeedsResearchSelection(
    gameState: gameState,
    activePlayerId: activePlayerId,
    technologyViewModel: technologyViewModel,
  )) {
    final scoreHint = _scoreResearchHint(l10n, scoreAdvice);
    if (scoreHint != null) return scoreHint;
    return l10n.turnHintChooseResearch;
  }

  final objective = activeObjectives.firstOrNull;
  if (objective != null) {
    final scoreHint = _scoreObjectiveHint(l10n, objective);
    if (scoreHint != null) return scoreHint;
    return l10n.turnHintObjective(
      GameObjectiveLabels.title(l10n, objective.definition.id),
    );
  }
  return l10n.turnHintCheckAction;
}

List<HudTurnActionOption> hudTurnActionOptions({
  required AppLocalizations l10n,
  required GameState? gameState,
  required String activePlayerId,
  required MapData mapData,
  required TechnologyRuleset technologyRuleset,
  required TechnologyPanelViewModel technologyViewModel,
}) {
  final targets = TurnReducer.pendingTurnActionTargets(
    gameState,
    activePlayerId,
    mapData,
    technologyRuleset: technologyRuleset,
  );
  return [
    for (var index = 0; index < targets.length; index++)
      HudTurnActionOption.fromTarget(
        index: index,
        target: targets[index],
        l10n: l10n,
        technologyViewModel: technologyViewModel,
      ),
  ];
}

class HudTurnActionOption {
  const HudTurnActionOption({
    required this.index,
    required this.label,
    required this.kindLabel,
    this.thumbnail,
  });

  final int index;
  final String label;
  final String kindLabel;
  final HudTurnActionThumbnail? thumbnail;

  factory HudTurnActionOption.fromTarget({
    required int index,
    required TurnActionTarget target,
    required AppLocalizations l10n,
    required TechnologyPanelViewModel technologyViewModel,
  }) {
    return switch (target) {
      UnitTurnActionTarget(:final unit) => HudTurnActionOption(
        index: index,
        label: _unitActionLabel(l10n, unit),
        kindLabel: l10n.turnActionUnitKind,
        thumbnail: HudTurnActionThumbnail.unit(unit.type),
      ),
      CityProductionTurnActionTarget(:final city) => HudTurnActionOption(
        index: index,
        label: l10n.turnActionCityProductionLabel(
          GameDisplayNames.city(l10n, city),
        ),
        kindLabel: l10n.turnActionCityProductionKind,
        thumbnail: HudTurnActionThumbnail.city(
          cityVisualLevel: _cityActionVisualLevel(city),
        ),
      ),
      ResearchTurnActionTarget() => HudTurnActionOption(
        index: index,
        label: l10n.turnActionResearchLabel,
        kindLabel: l10n.turnActionResearchKind,
        thumbnail: HudTurnActionThumbnail.research(
          technologyViewModel.recommendedTechnologies.firstOrNull?.id,
        ),
      ),
    };
  }
}

enum HudTurnActionThumbnailKind { unit, city, research }

class HudTurnActionThumbnail {
  const HudTurnActionThumbnail.unit(GameUnitType type)
    : kind = HudTurnActionThumbnailKind.unit,
      unitType = type,
      cityVisualLevel = null,
      cityTechnologyProfileIndex = null,
      technologyId = null;

  const HudTurnActionThumbnail.city({
    this.cityVisualLevel = 0,
    this.cityTechnologyProfileIndex = 0,
  }) : kind = HudTurnActionThumbnailKind.city,
       unitType = null,
       technologyId = null;

  const HudTurnActionThumbnail.research([this.technologyId])
    : kind = HudTurnActionThumbnailKind.research,
      unitType = null,
      cityVisualLevel = null,
      cityTechnologyProfileIndex = null;

  final HudTurnActionThumbnailKind kind;
  final GameUnitType? unitType;
  final int? cityVisualLevel;
  final int? cityTechnologyProfileIndex;
  final TechnologyId? technologyId;
}

String _unitActionLabel(AppLocalizations l10n, GameUnit unit) {
  return GameDisplayNames.unitWithType(l10n, unit);
}

int _cityActionVisualLevel(GameCity city) {
  if (city.population >= 10) return 3;
  if (city.population >= 6) return 2;
  if (city.population >= 4) return 1;
  return 0;
}

bool hudNeedsResearchSelection({
  required GameState gameState,
  required String activePlayerId,
  required TechnologyPanelViewModel technologyViewModel,
}) {
  final playerResearch = gameState.research.forPlayer(activePlayerId);
  if (playerResearch.activeTechnologyId != null) return false;
  return technologyViewModel.technologies.any((card) => card.canSelect);
}

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
  required GameState gameState,
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

  final preferred = _preferredUnitForAdvice(units, scoreAdvice);
  if (preferred != null) return preferred;
  return units.first;
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

String? _scoreUnitHint(
  AppLocalizations l10n,
  GameUnit unit,
  GameObjectiveAdvice? scoreAdvice,
) {
  return switch (scoreAdvice) {
    GameObjectiveAdvice.improveField when unit.type == GameUnitType.worker =>
      l10n.turnHintImproveFieldWithWorker,
    GameObjectiveAdvice.foundCity when unit.type == GameUnitType.settler =>
      l10n.turnHintFoundCityWithSettler,
    GameObjectiveAdvice.claimTerritory when unit.type == GameUnitType.settler =>
      l10n.turnHintClaimTerritoryWithSettler,
    GameObjectiveAdvice.trainUnit when !_isCivilianUnit(unit.type) =>
      l10n.turnHintTrainUnit(GameDisplayNames.unitType(l10n, unit.type)),
    GameObjectiveAdvice.protectLead when !_isCivilianUnit(unit.type) =>
      l10n.turnHintProtectLeadUnit(GameDisplayNames.unitType(l10n, unit.type)),
    _ => null,
  };
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

bool _isCivilianUnit(GameUnitType type) {
  return switch (type) {
    GameUnitType.settler || GameUnitType.worker || GameUnitType.scout => true,
    _ => false,
  };
}
