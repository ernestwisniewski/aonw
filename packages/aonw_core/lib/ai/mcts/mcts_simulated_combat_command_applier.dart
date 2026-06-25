import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class MctsSimulatedCombatCommandApplier {
  const MctsSimulatedCombatCommandApplier({
    required this.view,
    required this.ownUnits,
    required this.visibleEnemyUnits,
    required this.ownCities,
    required this.rememberedEnemyCities,
    required this.ownResearch,
  });

  final GameView view;
  final List<GameUnit> ownUnits;
  final List<GameUnit> visibleEnemyUnits;
  final List<GameCity> ownCities;
  final List<GameCity> rememberedEnemyCities;
  final PlayerResearchState ownResearch;

  MctsSimulatedCommandApplication applyAttackHex(AttackHexCommand command) {
    final attackerIndex = _unitIndexById(ownUnits, command.attackerUnitId);
    if (attackerIndex == null) return _unchangedCommandApplication;
    final attacker = ownUnits[attackerIndex];
    if (attacker.isWorking || attacker.movementPoints <= 0) {
      return _unchangedCommandApplication;
    }

    final attackerTile = view.mapData.tileAt(attacker.col, attacker.row);
    final defenderTile = view.mapData.tileAt(
      command.defenderCol,
      command.defenderRow,
    );
    if (attackerTile == null || defenderTile == null) {
      return _unchangedCommandApplication;
    }
    final ownBlockerIndex = _unitIndexAt(
      ownUnits,
      command.defenderCol,
      command.defenderRow,
    );
    if (ownBlockerIndex != null && ownBlockerIndex != attackerIndex) {
      return _unchangedCommandApplication;
    }

    final defenderIndex = _unitIndexAt(
      visibleEnemyUnits,
      command.defenderCol,
      command.defenderRow,
    );
    if (defenderIndex == null) {
      return _applyAttackCity(
        command,
        attacker: attacker,
        attackerIndex: attackerIndex,
        attackerTile: attackerTile,
      );
    }
    final defender = visibleEnemyUnits[defenderIndex];
    if (defender.ownerPlayerId == attacker.ownerPlayerId) {
      return _unchangedCommandApplication;
    }
    if (!view.canTargetPlayer(defender.ownerPlayerId)) {
      return _unchangedCommandApplication;
    }

    final combatants = _combatantsFor(
      attacker: attacker,
      defender: defender,
      attackerTile: attackerTile,
      defenderTile: defenderTile,
    );
    if (combatants.attacker.effective.attack <= 0) {
      return _unchangedCommandApplication;
    }
    if (_distance(attacker, defender) > combatants.attacker.effective.range) {
      return _unchangedCommandApplication;
    }

    final allKnownUnits = [...ownUnits, ...visibleEnemyUnits];
    final retreatDestination = combatants.defender.effective.attack > 0
        ? CombatRetreatResolver.destination(
            attacker: attacker,
            defender: defender,
            units: allKnownUnits,
            tileAt: view.mapData.tileAt,
          )
        : null;
    final outcome = CombatResolver.resolve(
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

    final nextOwnUnits = [...ownUnits];
    final nextVisibleEnemyUnits = [...visibleEnemyUnits];
    final nextOwnCities = ownCities;
    final nextRememberedEnemyCities = rememberedEnemyCities;

    final attackerExperience = UnitVeterancyRules.experienceAwardForCombat(
      unit: attacker,
      survived: !outcome.attackerKilled,
      defeatedEnemy: outcome.defenderKilled,
    );
    final defenderExperience = UnitVeterancyRules.experienceAwardForCombat(
      unit: defender,
      survived: !outcome.defenderKilled,
      defeatedEnemy: outcome.attackerKilled,
    );

    if (outcome.attackerKilled) {
      nextOwnUnits.removeAt(attackerIndex);
    } else {
      nextOwnUnits[attackerIndex] = _withCombatState(
        attacker,
        hitPoints: outcome.attackerHpAfter,
        maxHitPoints: combatants.attacker.maxHp,
        movementPoints: 0,
        experienceAward: attackerExperience,
      );
    }

    if (outcome.defenderKilled) {
      nextVisibleEnemyUnits.removeAt(defenderIndex);
    } else {
      nextVisibleEnemyUnits[defenderIndex] = _withCombatState(
        defender,
        hitPoints: outcome.defenderHpAfter,
        maxHitPoints: combatants.defender.maxHp,
        retreatDestination: outcome.defenderRetreated
            ? retreatDestination
            : null,
        experienceAward: defenderExperience,
      );
    }

    return (
      nextOwnUnits: List.unmodifiable(nextOwnUnits),
      nextVisibleEnemyUnits: List.unmodifiable(nextVisibleEnemyUnits),
      nextOwnCities: nextOwnCities,
      nextRememberedEnemyCities: nextRememberedEnemyCities,
      nextOwnResearch: ownResearch,
    );
  }

  MctsSimulatedCommandApplication _applyAttackCity(
    AttackHexCommand command, {
    required GameUnit attacker,
    required int attackerIndex,
    required TileData attackerTile,
  }) {
    final cityIndex = _rememberedEnemyCityIndexAt(
      command.defenderCol,
      command.defenderRow,
    );
    if (cityIndex == null) return _unchangedCommandApplication;
    final city = rememberedEnemyCities[cityIndex];
    if (city.ownerPlayerId == attacker.ownerPlayerId) {
      return _unchangedCommandApplication;
    }
    if (!view.canTargetPlayer(city.ownerPlayerId)) {
      return _unchangedCommandApplication;
    }

    final defenderTile = view.mapData.tileAt(city.center.col, city.center.row);
    if (defenderTile == null) return _unchangedCommandApplication;

    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: ownResearch,
      ruleset: view.ruleset.combat,
      technologyRuleset: view.ruleset.technology,
    );
    final attackerBaseStats = UnitCombatStats.derive(
      attacker,
      ruleset: view.ruleset.combat,
    );
    final attackerEffective = attackerBaseStats.applyAll(attackerModifiers);
    if (attackerEffective.attack <= 0) return _unchangedCommandApplication;
    if (_distanceToHex(attacker, city.center) > attackerEffective.range) {
      return _unchangedCommandApplication;
    }

    final cityBaseStats = view.ruleset.combat.cityBaseStats;
    if (cityBaseStats.hp <= 0) return _unchangedCommandApplication;
    final outcome = CombatResolver.resolve(
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
        unitId: city.id,
        ownerPlayerId: city.ownerPlayerId,
        baseStats: cityBaseStats,
        currentHp: CityCombatHealth.currentHp(
          city,
          effectiveStats: cityBaseStats,
        ),
      ),
      rng: CombatRng.fromTurn(
        turn: view.turn,
        attackerId: attacker.id,
        defenderId: city.id,
      ),
      ruleset: view.ruleset.combat,
    );

    final nextOwnUnits = [...ownUnits];
    if (outcome.attackerKilled) {
      nextOwnUnits.removeAt(attackerIndex);
    } else {
      final attackerExperience = UnitVeterancyRules.experienceAwardForCombat(
        unit: attacker,
        survived: true,
        defeatedEnemy: outcome.defenderKilled,
      );
      nextOwnUnits[attackerIndex] = _withCombatState(
        attacker,
        hitPoints: outcome.attackerHpAfter,
        maxHitPoints: attackerEffective.hp,
        movementPoints: 0,
        experienceAward: attackerExperience,
      );
    }

    var nextOwnCities = ownCities;
    final nextRememberedEnemyCities = [...rememberedEnemyCities];
    if (outcome.defenderKilled) {
      nextRememberedEnemyCities.removeAt(cityIndex);
      if (command.cityConquestAction == CityConquestAction.capture) {
        nextOwnCities = List.unmodifiable([
          ...ownCities,
          city.copyWith(
            ownerPlayerId: attacker.ownerPlayerId,
            hitPoints: CityCombatHealth.capturedHp(
              effectiveStats: cityBaseStats,
            ),
          ),
        ]);
      }
    } else {
      nextRememberedEnemyCities[cityIndex] = city.copyWithHitPoints(
        CityCombatHealth.storedHp(
          outcome.defenderHpAfter,
          effectiveStats: cityBaseStats,
        ),
      );
    }

    return (
      nextOwnUnits: List.unmodifiable(nextOwnUnits),
      nextVisibleEnemyUnits: visibleEnemyUnits,
      nextOwnCities: nextOwnCities,
      nextRememberedEnemyCities: List.unmodifiable(nextRememberedEnemyCities),
      nextOwnResearch: ownResearch,
    );
  }

  ({Combatant attacker, Combatant defender}) _combatantsFor({
    required GameUnit attacker,
    required GameUnit defender,
    required TileData attackerTile,
    required TileData defenderTile,
  }) {
    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: ownResearch,
      defender: defender,
      defenderTile: defenderTile,
      ruleset: view.ruleset.combat,
      technologyRuleset: view.ruleset.technology,
    );
    final defenderModifiers = CombatModifierCollector.forDefender(
      unit: defender,
      tile: defenderTile,
      defendedCity: _cityAt(defender.col, defender.row),
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

  GameUnit _withCombatState(
    GameUnit unit, {
    required int hitPoints,
    required int maxHitPoints,
    int? movementPoints,
    HexCoordinate? retreatDestination,
    int experienceAward = 0,
  }) {
    final updated = unit.copyWith(
      col: retreatDestination?.col,
      row: retreatDestination?.row,
      movementPoints: retreatDestination == null ? movementPoints : 0,
    );
    final withHitPoints = updated.copyWithHitPoints(
      hitPoints >= maxHitPoints ? null : hitPoints,
    );
    return UnitVeterancyRules.addExperience(withHitPoints, experienceAward);
  }

  GameCity? _cityAt(int col, int row) {
    for (final city in ownCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    for (final city in rememberedEnemyCities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    return null;
  }

  int? _rememberedEnemyCityIndexAt(int col, int row) {
    for (var i = 0; i < rememberedEnemyCities.length; i++) {
      if (rememberedEnemyCities[i].occupiesCenter(col, row)) return i;
    }
    return null;
  }

  MctsSimulatedCommandApplication get _unchangedCommandApplication => (
    nextOwnUnits: ownUnits,
    nextVisibleEnemyUnits: visibleEnemyUnits,
    nextOwnCities: ownCities,
    nextRememberedEnemyCities: rememberedEnemyCities,
    nextOwnResearch: ownResearch,
  );

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static int? _unitIndexAt(List<GameUnit> units, int col, int row) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].occupies(col, row)) return i;
    }
    return null;
  }

  static int _distance(GameUnit a, GameUnit b) {
    return HexDistance.between(
      HexCoordinate(col: a.col, row: a.row),
      HexCoordinate(col: b.col, row: b.row),
    );
  }

  static int _distanceToHex(GameUnit unit, CityHex hex) {
    return HexDistance.between(
      HexCoordinate(col: unit.col, row: unit.row),
      hex.toCoordinate(),
    );
  }
}
