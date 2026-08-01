part of 'combat_reducer.dart';

typedef _TargetingAttacker = ({
  GameUnit attacker,
  MapTileView attackerTile,
  CombatStats attackerBase,
  CombatStats attackerEffective,
});

/// Client-only target selection policy.
///
/// Authoritative validation and execution belong to [CombatCommandResolver].
abstract final class _CombatTargetingPolicy {
  static _AttackSetup? unitTarget(
    GameClientState state,
    AttackHexCommand command,
    MapTileLookup mapTiles, {
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
    required GameCommandContext context,
    bool allowExistingTargetOverride = false,
  }) {
    final attackerSetup = _attackerForTargeting(
      state,
      command,
      mapTiles,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
      allowExistingTargetOverride: allowExistingTargetOverride,
    );
    if (attackerSetup == null) return null;

    final defenderTile = mapTiles.tileAt(
      command.defenderCol,
      command.defenderRow,
    );
    final defender = state.unitAt(command.defenderCol, command.defenderRow);
    if (defenderTile == null || defender == null) return null;
    if (!_canAttackDefender(state, attackerSetup.attacker, defender)) {
      return null;
    }
    if (!_targetIsVisible(context, state, defender.col, defender.row)) {
      return null;
    }
    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attackerSetup.attacker,
      tile: attackerSetup.attackerTile,
      research: state.research.forPlayer(attackerSetup.attacker.ownerPlayerId),
      defender: defender,
      defenderTile: defenderTile,
      ruleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    final attackerEffective = attackerSetup.attackerBase.applyAll(
      attackerModifiers,
    );
    if (attackerEffective.attack <= 0) return null;
    if (!_targetIsInRange(
      attackerSetup.attacker,
      attackerEffective,
      HexCoordinate(col: defender.col, row: defender.row),
    )) {
      return null;
    }

    return (attacker: attackerSetup.attacker, defender: defender);
  }

  static _CityAttackSetup? cityTarget(
    GameClientState state,
    AttackHexCommand command,
    MapTileLookup mapTiles, {
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
    required GameCommandContext context,
    bool allowExistingTargetOverride = false,
  }) {
    final attackerSetup = _attackerForTargeting(
      state,
      command,
      mapTiles,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
      allowExistingTargetOverride: allowExistingTargetOverride,
    );
    if (attackerSetup == null) return null;

    if (mapTiles.tileAt(command.defenderCol, command.defenderRow) == null) {
      return null;
    }
    if (_cityTargetHasOtherUnit(state, command, attackerSetup.attacker)) {
      return null;
    }

    final city = _attackableCityAt(state, command, attackerSetup.attacker);
    if (city == null) return null;
    if (!_targetIsVisible(context, state, city.center.col, city.center.row)) {
      return null;
    }
    if (!_targetIsInRange(
      attackerSetup.attacker,
      attackerSetup.attackerEffective,
      city.center.toCoordinate(),
    )) {
      return null;
    }

    final cityBase = combatRuleset.cityBaseStats.add(
      WorldArtifactBonuses.cityCombatStatsFor(
        cityId: city.id,
        artifacts: state.artifacts,
      ),
    );
    final cityEffective = cityBase;
    if (cityEffective.hp <= 0) return null;

    return (attacker: attackerSetup.attacker, city: city);
  }

  static _TargetingAttacker? _attackerForTargeting(
    GameClientState state,
    AttackHexCommand command,
    MapTileLookup mapTiles, {
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
    required GameCommandContext context,
    required bool allowExistingTargetOverride,
  }) {
    final attacker = state.unitById(command.attackerUnitId);
    if (attacker == null || !_canUseAttacker(state, attacker, context)) {
      return null;
    }
    if (!pendingAllowsCommand(
      state: state,
      command: command,
      attacker: attacker,
      allowExistingTargetOverride: allowExistingTargetOverride,
    )) {
      return null;
    }

    final attackerTile = mapTiles.tileAt(attacker.col, attacker.row);
    if (attackerTile == null) return null;

    final attackerModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: state.research.forPlayer(attacker.ownerPlayerId),
      ruleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    final attackerBase = UnitCombatStats.derive(
      attacker,
      ruleset: combatRuleset,
    );
    final attackerEffective = attackerBase.applyAll(attackerModifiers);
    if (attackerEffective.attack <= 0) return null;

    return (
      attacker: attacker,
      attackerTile: attackerTile,
      attackerBase: attackerBase,
      attackerEffective: attackerEffective,
    );
  }

  static bool _canUseAttacker(
    GameClientState state,
    GameUnit attacker,
    GameCommandContext context,
  ) {
    return context.canControlUnit(state, attacker) &&
        !attacker.isWorking &&
        attacker.movementPoints > 0;
  }

  static bool pendingAllowsCommand({
    required GameClientState state,
    required AttackHexCommand command,
    required GameUnit attacker,
    required bool allowExistingTargetOverride,
  }) {
    final pendingAction = state.pendingAction;
    return switch (pendingAction) {
      null => true,
      PendingAttackTargeting(:final attackerUnitId)
          when attackerUnitId == attacker.id =>
        allowExistingTargetOverride ||
            !pendingAction.hasDefenderTarget ||
            (pendingAction.defenderCol == command.defenderCol &&
                pendingAction.defenderRow == command.defenderRow),
      _ => false,
    };
  }

  static bool _canAttackDefender(
    GameClientState state,
    GameUnit attacker,
    GameUnit defender,
  ) {
    return defender.id != attacker.id &&
        _canAttackTargetOwner(state, attacker, defender.ownerPlayerId);
  }

  static bool _canAttackTargetOwner(
    GameClientState state,
    GameUnit attacker,
    String targetOwnerPlayerId,
  ) {
    return targetOwnerPlayerId != attacker.ownerPlayerId &&
        !CombatReducer._isProtectedRelation(
          state,
          attacker.ownerPlayerId,
          targetOwnerPlayerId,
        );
  }

  static bool _targetIsVisible(
    GameCommandContext context,
    GameClientState state,
    int col,
    int row,
  ) {
    return context.visibilityFor(state).canSeeDynamicAt(col, row);
  }

  static bool _targetIsInRange(
    GameUnit attacker,
    CombatStats attackerEffective,
    HexCoordinate target,
  ) {
    final distance = CombatDistance.fromUnitToCoordinate(attacker, target);
    return distance <= attackerEffective.range;
  }

  static bool _cityTargetHasOtherUnit(
    GameClientState state,
    AttackHexCommand command,
    GameUnit attacker,
  ) {
    return state.units.any(
      (unit) =>
          unit.id != attacker.id &&
          unit.occupies(command.defenderCol, command.defenderRow),
    );
  }

  static GameCity? _attackableCityAt(
    GameClientState state,
    AttackHexCommand command,
    GameUnit attacker,
  ) {
    final city = state.cityAt(command.defenderCol, command.defenderRow);
    if (city == null) return null;
    return _canAttackTargetOwner(state, attacker, city.ownerPlayerId)
        ? city
        : null;
  }
}
