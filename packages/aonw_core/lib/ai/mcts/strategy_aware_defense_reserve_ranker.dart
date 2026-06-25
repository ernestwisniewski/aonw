part of 'strategy_aware_defense_ranker.dart';

class _LastMilitaryReserveRanker {
  const _LastMilitaryReserveRanker();

  CommandRanking? rank(GameCommand command, GameView view, AiContext context) {
    if (!needsMilitaryReserve(view, context)) return null;

    return switch (command) {
      AttackHexCommand() => rankAttack(command, view, context),
      MoveUnitCommand() => rankMove(command, view, context),
      FortifyUnitCommand() => rankFortify(command, view, context),
      StartUnitProductionCommand() => rankUnitProduction(
        command,
        view,
        context,
      ),
      _ => null,
    };
  }

  CommandRanking? rankAttack(
    AttackHexCommand command,
    GameView view,
    AiContext context,
  ) {
    final attacker = ownUnitById(view, command.attackerUnitId);
    if (attacker == null || !_military.isOnly(attacker, view, context)) {
      return null;
    }

    final defender = enemyAt(view, command.defenderCol, command.defenderRow);
    if (defender == null ||
        !isNearOwnCity(view, defender.col, defender.row, 2)) {
      return _blockedDefense;
    }
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
    if (!_military.isSafeLastMilitaryAttack(evaluation)) {
      return _blockedDefense;
    }

    final distance = nearestOwnCityDistance(view, defender.col, defender.row);
    return CommandRanking(
      CandidatePriority.defense,
      780 -
          distance * 12 +
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
    AiContext context,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null || !_military.isOnly(unit, view, context)) {
      return null;
    }

    final city = nearestOwnCity(view, unit.col, unit.row);
    if (city == null) return null;
    final improvement = distanceImprovement(
      fromCol: unit.col,
      fromRow: unit.row,
      toCol: command.targetCol,
      toRow: command.targetRow,
      target: city.center.toCoordinate(),
    );
    if (improvement <= 0) return _blockedReserveMove;

    return CommandRanking(CandidatePriority.defense, 760 + improvement * 28);
  }

  CommandRanking? rankFortify(
    FortifyUnitCommand command,
    GameView view,
    AiContext context,
  ) {
    final unit = ownUnitById(view, command.unitId);
    if (unit == null || !_military.isOnly(unit, view, context)) {
      return null;
    }
    final distance = nearestOwnCityDistance(view, unit.col, unit.row);
    if (distance > 1) return null;

    final stats = UnitCombatStats.derive(unit, ruleset: context.ruleset.combat);
    final hp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    final hpDeficit = (stats.hp - hp).clamp(0, stats.hp).toDouble();
    return CommandRanking(
      CandidatePriority.defense,
      790 + hpDeficit * 8 - distance * 10,
    );
  }

  CommandRanking? rankUnitProduction(
    StartUnitProductionCommand command,
    GameView view,
    AiContext context,
  ) {
    if (!_military.isType(command.unitType, context)) return null;
    if (ownCityById(view, command.cityId) == null) return null;

    final militaryCount = _military.countWithQueues(view, context);
    if (militaryCount > 1) return null;
    if (militaryCount == 1 && !needsReserveDefenderProduction(view, context)) {
      return null;
    }

    final emptyArmyBonus = militaryCount == 0 ? 140.0 : 0.0;
    return CommandRanking(
      CandidatePriority.defense,
      770 + emptyArmyBonus + context.civProfile.belligerence * 24,
    );
  }
}
