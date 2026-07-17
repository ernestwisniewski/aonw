import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact_bonuses.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/combat/city_combat_health.dart';
import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/game/domain/combat/combat_distance.dart';
import 'package:aonw_core/game/domain/combat/combat_modifier_collector.dart';
import 'package:aonw_core/game/domain/combat/combat_outcome.dart';
import 'package:aonw_core/game/domain/combat/combat_resolver.dart';
import 'package:aonw_core/game/domain/combat/combat_rng.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/combat/combatant.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_health.dart';
import 'package:aonw_core/game/domain/combat/unit_combat_stats.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_warmonger_reputation.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_context.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_effects.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_veterancy.dart';

typedef _PreparedCityAttack = ({
  Combatant attacker,
  Combatant city,
  CombatStats cityStats,
  int distance,
});

abstract final class CityTurnCombatResolver {
  static void resolve({
    required IntendedAttack intent,
    required int attackerIndex,
    required TurnCombatContext context,
    required TurnCombatEffects effects,
  }) {
    final cityIndex = effects.cityIndexAt(
      intent.defenderCol,
      intent.defenderRow,
    );
    if (cityIndex == null) return;
    final attacker = effects.units[attackerIndex];
    final city = effects.cities[cityIndex];
    if (!_canAttack(attacker, city, effects)) return;
    final prepared = _prepareAttack(
      attacker: attacker,
      city: city,
      context: context,
      effects: effects,
    );
    if (prepared == null) return;

    final scoreEntries = _registerDiplomaticEffects(
      attacker: attacker,
      city: city,
      context: context,
      effects: effects,
    );
    final outcome = _resolveOutcome(
      attacker: attacker,
      city: city,
      prepared: prepared,
      context: context,
    );
    _recordOpeningEvents(
      attacker: attacker,
      city: city,
      outcome: outcome,
      scoreEntries: scoreEntries,
      effects: effects,
    );
    _applyAttackerOutcome(
      attacker: attacker,
      city: city,
      attackerIndex: attackerIndex,
      attackerMaxHp: prepared.attacker.maxHp,
      outcome: outcome,
      effects: effects,
    );
    _applyCityOutcome(
      intent: intent,
      attacker: attacker,
      city: city,
      cityIndex: cityIndex,
      cityStats: prepared.cityStats,
      outcome: outcome,
      effects: effects,
    );
  }

  static bool _canAttack(
    GameUnit attacker,
    GameCity city,
    TurnCombatEffects effects,
  ) {
    if (city.ownerPlayerId == attacker.ownerPlayerId) return false;
    return !effects.isProtectedRelation(
      attacker.ownerPlayerId,
      city.ownerPlayerId,
    );
  }

  static _PreparedCityAttack? _prepareAttack({
    required GameUnit attacker,
    required GameCity city,
    required TurnCombatContext context,
    required TurnCombatEffects effects,
  }) {
    final attackerTile = context.mapTiles?.tileAt(attacker.col, attacker.row);
    if (attackerTile == null ||
        context.mapTiles?.tileAt(city.center.col, city.center.row) == null) {
      return null;
    }
    final modifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: context.researchForPlayer(attacker.ownerPlayerId),
      ruleset: context.ruleset.combat,
      technologyRuleset: context.ruleset.technology,
    );
    final attackerStats = UnitCombatStats.derive(
      attacker,
      ruleset: context.ruleset.combat,
    );
    final attackerEffective = attackerStats.applyAll(modifiers);
    final distance = CombatDistance.fromUnitToHex(attacker, city.center);
    if (attackerEffective.attack <= 0 || distance > attackerEffective.range) {
      return null;
    }
    final cityStats = context.ruleset.combat.cityBaseStats.add(
      WorldArtifactBonuses.cityCombatStatsFor(
        cityId: city.id,
        artifacts: effects.initialArtifacts,
      ),
    );
    if (cityStats.hp <= 0) return null;
    return (
      attacker: Combatant(
        unitId: attacker.id,
        ownerPlayerId: attacker.ownerPlayerId,
        baseStats: attackerStats,
        modifiers: modifiers,
        currentHp: UnitCombatHealth.currentHp(
          attacker,
          effectiveStats: attackerEffective,
        ),
      ),
      city: Combatant(
        unitId: city.id,
        ownerPlayerId: city.ownerPlayerId,
        baseStats: cityStats,
        currentHp: CityCombatHealth.currentHp(city, effectiveStats: cityStats),
      ),
      cityStats: cityStats,
      distance: distance,
    );
  }

  static List<DiplomaticScoreEntry> _registerDiplomaticEffects({
    required GameUnit attacker,
    required GameCity city,
    required TurnCombatContext context,
    required TurnCombatEffects effects,
  }) {
    final afterAttack = effects.diplomacy.registerCityAttack(
      attackerPlayerId: attacker.ownerPlayerId,
      defenderPlayerId: city.ownerPlayerId,
      turn: context.turn,
    );
    final reputation = DiplomaticWarmongerReputation.apply(
      diplomacy: afterAttack,
      aggressorPlayerId: attacker.ownerPlayerId,
      victimPlayerId: city.ownerPlayerId,
      action: DiplomaticWarmongerAction.cityAttack,
      turn: context.turn,
      sourceId: 'city_attack.${context.turn}.${attacker.id}',
    );
    effects
      ..diplomacy = reputation.diplomacy
      ..removeTradeAgreementsBetween(
        attacker.ownerPlayerId,
        city.ownerPlayerId,
      );
    return reputation.entries;
  }

  static CombatOutcome _resolveOutcome({
    required GameUnit attacker,
    required GameCity city,
    required _PreparedCityAttack prepared,
    required TurnCombatContext context,
  }) {
    return CombatResolver.resolve(
      attacker: prepared.attacker,
      defender: prepared.city,
      rng: CombatRng.fromTurn(
        turn: context.turn,
        attackerId: attacker.id,
        defenderId: city.id,
      ),
      attackDistance: prepared.distance,
      ruleset: context.ruleset.combat,
    );
  }

  static void _recordOpeningEvents({
    required GameUnit attacker,
    required GameCity city,
    required CombatOutcome outcome,
    required Iterable<DiplomaticScoreEntry> scoreEntries,
    required TurnCombatEffects effects,
  }) {
    effects.events
      ..add(
        CityAttackedEvent(
          attackerUnitId: attacker.id,
          attackerOwnerPlayerId: attacker.ownerPlayerId,
          cityId: city.id,
          cityOwnerPlayerId: city.ownerPlayerId,
        ),
      )
      ..add(
        CombatResolvedEvent(
          attackerUnitId: attacker.id,
          defenderUnitId: city.id,
          outcome: outcome,
        ),
      )
      ..addAll(_scoreEvents(scoreEntries));
  }

  static Iterable<DiplomaticScoreChangedEvent> _scoreEvents(
    Iterable<DiplomaticScoreEntry> entries,
  ) sync* {
    for (final entry in entries) {
      yield DiplomaticScoreChangedEvent(
        playerAId: entry.playerAId,
        playerBId: entry.playerBId,
        delta: entry.delta,
        scoreAfter: entry.scoreAfter,
        reason: entry.reason,
        sourceId: entry.sourceId,
      );
    }
  }

  static void _applyAttackerOutcome({
    required GameUnit attacker,
    required GameCity city,
    required int attackerIndex,
    required int attackerMaxHp,
    required CombatOutcome outcome,
    required TurnCombatEffects effects,
  }) {
    if (outcome.attackerKilled) {
      effects.dropUnitArtifacts(attacker);
      effects.units.removeAt(attackerIndex);
      effects.events.add(
        UnitKilledEvent(
          unitId: attacker.id,
          ownerPlayerId: attacker.ownerPlayerId,
          attackerUnitId: city.id,
        ),
      );
      return;
    }
    final experience = UnitVeterancyRules.experienceAwardForCombat(
      unit: attacker,
      survived: true,
      defeatedEnemy: outcome.defenderKilled,
    );
    final updated = effects.withCombatState(
      attacker,
      hitPoints: outcome.attackerHpAfter,
      maxHitPoints: attackerMaxHp,
      movementPoints: 0,
      experienceAward: experience,
    );
    effects.units[attackerIndex] = updated;
    final event = effects.experienceEvent(
      before: attacker,
      after: updated,
      amount: experience,
    );
    if (event != null) effects.events.add(event);
  }

  static void _applyCityOutcome({
    required IntendedAttack intent,
    required GameUnit attacker,
    required GameCity city,
    required int cityIndex,
    required CombatStats cityStats,
    required CombatOutcome outcome,
    required TurnCombatEffects effects,
  }) {
    if (!outcome.defenderKilled) {
      effects.cities[cityIndex] = city.copyWithHitPoints(
        CityCombatHealth.storedHp(
          outcome.defenderHpAfter,
          effectiveStats: cityStats,
        ),
      );
      return;
    }
    if (intent.cityConquestAction == CityConquestAction.destroy) {
      effects.dropStoredArtifactsFromCity(city);
      effects.cities.removeAt(cityIndex);
      effects.events.add(
        CityDestroyedEvent(
          cityId: city.id,
          previousOwnerPlayerId: city.ownerPlayerId,
          attackerOwnerPlayerId: attacker.ownerPlayerId,
        ),
      );
      return;
    }
    effects.cities[cityIndex] = city.copyWith(
      ownerPlayerId: attacker.ownerPlayerId,
      hitPoints: CityCombatHealth.capturedHp(effectiveStats: cityStats),
    );
    effects.events.add(
      CityCapturedEvent(
        cityId: city.id,
        previousOwnerPlayerId: city.ownerPlayerId,
        newOwnerPlayerId: attacker.ownerPlayerId,
      ),
    );
  }
}
