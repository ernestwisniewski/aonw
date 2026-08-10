import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'turn_action_option.dart';
part 'turn_action_score_advice.dart';

bool hudPlayerReadyToEndTurn({
  required GameClientState? gameState,
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
  required GameClientState? gameState,
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
  required GameClientState? gameState,
  required String activePlayerId,
  required MapTileLookup mapTiles,
  required TechnologyRuleset technologyRuleset,
  required TechnologyPanelViewModel technologyViewModel,
}) {
  final targets = TurnReducer.pendingTurnActionTargets(
    gameState,
    activePlayerId,
    mapTiles,
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

bool hudNeedsResearchSelection({
  required GameClientState gameState,
  required String activePlayerId,
  required TechnologyPanelViewModel technologyViewModel,
}) {
  final playerResearch = gameState.research.forPlayer(activePlayerId);
  if (playerResearch.activeTechnologyId != null) return false;
  return technologyViewModel.technologies.any((card) => card.canSelect);
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

bool _isCivilianUnit(GameUnitType type) {
  return switch (type) {
    GameUnitType.settler || GameUnitType.worker || GameUnitType.scout => true,
    _ => false,
  };
}
