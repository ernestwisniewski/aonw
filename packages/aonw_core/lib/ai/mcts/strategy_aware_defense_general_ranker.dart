part of 'strategy_aware_defense_ranker.dart';

class _GeneralDefenseRanker {
  const _GeneralDefenseRanker();

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    return switch (command) {
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
        CandidatePriority.defense,
        720 + defense.threatLevel * 24 + improvement * 20,
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

    final defense = assignedDefenseFor(plan, unit.id);
    if (defense == null) return null;
    final distance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      defense.cityCenter.toCoordinate(),
    );
    if (distance > 1) return null;

    return CommandRanking(
      CandidatePriority.defense,
      735 + defense.threatLevel * 16 - distance * 8,
    );
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

    final missingGarrisonBonus = defense.hasAssignedGarrison ? 0.0 : 120.0;
    return CommandRanking(
      CandidatePriority.defense,
      700 + missingGarrisonBonus + defense.threatLevel * 24,
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

    return CommandRanking(
      CandidatePriority.defense,
      660 + defense.threatLevel * 18,
    );
  }
}
