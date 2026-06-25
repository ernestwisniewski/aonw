part of 'strategy_aware_defense_ranker.dart';

class _EarlyCityDefenseRanker {
  const _EarlyCityDefenseRanker();

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    if (!needsEarlyCityDefense(view, context, plan)) return null;

    return switch (command) {
      AttackHexCommand() => rankAttack(command, view, context, plan),
      MoveUnitCommand() => rankMove(command, view, plan),
      FortifyUnitCommand() => rankFortify(command, view, plan),
      StartUnitProductionCommand() => rankUnitProduction(
        command,
        view,
        context,
        plan,
      ),
      StartBuildingCommand() => rankBuilding(command, plan),
      _ => null,
    };
  }

  CommandRanking rankAttack(
    AttackHexCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final defender = enemyAt(view, command.defenderCol, command.defenderRow);
    if (defender == null) return _blockedEarlyDefense;

    final defenseTarget = _closestDefenseTo(defender.col, defender.row, plan);
    if (defenseTarget == null || defenseTarget.distance > 2) {
      return _blockedEarlyDefense;
    }

    final evaluation = AiCombatTactics.evaluateAttack(
      view: view,
      context: context,
      command: command,
    );
    if (evaluation == null ||
        !AiCombatTactics.shouldConsiderAttack(
          evaluation,
          context,
          defendingCity: true,
        )) {
      return _blockedEarlyDefense;
    }

    final attacker = ownUnitById(view, command.attackerUnitId);
    if (attacker != null &&
        _military.isOnly(attacker, view, context) &&
        !_military.isSafeLastMilitaryAttack(evaluation)) {
      return _blockedEarlyDefense;
    }

    final defense = defenseTarget.defense;
    final assignedBonus =
        defense.assignedUnitIds.contains(command.attackerUnitId) ? 32.0 : 0.0;
    return CommandRanking(
      CandidatePriority.opening,
      1230 +
          defense.threatLevel * 10 +
          assignedBonus -
          defenseTarget.distance * 8 +
          AiCombatTactics.rankingBonus(
            evaluation,
            context,
            defendingCity: true,
          ),
    );
  }

  CommandRanking? rankMove(
    MoveUnitCommand command,
    GameView view,
    StrategicPlan plan,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null) return null;

    for (final defense in plan.defenses.values) {
      if (!defense.assignedUnitIds.contains(unit.id)) continue;
      final improvement = distanceImprovement(
        fromCol: unit.col,
        fromRow: unit.row,
        toCol: command.targetCol,
        toRow: command.targetRow,
        target: defense.cityCenter.toCoordinate(),
      );
      if (improvement <= 0) continue;
      return CommandRanking(
        CandidatePriority.opening,
        1210 + defense.threatLevel * 12 + improvement * 24,
      );
    }

    return null;
  }

  CommandRanking? rankFortify(
    FortifyUnitCommand command,
    GameView view,
    StrategicPlan plan,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null) return null;

    for (final defense in plan.defenses.values) {
      if (!defense.assignedUnitIds.contains(unit.id)) continue;
      final distance = HexDistance.between(
        HexCoordinate(col: unit.col, row: unit.row),
        defense.cityCenter.toCoordinate(),
      );
      if (distance > 1) continue;
      return CommandRanking(
        CandidatePriority.opening,
        1220 + defense.threatLevel * 12 - distance * 8,
      );
    }

    return null;
  }

  CommandRanking? rankUnitProduction(
    StartUnitProductionCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final defense = plan.defenses[command.cityId];
    if (defense == null || !_military.isType(command.unitType, context)) {
      return null;
    }

    final requiredMilitary = coreDefenseMilitaryTarget(view, context, plan);
    if (defense.hasAssignedGarrison &&
        _military.countWithQueues(view, context) >= requiredMilitary) {
      return null;
    }

    final missingGarrisonBonus = defense.hasAssignedGarrison ? 0.0 : 160.0;
    return CommandRanking(
      CandidatePriority.opening,
      1200 + missingGarrisonBonus + defense.threatLevel * 16,
    );
  }

  CommandRanking? rankBuilding(
    StartBuildingCommand command,
    StrategicPlan plan,
  ) {
    final defense = plan.defenses[command.cityId];
    if (defense == null || !isMilitaryBuilding(command.buildingType)) {
      return null;
    }

    final missingGarrisonBonus = defense.hasAssignedGarrison ? 0.0 : 80.0;
    return CommandRanking(
      CandidatePriority.defense,
      640 + missingGarrisonBonus + defense.threatLevel * 16,
    );
  }

  _DefenseDistance? _closestDefenseTo(int col, int row, StrategicPlan plan) {
    StrategicDefenseAssignment? closestDefense;
    var closestDistance = 1 << 30;
    for (final defense in plan.defenses.values) {
      final distance = HexDistance.between(
        HexCoordinate(col: col, row: row),
        defense.cityCenter.toCoordinate(),
      );
      if (distance < closestDistance) {
        closestDefense = defense;
        closestDistance = distance;
      }
    }

    final defense = closestDefense;
    if (defense == null) return null;
    return _DefenseDistance(defense, closestDistance);
  }
}

class _DefenseDistance {
  final StrategicDefenseAssignment defense;
  final int distance;

  const _DefenseDistance(this.defense, this.distance);
}
