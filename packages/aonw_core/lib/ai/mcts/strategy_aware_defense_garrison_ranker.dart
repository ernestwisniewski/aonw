part of 'strategy_aware_defense_ranker.dart';

class _ReservedGarrisonRanker {
  const _ReservedGarrisonRanker();

  CommandRanking? rank(
    GameCommand command,
    GameView view,
    AiContext context,
    StrategicPlan plan,
  ) {
    final unitId = unitIdForCommand(command);
    if (unitId == null) return null;

    final defense = assignedDefenseFor(plan, unitId);
    if (defense == null) return null;

    return switch (command) {
      AttackHexCommand() => rankAttack(command, view, context, defense),
      MoveUnitCommand() => rankMove(command, view, defense),
      FortifyUnitCommand() => _generalDefenseRanker.rankFortify(
        command,
        view,
        plan,
      ),
      _ => null,
    };
  }

  CommandRanking? rankPinnedMove(
    MoveUnitCommand command,
    GameView view,
    StrategicPlan plan,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null) return null;

    final defense = assignedDefenseFor(plan, unit.id);
    if (defense == null || defense.threatLevel <= 0) return null;

    final cityCenter = defense.cityCenter.toCoordinate();
    final currentDistance = HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      cityCenter,
    );
    final targetDistance = HexDistance.between(
      HexCoordinate(col: command.targetCol, row: command.targetRow),
      cityCenter,
    );
    if (targetDistance < currentDistance) return null;

    return _blockedDefense;
  }

  CommandRanking rankAttack(
    AttackHexCommand command,
    GameView view,
    AiContext context,
    StrategicDefenseAssignment defense,
  ) {
    final attacker = ownUnitById(view, command.attackerUnitId);
    if (attacker == null) return _blockedDefense;

    final defender = enemyAt(view, command.defenderCol, command.defenderRow);
    if (defender == null) return _blockedDefense;

    final distance = HexDistance.between(
      HexCoordinate(col: defender.col, row: defender.row),
      defense.cityCenter.toCoordinate(),
    );
    if (defense.threatLevel <= 0 && distance > 1) return _blockedDefense;
    if (distance > 2) return _blockedDefense;

    if (!_military.lastMilitarySurvivesAttack(
      attacker: attacker,
      defender: defender,
      context: context,
    )) {
      return _blockedDefense;
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
      return _blockedDefense;
    }
    if (_military.isOnly(attacker, view, context) &&
        !_military.isSafeLastMilitaryAttack(evaluation)) {
      return _blockedDefense;
    }

    return CommandRanking(
      CandidatePriority.defense,
      740 +
          defense.threatLevel * 14 -
          distance * 10 +
          AiCombatTactics.rankingBonus(
            evaluation,
            context,
            defendingCity: true,
          ),
    );
  }

  CommandRanking rankMove(
    MoveUnitCommand command,
    GameView view,
    StrategicDefenseAssignment defense,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null) return _blockedDefense;

    final target = defense.cityCenter.toCoordinate();
    final improvement = distanceImprovement(
      fromCol: unit.col,
      fromRow: unit.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: target,
    );
    if (improvement > 0) {
      return CommandRanking(
        CandidatePriority.defense,
        720 + defense.threatLevel * 18 + improvement * 20,
      );
    }

    final targetDistance = HexDistance.between(
      HexCoordinate(col: command.targetCol, row: command.targetRow),
      target,
    );
    if (targetDistance <= 1) {
      return CommandRanking(
        CandidatePriority.defense,
        700 + defense.threatLevel * 14 - targetDistance * 8,
      );
    }

    return _blockedDefense;
  }
}
