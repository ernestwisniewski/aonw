part of 'hud_combat_preview_factory.dart';

final class _CombatPreviewResolver {
  const _CombatPreviewResolver(this.request);

  final _PreviewRequest request;

  HudCombatPreview? resolve(_PreviewTarget target) {
    final attacker = _attackerCombatant(target);
    if (attacker == null) return null;
    final defender = _defenderCombatant(target);
    final outcome = _resolveOutcome(
      target: target,
      attacker: attacker,
      defender: defender,
    );
    return _buildPreview(
      target: target,
      attacker: attacker,
      defender: defender,
      outcome: outcome,
    );
  }

  _PreviewCombatant? _attackerCombatant(_PreviewTarget target) {
    final modifiers = CombatModifierCollector.forAttacker(
      unit: request.attacker,
      tile: request.attackerTile,
      research: request.state.research.forPlayer(
        request.attacker.ownerPlayerId,
      ),
      defender: target.defender,
      defenderTile: target.tile,
      ruleset: request.combatRuleset,
      technologyRuleset: request.technologyRuleset,
    );
    final effectiveStats = request.attackerBase.applyAll(modifiers);
    if (effectiveStats.attack <= 0 || target.distance > effectiveStats.range) {
      return null;
    }
    return _PreviewCombatant(
      combatant: Combatant(
        unitId: request.attacker.id,
        ownerPlayerId: request.attacker.ownerPlayerId,
        baseStats: request.attackerBase,
        modifiers: modifiers,
        currentHp: UnitCombatHealth.currentHp(
          request.attacker,
          effectiveStats: effectiveStats,
        ),
      ),
      effectiveStats: effectiveStats,
    );
  }

  _PreviewCombatant _defenderCombatant(_PreviewTarget target) {
    final unit = target.defender;
    final modifiers = unit == null
        ? const <CombatModifier>[]
        : CombatModifierCollector.forDefender(
            unit: unit,
            tile: target.tile,
            defendedCity: request.state.cityAt(unit.col, unit.row),
            research: request.state.research.forPlayer(unit.ownerPlayerId),
            attacker: request.attacker,
            ruleset: request.combatRuleset,
            technologyRuleset: request.technologyRuleset,
          );
    final baseStats = unit == null
        ? _cityBaseStats(target.city!)
        : UnitCombatStats.derive(unit, ruleset: request.combatRuleset);
    final effectiveStats = baseStats.applyAll(modifiers);
    return _PreviewCombatant(
      combatant: Combatant(
        unitId: target.id,
        ownerPlayerId: target.ownerPlayerId,
        baseStats: baseStats,
        modifiers: modifiers,
        currentHp: target.currentHp(effectiveStats),
      ),
      effectiveStats: effectiveStats,
    );
  }

  CombatStats _cityBaseStats(GameCity city) {
    return request.combatRuleset.cityBaseStats.add(
      WorldArtifactBonuses.cityCombatStatsFor(
        cityId: city.id,
        artifacts: request.state.artifacts,
      ),
    );
  }

  CombatOutcome _resolveOutcome({
    required _PreviewTarget target,
    required _PreviewCombatant attacker,
    required _PreviewCombatant defender,
  }) {
    return CombatResolver.resolve(
      attacker: attacker.combatant,
      defender: defender.combatant,
      ruleset: request.combatRuleset,
      rng: CombatRng.fromTurn(
        turn: request.turn,
        attackerId: request.attacker.id,
        defenderId: target.id,
      ),
      attackDistance: target.distance,
      defenderCanRetreat: _canRetreat(target, defender.effectiveStats),
    );
  }

  bool _canRetreat(_PreviewTarget target, CombatStats defenderStats) {
    final defender = target.defender;
    if (defender == null || defenderStats.attack <= 0) return false;
    return CombatRetreatResolver.destination(
          attacker: request.attacker,
          defender: defender,
          units: request.state.units,
          tileAt: request.mapData.tileAt,
        ) !=
        null;
  }

  HudCombatPreview _buildPreview({
    required _PreviewTarget target,
    required _PreviewCombatant attacker,
    required _PreviewCombatant defender,
    required CombatOutcome outcome,
  }) {
    final defenderUnit = target.defender;
    return HudCombatPreview(
      attackerUnitId: request.attacker.id,
      defenderUnitId: target.id,
      attackerOwnerPlayerId: request.attacker.ownerPlayerId,
      defenderOwnerPlayerId: target.ownerPlayerId,
      attackerCountry: request.state.countryForPlayer(
        request.attacker.ownerPlayerId,
      ),
      defenderCountry: request.state.countryForPlayer(target.ownerPlayerId),
      attackerUnitType: request.attacker.type,
      defenderUnitType: defenderUnit?.type,
      defenderCity: target.city,
      attackerName: request.attacker.name,
      defenderName: target.name,
      attackerTerrains: List.unmodifiable(request.attackerTile.terrains),
      defenderTerrains: List.unmodifiable(target.tile.terrains),
      attackerModifiers: List.unmodifiable(attacker.combatant.modifiers),
      defenderModifiers: List.unmodifiable(defender.combatant.modifiers),
      attackerHpBefore: attacker.combatant.currentHp,
      defenderHpBefore: defender.combatant.currentHp,
      attackerMaxHp: attacker.combatant.maxHp,
      defenderMaxHp: defender.combatant.maxHp,
      attackerHpAfter: outcome.attackerHpAfter,
      defenderHpAfter: outcome.defenderHpAfter,
      attackerAttack: attacker.effectiveStats.attack,
      attackerDefense: attacker.effectiveStats.defense,
      defenderAttack: defender.effectiveStats.attack,
      defenderDefense: defender.effectiveStats.defense,
      defenderRange: defender.effectiveStats.range,
      attackDamage: _damageFromAttack(outcome),
      retaliationDamage: _damageFromRetaliation(outcome),
      attackerKilled: outcome.attackerKilled,
      defenderKilled: outcome.defenderKilled,
      defenderRetreated: outcome.defenderRetreated,
      targetIsCity: target.isCity,
      distance: target.distance,
      range: attacker.effectiveStats.range,
    );
  }

  static int _damageFromAttack(CombatOutcome outcome) {
    for (final step in outcome.steps) {
      if (step is AttackStep) return step.damage;
    }
    return 0;
  }

  static int _damageFromRetaliation(CombatOutcome outcome) {
    for (final step in outcome.steps) {
      if (step is RetaliationStep) return step.damage;
    }
    return 0;
  }
}

final class _PreviewCombatant {
  const _PreviewCombatant({
    required this.combatant,
    required this.effectiveStats,
  });

  final Combatant combatant;
  final CombatStats effectiveStats;
}
