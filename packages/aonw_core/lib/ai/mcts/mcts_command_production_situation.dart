part of 'mcts_command_production_scorer.dart';

final class _MctsProductionSituation {
  const _MctsProductionSituation({
    required this.command,
    required this.state,
    required this.context,
    required this.assessment,
  });

  final StartUnitProductionCommand command;
  final SimulatedState state;
  final AiContext context;
  final AiEmpireAssessment assessment;

  GameUnitType get unitType => command.unitType;

  StrategicMode? get mode => context.strategicPlan?.mode;

  bool get isWorker => unitType == GameUnitType.worker;

  bool get isScout => unitType == GameUnitType.scout;

  bool get isSettler => unitType == GameUnitType.settler;

  bool get isMilitary => mctsIsMilitaryType(unitType, context);

  int get coreDefenseDeficit {
    return mctsCoreDefenseDeficit(
      assessment: assessment,
      state: state,
      context: context,
    );
  }

  bool get hasMilitaryDeficit {
    final weights = context.effectiveWeights;
    return coreDefenseDeficit > 0 ||
        (assessment.militaryCount < assessment.desiredMilitaryCount &&
            weights.aggression >= weights.expansion);
  }

  bool get openingSecondCityRoom {
    final weights = context.effectiveWeights;
    return assessment.cityCount == 1 &&
        assessment.desiredCityCount - assessment.cityCount >= 2 &&
        weights.aggression > weights.expansion &&
        assessment.militaryCount >= 2 &&
        assessment.netGoldPerTurn >= 0;
  }

  bool get safeSecondCityRoom {
    final weights = context.effectiveWeights;
    final allowedSettlers = isSettler ? 1 : 0;
    return assessment.cityCount == 1 &&
        assessment.settlerCount <= allowedSettlers &&
        assessment.desiredCityCount - assessment.cityCount >= 2 &&
        assessment.militaryCount >= 1 &&
        assessment.netGoldPerTurn >= 0 &&
        weights.expansion >= weights.aggression &&
        coreDefenseDeficit == 0 &&
        !hasLocalEnemyPressure;
  }

  bool get workerRecoveryNeeded {
    return assessment.cityCount >= 2 &&
        assessment.workerCount < assessment.cityCount - 1;
  }

  bool get reinforcedSecondCityRoom {
    return assessment.cityCount == 1 &&
        assessment.settlerCount == 1 &&
        assessment.desiredCityCount - assessment.cityCount >= 2 &&
        assessment.militaryCount >= 3 &&
        assessment.workerCount >= 1 &&
        assessment.netGoldPerTurn >= -2;
  }

  bool get escortedThirdCityPush {
    return assessment.militaryCount >= assessment.cityCount + 1;
  }

  bool get stableThirdCityRoom {
    return assessment.cityCount == 2 &&
        assessment.settlerCount == 1 &&
        assessment.desiredCityCount - assessment.cityCount >= 1 &&
        assessment.militaryCount >= assessment.cityCount &&
        assessment.netGoldPerTurn >= 0 &&
        (!hasLocalEnemyPressure || escortedThirdCityPush);
  }

  bool get activeSettlerNeedsEscort {
    if (state.ownCities.isEmpty) return false;
    if (assessment.settlerCount <= 0) return false;
    if (assessment.militaryCount >=
        assessment.cityCount + assessment.settlerCount) {
      return false;
    }

    for (final founder in state.ownUnits) {
      if (!CityFoundingRules.canFoundCityWith(founder)) continue;
      if (founder.isWorking || founder.queuedPath != null) continue;
      final origin = HexCoordinate(col: founder.col, row: founder.row);
      if (mctsOwnMilitaryNear(state, origin.col, origin.row, 2, context)) {
        continue;
      }
      if (mctsVisibleMilitaryNear(state, origin.col, origin.row, 3, context)) {
        return true;
      }
      final assignment = context.strategicPlan?.settlerAssignments[founder.id];
      if (assignment != null &&
          mctsVisibleMilitaryNear(
            state,
            assignment.col,
            assignment.row,
            3,
            context,
          )) {
        return true;
      }
      final nearestEnemyCity =
          AiCityFoundingSafety.nearestRememberedEnemyCityDistance(
            view: state.view,
            hex: origin,
          );
      if (nearestEnemyCity != null && nearestEnemyCity <= 3) return true;
    }
    return false;
  }

  bool get wantsMoreCities {
    return assessment.cityCount + assessment.settlerCount <=
        assessment.desiredCityCount;
  }

  bool get needsCitySiteScoutProduction {
    final plan = context.strategicPlan;
    if (!AiFrontierExplorationScorer.needsCitySiteDiscovery(
      view: state.view,
      plan: plan,
    )) {
      return false;
    }
    if (mctsHasAvailableReconCitySiteScout(state.view, plan)) return false;
    return !state.view.ownCities.any((city) {
      final target = city.productionQueue?.target;
      return target is UnitProductionTarget && mctsIsReconType(target.unitType);
    });
  }

  bool get hasLocalEnemyPressure {
    for (final city in state.ownCities) {
      final center = HexCoordinate(col: city.center.col, row: city.center.row);
      for (final enemy in state.visibleTargetableEnemyUnits) {
        final stats = UnitCombatStats.derive(
          enemy,
          ruleset: state.view.ruleset.combat,
        );
        if (stats.attack <= 0 && stats.defense <= 0) continue;
        final enemyHex = HexCoordinate(col: enemy.col, row: enemy.row);
        if (HexDistance.between(center, enemyHex) <= 3) return true;
      }
    }
    return false;
  }
}
