import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/combat/combat_distance.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier_collector.dart';
import 'package:aonw_core/game/domain/combat/combat_outcome.dart';
import 'package:aonw_core/game/domain/combat/combat_resolver.dart';
import 'package:aonw_core/game/domain/combat/combat_retreat_resolver.dart';
import 'package:aonw_core/game/domain/combat/combat_rng.dart';
import 'package:aonw_core/game/domain/combat/combatant.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_health.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_stats.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_context.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_effects.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_veterancy.dart';

typedef _UnitCombatants = ({Combatant attacker, Combatant defender});

abstract final class UnitTurnCombatResolver {
  static void resolve({
    required int attackerIndex,
    required int defenderIndex,
    required TurnCombatContext context,
    required TurnCombatEffects effects,
  }) {
    final attacker = effects.units[attackerIndex];
    final defender = effects.units[defenderIndex];
    if (!_canAttack(attacker, defender, effects)) return;

    final combatants = _combatantsFor(
      attacker: attacker,
      defender: defender,
      context: context,
      effects: effects,
    );
    if (combatants.attacker.effective.attack <= 0) return;
    final distance = CombatDistance.betweenUnits(attacker, defender);
    if (distance > combatants.attacker.effective.range) return;

    final resolution = _executeAttack(
      attacker: attacker,
      defender: defender,
      combatants: combatants,
      attackDistance: distance,
      context: context,
      effects: effects,
    );
    _recordOpeningEvents(
      attacker: attacker,
      defender: defender,
      outcome: resolution.outcome,
      retreat: resolution.retreat,
      effects: effects,
    );
    _applyOutcome(
      attacker: attacker,
      defender: defender,
      attackerIndex: attackerIndex,
      defenderIndex: defenderIndex,
      combatants: combatants,
      outcome: resolution.outcome,
      retreat: resolution.retreat,
      effects: effects,
    );
  }

  static bool _canAttack(
    GameUnit attacker,
    GameUnit defender,
    TurnCombatEffects effects,
  ) {
    if (attacker.ownerPlayerId == defender.ownerPlayerId) return false;
    return !effects.isProtectedRelation(
      attacker.ownerPlayerId,
      defender.ownerPlayerId,
    );
  }

  static _UnitCombatants _combatantsFor({
    required GameUnit attacker,
    required GameUnit defender,
    required TurnCombatContext context,
    required TurnCombatEffects effects,
  }) {
    final attackerTile = context.mapTiles?.tileAt(attacker.col, attacker.row);
    final defenderTile = context.mapTiles?.tileAt(defender.col, defender.row);
    final defendedCity = _cityAt(effects, defender.col, defender.row);
    final attackerModifiers = attackerTile == null
        ? const <CombatModifier>[]
        : CombatModifierCollector.forAttacker(
            unit: attacker,
            tile: attackerTile,
            research: context.researchForPlayer(attacker.ownerPlayerId),
            defender: defender,
            defenderTile: defenderTile,
            ruleset: context.ruleset.combat,
            technologyRuleset: context.ruleset.technology,
          );
    final defenderModifiers = defenderTile == null
        ? const <CombatModifier>[]
        : CombatModifierCollector.forDefender(
            unit: defender,
            tile: defenderTile,
            defendedCity: defendedCity,
            research: context.researchForPlayer(defender.ownerPlayerId),
            attacker: attacker,
            ruleset: context.ruleset.combat,
            technologyRuleset: context.ruleset.technology,
          );
    return _buildCombatants(
      attacker: attacker,
      defender: defender,
      attackerModifiers: attackerModifiers,
      defenderModifiers: defenderModifiers,
      context: context,
    );
  }

  static _UnitCombatants _buildCombatants({
    required GameUnit attacker,
    required GameUnit defender,
    required List<CombatModifier> attackerModifiers,
    required List<CombatModifier> defenderModifiers,
    required TurnCombatContext context,
  }) {
    final attackerBase = UnitCombatStats.derive(
      attacker,
      ruleset: context.ruleset.combat,
    );
    final defenderBase = UnitCombatStats.derive(
      defender,
      ruleset: context.ruleset.combat,
    );
    return (
      attacker: Combatant(
        unitId: attacker.id,
        ownerPlayerId: attacker.ownerPlayerId,
        baseStats: attackerBase,
        modifiers: attackerModifiers,
        currentHp: UnitCombatHealth.currentHp(
          attacker,
          effectiveStats: attackerBase.applyAll(attackerModifiers),
        ),
      ),
      defender: Combatant(
        unitId: defender.id,
        ownerPlayerId: defender.ownerPlayerId,
        baseStats: defenderBase,
        modifiers: defenderModifiers,
        currentHp: UnitCombatHealth.currentHp(
          defender,
          effectiveStats: defenderBase.applyAll(defenderModifiers),
        ),
      ),
    );
  }

  static ({CombatOutcome outcome, HexCoordinate? retreat}) _executeAttack({
    required GameUnit attacker,
    required GameUnit defender,
    required _UnitCombatants combatants,
    required int attackDistance,
    required TurnCombatContext context,
    required TurnCombatEffects effects,
  }) {
    effects.diplomacy = effects.diplomacy.registerUnitAttack(
      attackerPlayerId: attacker.ownerPlayerId,
      defenderPlayerId: defender.ownerPlayerId,
      turn: context.turn,
    );
    final retreat = CombatRetreatResolver.destinationIfAvailable(
      canCounter: combatants.defender.effective.attack > 0,
      attacker: attacker,
      defender: defender,
      units: effects.units,
      tileAt: context.mapTiles?.tileAt,
    );
    final outcome = CombatResolver.resolve(
      attacker: combatants.attacker,
      defender: combatants.defender,
      rng: CombatRng.fromTurn(
        turn: context.turn,
        attackerId: attacker.id,
        defenderId: defender.id,
      ),
      attackDistance: attackDistance,
      ruleset: context.ruleset.combat,
      defenderCanRetreat: retreat != null,
    );
    return (outcome: outcome, retreat: retreat);
  }

  static void _recordOpeningEvents({
    required GameUnit attacker,
    required GameUnit defender,
    required CombatOutcome outcome,
    required HexCoordinate? retreat,
    required TurnCombatEffects effects,
  }) {
    effects.events.addAll([
      UnitAttackedEvent(
        attackerUnitId: attacker.id,
        attackerOwnerPlayerId: attacker.ownerPlayerId,
        defenderUnitId: defender.id,
        defenderOwnerPlayerId: defender.ownerPlayerId,
      ),
      CombatResolvedEvent(
        attackerUnitId: attacker.id,
        defenderUnitId: defender.id,
        outcome: outcome,
      ),
    ]);
    if (!outcome.defenderRetreated || retreat == null) return;
    effects.events.add(
      UnitRetreatedEvent(
        unitId: defender.id,
        ownerPlayerId: defender.ownerPlayerId,
        fromCol: defender.col,
        fromRow: defender.row,
        toCol: retreat.col,
        toRow: retreat.row,
      ),
    );
  }

  static void _applyOutcome({
    required GameUnit attacker,
    required GameUnit defender,
    required int attackerIndex,
    required int defenderIndex,
    required _UnitCombatants combatants,
    required CombatOutcome outcome,
    required HexCoordinate? retreat,
    required TurnCombatEffects effects,
  }) {
    _applyAttackerOutcome(
      unit: attacker,
      opponent: defender,
      index: attackerIndex,
      maxHitPoints: combatants.attacker.maxHp,
      outcome: outcome,
      effects: effects,
    );
    _applyDefenderOutcome(
      unit: defender,
      opponent: attacker,
      index: defenderIndex,
      maxHitPoints: combatants.defender.maxHp,
      outcome: outcome,
      retreat: retreat,
      effects: effects,
    );
    final removals = <int>[
      if (outcome.attackerKilled) attackerIndex,
      if (outcome.defenderKilled) defenderIndex,
    ]..sort((a, b) => b.compareTo(a));
    for (final index in removals) {
      effects.units.removeAt(index);
    }
  }

  static void _applyAttackerOutcome({
    required GameUnit unit,
    required GameUnit opponent,
    required int index,
    required int maxHitPoints,
    required CombatOutcome outcome,
    required TurnCombatEffects effects,
  }) {
    if (outcome.attackerKilled) {
      effects.dropUnitArtifacts(unit);
      effects.events.add(
        UnitKilledEvent(
          unitId: unit.id,
          ownerPlayerId: unit.ownerPlayerId,
          attackerUnitId: opponent.id,
        ),
      );
      return;
    }
    final experience = UnitVeterancyRules.experienceAwardForCombat(
      unit: unit,
      survived: true,
      defeatedEnemy: outcome.defenderKilled,
    );
    final updated = effects.withCombatState(
      unit,
      hitPoints: outcome.attackerHpAfter,
      maxHitPoints: maxHitPoints,
      movementPoints: 0,
      experienceAward: experience,
    );
    effects.units[index] = updated;
    final event = effects.experienceEvent(
      before: unit,
      after: updated,
      amount: experience,
    );
    if (event != null) effects.events.add(event);
  }

  static void _applyDefenderOutcome({
    required GameUnit unit,
    required GameUnit opponent,
    required int index,
    required int maxHitPoints,
    required CombatOutcome outcome,
    required HexCoordinate? retreat,
    required TurnCombatEffects effects,
  }) {
    if (outcome.defenderKilled) {
      effects.dropUnitArtifacts(unit);
      effects.events.add(
        UnitKilledEvent(
          unitId: unit.id,
          ownerPlayerId: unit.ownerPlayerId,
          attackerUnitId: opponent.id,
        ),
      );
      return;
    }
    final experience = UnitVeterancyRules.experienceAwardForCombat(
      unit: unit,
      survived: true,
      defeatedEnemy: outcome.attackerKilled,
    );
    final updated = effects.withCombatState(
      unit,
      hitPoints: outcome.defenderHpAfter,
      maxHitPoints: maxHitPoints,
      retreatDestination: outcome.defenderRetreated ? retreat : null,
      experienceAward: experience,
    );
    effects.units[index] = updated;
    final event = effects.experienceEvent(
      before: unit,
      after: updated,
      amount: experience,
    );
    if (event != null) effects.events.add(event);
  }

  static GameCity? _cityAt(TurnCombatEffects effects, int col, int row) {
    final index = effects.cityIndexAt(col, row);
    return index == null ? null : effects.cities[index];
  }
}
