part of 'combat_tactics.dart';

final class _UnitAttackEvaluationBuilder {
  const _UnitAttackEvaluationBuilder();

  AiAttackEvaluation? evaluate({
    required GameView view,
    required AiContext context,
    required AttackHexCommand command,
  }) {
    final attacker = _CombatTacticsQueries.activeOwnAttacker(
      view,
      command.attackerUnitId,
    );
    if (attacker == null) return null;

    final defender = _CombatTacticsQueries.targetableEnemyUnitAt(
      view: view,
      col: command.defenderCol,
      row: command.defenderRow,
      attacker: attacker,
    );
    if (defender == null) return null;

    final tiles = _CombatTacticsQueries.unitAttackTiles(
      view: view,
      attacker: attacker,
      defender: defender,
    );
    if (tiles == null) return null;

    final combatants = _CombatTacticsQueries.combatantsForUnitAttack(
      view: view,
      attacker: attacker,
      defender: defender,
      attackerTile: tiles.attacker,
      defenderTile: tiles.defender,
    );
    final attackerEffective = combatants.attacker.effective;
    final defenderEffective = combatants.defender.effective;
    if (!_canAttackUnit(attacker, defender, attackerEffective)) return null;

    final outcome = _resolveAttack(
      view: view,
      attacker: attacker,
      defender: defender,
      combatants: combatants,
      defenderEffective: defenderEffective,
    );
    final evaluation = _evaluationFromOutcome(
      view: view,
      command: command,
      attacker: attacker,
      defender: defender,
      combatants: combatants,
      outcome: outcome,
      rangedAttack: attackerEffective.range > 1,
    );
    return evaluation.withHeuristicScore(
      _CombatHeuristicScorer.unit(evaluation),
    );
  }

  bool _canAttackUnit(
    GameUnit attacker,
    GameUnit defender,
    CombatStats attackerEffective,
  ) {
    return attackerEffective.attack > 0 &&
        _CombatTacticsQueries.unitDistance(attacker, defender) <=
            attackerEffective.range;
  }

  CombatOutcome _resolveAttack({
    required GameView view,
    required GameUnit attacker,
    required GameUnit defender,
    required ({Combatant attacker, Combatant defender}) combatants,
    required CombatStats defenderEffective,
  }) {
    final retreatDestination = defenderEffective.attack > 0
        ? CombatRetreatResolver.destination(
            attacker: attacker,
            defender: defender,
            units: view.movementBlockingUnits,
            tileAt: view.mapData.tileAt,
          )
        : null;
    return CombatResolver.resolve(
      attacker: combatants.attacker,
      defender: combatants.defender,
      rng: CombatRng.fromTurn(
        turn: view.turn,
        attackerId: attacker.id,
        defenderId: defender.id,
      ),
      ruleset: view.ruleset.combat,
      defenderCanRetreat: retreatDestination != null,
    );
  }

  AiAttackEvaluation _evaluationFromOutcome({
    required GameView view,
    required AttackHexCommand command,
    required GameUnit attacker,
    required GameUnit defender,
    required ({Combatant attacker, Combatant defender}) combatants,
    required CombatOutcome outcome,
    required bool rangedAttack,
  }) {
    final defenderHpBefore = combatants.defender.currentHp;
    final attackerHpBefore = combatants.attacker.currentHp;
    final defenderHpAfter = outcome.defenderKilled
        ? 0
        : outcome.defenderHpAfter;
    final attackerHpAfter = outcome.attackerKilled
        ? 0
        : outcome.attackerHpAfter;
    final defenderDamage = math.max(0, defenderHpBefore - defenderHpAfter);
    final attackerDamage = math.max(0, attackerHpBefore - attackerHpAfter);

    return AiAttackEvaluation(
      command: command,
      attacker: attacker,
      defender: defender,
      defenderDamage: defenderDamage,
      attackerDamage: attackerDamage,
      defenderHpBefore: defenderHpBefore,
      attackerHpBefore: attackerHpBefore,
      defenderHpAfter: defenderHpAfter,
      attackerHpAfter: attackerHpAfter,
      defenderKilled: outcome.defenderKilled,
      attackerKilled: outcome.attackerKilled,
      defenderRetreated: outcome.defenderRetreated,
      targetIsCivilian: !_CombatTacticsQueries.isMilitaryUnit(
        defender,
        view.ruleset.combat,
      ),
      capturesCity: false,
      rangedAttack: rangedAttack,
      nearestOwnCityDistance: _CombatTacticsQueries.nearestOwnCityDistance(
        view,
        defender.col,
        defender.row,
      ),
      heuristicScore: 0,
    );
  }
}

final class _CityAttackEvaluationBuilder {
  const _CityAttackEvaluationBuilder();

  AiCityAttackEvaluation? evaluate({
    required GameView view,
    required AiContext context,
    required AttackHexCommand command,
  }) {
    final attacker = _CombatTacticsQueries.activeOwnAttacker(
      view,
      command.attackerUnitId,
    );
    if (attacker == null) return null;

    final city = _CombatTacticsQueries.targetableEnemyCityAt(
      view: view,
      col: command.defenderCol,
      row: command.defenderRow,
      attacker: attacker,
    );
    if (city == null) return null;

    final tiles = _CombatTacticsQueries.cityAttackTiles(
      view: view,
      attacker: attacker,
      city: city,
    );
    if (tiles == null) return null;

    final attackerCombatant = _CombatTacticsQueries.attackerCombatantForCity(
      view: view,
      attacker: attacker,
      attackerTile: tiles.attacker,
      context: context,
    );
    final attackerEffective = attackerCombatant.effective;
    if (!_canAttackCity(attacker, city, attackerEffective)) return null;

    final cityBaseStats = context.ruleset.combat.cityBaseStats;
    if (cityBaseStats.hp <= 0) return null;

    final cityCombatant = _CombatTacticsQueries.cityCombatant(
      city: city,
      baseStats: cityBaseStats,
    );
    final outcome = CombatResolver.resolve(
      attacker: attackerCombatant,
      defender: cityCombatant,
      rng: CombatRng.fromTurn(
        turn: view.turn,
        attackerId: attacker.id,
        defenderId: city.id,
      ),
      ruleset: context.ruleset.combat,
    );
    final evaluation = _evaluationFromOutcome(
      view: view,
      command: command,
      attacker: attacker,
      city: city,
      attackerCombatant: attackerCombatant,
      cityCombatant: cityCombatant,
      outcome: outcome,
      rangedAttack: attackerEffective.range > 1,
    );
    return evaluation.withHeuristicScore(
      _CombatHeuristicScorer.city(evaluation),
    );
  }

  bool _canAttackCity(
    GameUnit attacker,
    GameCity city,
    CombatStats attackerEffective,
  ) {
    return attackerEffective.attack > 0 &&
        _CombatTacticsQueries.distanceToCity(attacker, city.center) <=
            attackerEffective.range;
  }

  AiCityAttackEvaluation _evaluationFromOutcome({
    required GameView view,
    required AttackHexCommand command,
    required GameUnit attacker,
    required GameCity city,
    required Combatant attackerCombatant,
    required Combatant cityCombatant,
    required CombatOutcome outcome,
    required bool rangedAttack,
  }) {
    final defenderHpBefore = cityCombatant.currentHp;
    final attackerHpBefore = attackerCombatant.currentHp;
    final defenderHpAfter = outcome.defenderKilled
        ? 0
        : outcome.defenderHpAfter;
    final attackerHpAfter = outcome.attackerKilled
        ? 0
        : outcome.attackerHpAfter;

    return AiCityAttackEvaluation(
      command: command,
      attacker: attacker,
      city: city,
      defenderDamage: math.max(0, defenderHpBefore - defenderHpAfter),
      attackerDamage: math.max(0, attackerHpBefore - attackerHpAfter),
      defenderHpBefore: defenderHpBefore,
      attackerHpBefore: attackerHpBefore,
      defenderHpAfter: defenderHpAfter,
      attackerHpAfter: attackerHpAfter,
      cityDefeated: outcome.defenderKilled,
      attackerKilled: outcome.attackerKilled,
      rangedAttack: rangedAttack,
      nearestOwnCityDistance: _CombatTacticsQueries.nearestOwnCityDistance(
        view,
        city.center.col,
        city.center.row,
      ),
      heuristicScore: 0,
    );
  }
}
