import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/production_models.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class AiProductionScoringCache {
  AiProductionScoringCache({required this.view, required this.context});

  final GameView view;
  final AiContext context;
  final Map<String, CityEconomyBreakdown> _economyByCityId = {};
  final Map<int, int> _availableSupplyByReservedSupply = {};
  final Map<GameUnitType, double> _unitPowerByType = {};
  final Map<int, bool> _citySiteScoutNeedByReconCount = {};
  final Map<String, bool> _activeSettlerEscortByPlanState = {};

  late final ResearchState research = ResearchState(
    players: {view.forPlayerId: view.ownResearch},
  );

  late final TechnologyEffectSummary technologyEffects =
      TechnologyEffectSummary.forPlayer(
        playerId: view.forPlayerId,
        research: research,
        ruleset: view.ruleset.technology,
      );

  CityEconomyBreakdown economyFor(GameCity city) {
    return _economyByCityId.putIfAbsent(city.id, () {
      final cityYield = CityYieldCalculator.totalFor(
        city,
        view.mapData,
        fieldImprovements: view.ownImprovements,
        units: view.ownUnits,
        ruleset: view.ruleset.city,
      );
      return CityEconomyBreakdown.from(
        city: city,
        tileYield: cityYield,
        mapData: view.mapData,
        ruleset: view.ruleset.city,
        paceBalance: view.ruleset.paceBalance,
        technologyEffects: technologyEffects,
      );
    });
  }

  int availableUnitSupply(AiProductionPlanState planState) {
    return _availableSupplyByReservedSupply.putIfAbsent(
      planState.reservedUnitSupply,
      () {
        final breakdown = CityUnitSupplyRules.forPlayer(
          playerId: view.forPlayerId,
          cities: view.ownCities,
          units: view.ownUnits,
          fieldImprovements: view.ownImprovements,
          mapData: view.mapData,
          cityRuleset: view.ruleset.city,
          research: research,
          technologyRuleset: view.ruleset.technology,
        );
        final available = breakdown.available - planState.reservedUnitSupply;
        return available < 0 ? 0 : available;
      },
    );
  }

  double unitPowerScore(GameUnitType unitType) {
    return _unitPowerByType.putIfAbsent(unitType, () {
      final unit = GameUnit.produced(
        id: 'score_${unitType.name}',
        ownerPlayerId: 'ai',
        type: unitType,
        col: 0,
        row: 0,
      );
      final stats = UnitCombatStats.derive(
        unit,
        ruleset: context.ruleset.combat,
      );
      return (stats.attack * 0.4 + stats.defense * 0.25 + stats.range * 0.5) /
          4;
    });
  }

  bool needsCitySiteScoutProduction(AiProductionPlanState planState) {
    return _citySiteScoutNeedByReconCount.putIfAbsent(planState.reconCount, () {
      if (view.ownCities.length < 2) return false;
      if (planState.reconCount > 0) return false;
      return AiFrontierExplorationScorer.needsCitySiteDiscovery(
        view: view,
        plan: context.strategicPlan,
      );
    });
  }

  bool activeSettlerNeedsEscortProduction({
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
  }) {
    final key =
        '${assessment.cityCount}|${assessment.settlerCount}|'
        '${planState.militaryCount}';
    return _activeSettlerEscortByPlanState.putIfAbsent(key, () {
      return _activeSettlerNeedsEscortProduction(
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
      );
    });
  }
}

bool _activeSettlerNeedsEscortProduction({
  required GameView view,
  required AiContext context,
  required AiEmpireAssessment assessment,
  required AiProductionPlanState planState,
}) {
  if (view.ownCities.isEmpty) return false;
  if (assessment.settlerCount <= 0) return false;
  final desiredMilitary = assessment.cityCount + assessment.settlerCount;
  if (planState.militaryCount >= desiredMilitary) return false;

  for (final founder in view.ownUnits) {
    if (!CityFoundingRules.canFoundCityWith(founder)) continue;
    if (founder.isWorking || founder.queuedPath != null) continue;
    final origin = HexCoordinate(col: founder.col, row: founder.row);
    if (_ownMilitaryNear(view, origin, 2)) continue;
    if (_visibleEnemyMilitaryNear(view, context, origin, 3)) return true;
    final assignment = context.strategicPlan?.settlerAssignments[founder.id];
    if (assignment != null &&
        _visibleEnemyMilitaryNear(
          view,
          context,
          assignment.toCoordinate(),
          3,
        )) {
      return true;
    }
    final nearestEnemyCity =
        AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
          view: view,
          hex: origin,
        );
    if (nearestEnemyCity != null && nearestEnemyCity <= 3) return true;
  }
  return false;
}

bool _ownMilitaryNear(GameView view, HexCoordinate target, int maxDistance) {
  for (final unit in view.ownUnits) {
    if (!AiUnitRoles.isMilitaryType(unit.type)) continue;
    final distance = HexDistance.between(
      target,
      HexCoordinate(col: unit.col, row: unit.row),
    );
    if (distance <= maxDistance) return true;
  }
  return false;
}

bool _visibleEnemyMilitaryNear(
  GameView view,
  AiContext context,
  HexCoordinate target,
  int maxDistance,
) {
  for (final enemy in view.visibleTargetableEnemyUnits) {
    if (!AiUnitRoles.isMilitaryType(enemy.type)) continue;
    final stats = UnitCombatStats.derive(
      enemy,
      ruleset: context.ruleset.combat,
    );
    if (stats.attack <= 0 && stats.defense <= 0) continue;
    final distance = HexDistance.between(
      target,
      HexCoordinate(col: enemy.col, row: enemy.row),
    );
    if (distance <= maxDistance) return true;
  }
  return false;
}
