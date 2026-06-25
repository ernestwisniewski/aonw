part of 'combat_tactics.dart';

abstract final class _CombatTacticsQueries {
  static GameUnit? activeOwnAttacker(GameView view, String unitId) {
    final unit = ownUnitById(view, unitId);
    if (unit == null) return null;
    if (unit.isWorking || unit.movementPoints <= 0) return null;
    return unit;
  }

  static GameUnit? ownUnitById(GameView view, String unitId) {
    for (final unit in view.ownUnits) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  static GameUnit? targetableEnemyUnitAt({
    required GameView view,
    required int col,
    required int row,
    required GameUnit attacker,
  }) {
    final defender = enemyAt(view, col, row);
    if (defender == null) return null;
    if (defender.ownerPlayerId == attacker.ownerPlayerId) return null;
    if (!view.canTargetPlayer(defender.ownerPlayerId)) return null;
    return defender;
  }

  static GameUnit? enemyAt(GameView view, int col, int row) {
    for (final unit in view.visibleEnemyUnits) {
      if (unit.col == col && unit.row == row) return unit;
    }
    return null;
  }

  static GameCity? targetableEnemyCityAt({
    required GameView view,
    required int col,
    required int row,
    required GameUnit attacker,
  }) {
    final city = enemyCityAt(view, col, row);
    if (city == null) return null;
    if (city.ownerPlayerId == attacker.ownerPlayerId) return null;
    if (!view.canTargetPlayer(city.ownerPlayerId)) return null;
    return city;
  }

  static GameCity? enemyCityAt(GameView view, int col, int row) {
    for (final city in view.rememberedEnemyCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    return null;
  }

  static ({TileData attacker, TileData defender})? unitAttackTiles({
    required GameView view,
    required GameUnit attacker,
    required GameUnit defender,
  }) {
    final attackerTile = view.mapData.tileAt(attacker.col, attacker.row);
    final defenderTile = view.mapData.tileAt(defender.col, defender.row);
    if (attackerTile == null || defenderTile == null) return null;
    return (attacker: attackerTile, defender: defenderTile);
  }

  static ({TileData attacker, TileData defender})? cityAttackTiles({
    required GameView view,
    required GameUnit attacker,
    required GameCity city,
  }) {
    final attackerTile = view.mapData.tileAt(attacker.col, attacker.row);
    final defenderTile = view.mapData.tileAt(city.center.col, city.center.row);
    if (attackerTile == null || defenderTile == null) return null;
    return (attacker: attackerTile, defender: defenderTile);
  }

  static ({Combatant attacker, Combatant defender}) combatantsForUnitAttack({
    required GameView view,
    required GameUnit attacker,
    required GameUnit defender,
    required TileData attackerTile,
    required TileData defenderTile,
  }) {
    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: view.ownResearch,
      defender: defender,
      defenderTile: defenderTile,
      ruleset: view.ruleset.combat,
      technologyRuleset: view.ruleset.technology,
    );
    final defenderModifiers = CombatModifierCollector.forDefender(
      unit: defender,
      tile: defenderTile,
      defendedCity: cityAt(view, defender.col, defender.row),
      research: PlayerResearchState.empty,
      attacker: attacker,
      ruleset: view.ruleset.combat,
      technologyRuleset: view.ruleset.technology,
    );
    final attackerBaseStats = UnitCombatStats.derive(
      attacker,
      ruleset: view.ruleset.combat,
    );
    final defenderBaseStats = UnitCombatStats.derive(
      defender,
      ruleset: view.ruleset.combat,
    );
    final attackerEffective = attackerBaseStats.applyAll(attackerModifiers);
    final defenderEffective = defenderBaseStats.applyAll(defenderModifiers);
    return (
      attacker: Combatant(
        unitId: attacker.id,
        ownerPlayerId: attacker.ownerPlayerId,
        baseStats: attackerBaseStats,
        modifiers: attackerModifiers,
        currentHp: UnitCombatHealth.currentHp(
          attacker,
          effectiveStats: attackerEffective,
        ),
      ),
      defender: Combatant(
        unitId: defender.id,
        ownerPlayerId: defender.ownerPlayerId,
        baseStats: defenderBaseStats,
        modifiers: defenderModifiers,
        currentHp: UnitCombatHealth.currentHp(
          defender,
          effectiveStats: defenderEffective,
        ),
      ),
    );
  }

  static Combatant attackerCombatantForCity({
    required GameView view,
    required GameUnit attacker,
    required TileData attackerTile,
    required AiContext context,
  }) {
    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: view.ownResearch,
      ruleset: context.ruleset.combat,
      technologyRuleset: context.ruleset.technology,
    );
    final attackerBaseStats = UnitCombatStats.derive(
      attacker,
      ruleset: context.ruleset.combat,
    );
    final attackerEffective = attackerBaseStats.applyAll(attackerModifiers);
    return Combatant(
      unitId: attacker.id,
      ownerPlayerId: attacker.ownerPlayerId,
      baseStats: attackerBaseStats,
      modifiers: attackerModifiers,
      currentHp: UnitCombatHealth.currentHp(
        attacker,
        effectiveStats: attackerEffective,
      ),
    );
  }

  static Combatant cityCombatant({
    required GameCity city,
    required CombatStats baseStats,
  }) {
    return Combatant(
      unitId: city.id,
      ownerPlayerId: city.ownerPlayerId,
      baseStats: baseStats,
      currentHp: CityCombatHealth.currentHp(city, effectiveStats: baseStats),
    );
  }

  static GameCity? cityAt(GameView view, int col, int row) {
    for (final city in view.ownCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    for (final city in view.rememberedEnemyCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    return null;
  }

  static int nearestOwnCityDistance(GameView view, int col, int row) {
    var nearest = 1 << 30;
    for (final city in view.ownCities) {
      final distance = HexDistance.between(
        HexCoordinate(col: col, row: row),
        city.center.toCoordinate(),
      );
      if (distance < nearest) nearest = distance;
    }
    return nearest == 1 << 30 ? 99 : nearest;
  }

  static bool isMilitaryUnit(GameUnit unit, CombatRuleset ruleset) {
    if (unit.isWorker ||
        unit.type == GameUnitType.settler ||
        unit.hasSettlers) {
      return false;
    }
    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    return stats.attack > 0 || stats.defense > 0;
  }

  static int unitDistance(GameUnit a, GameUnit b) {
    return HexDistance.between(
      HexCoordinate(col: a.col, row: a.row),
      HexCoordinate(col: b.col, row: b.row),
    );
  }

  static int distanceToCity(GameUnit unit, CityHex hex) {
    return HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      hex.toCoordinate(),
    );
  }
}
