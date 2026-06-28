part of 'combat_reducer.dart';

typedef _AttackerCombatSetup = ({
  GameUnit attacker,
  List<CombatModifier> attackerModifiers,
  CombatStats attackerBase,
  CombatStats attackerEffective,
});

abstract final class _CombatSetupFactory {
  static _AttackSetup? unitAttackSetup(
    GameState state,
    AttackHexCommand command,
    MapData mapData, {
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
    required GameCommandContext context,
    bool allowExistingTargetOverride = false,
  }) {
    final attackerSetup = _attackerCombatSetup(
      state,
      command,
      mapData,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
      allowExistingTargetOverride: allowExistingTargetOverride,
    );
    if (attackerSetup == null) return null;

    final defenderTile = mapData.tileAt(
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
    if (!_targetIsInRange(
      attackerSetup.attacker,
      attackerSetup.attackerEffective,
      HexCoordinate(col: defender.col, row: defender.row),
    )) {
      return null;
    }

    return (
      attacker: attackerSetup.attacker,
      defender: defender,
      defenderTile: defenderTile,
      attackerModifiers: attackerSetup.attackerModifiers,
      attackerBase: attackerSetup.attackerBase,
      attackerEffective: attackerSetup.attackerEffective,
    );
  }

  static _CityAttackSetup? cityAttackSetup(
    GameState state,
    AttackHexCommand command,
    MapData mapData, {
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
    required GameCommandContext context,
    bool allowExistingTargetOverride = false,
  }) {
    final attackerSetup = _attackerCombatSetup(
      state,
      command,
      mapData,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
      allowExistingTargetOverride: allowExistingTargetOverride,
    );
    if (attackerSetup == null) return null;

    final cityTile = mapData.tileAt(command.defenderCol, command.defenderRow);
    if (cityTile == null) return null;
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

    return (
      attacker: attackerSetup.attacker,
      city: city,
      cityTile: cityTile,
      attackerModifiers: attackerSetup.attackerModifiers,
      attackerBase: attackerSetup.attackerBase,
      attackerEffective: attackerSetup.attackerEffective,
      cityBase: cityBase,
      cityEffective: cityEffective,
    );
  }

  static _DefenseSetup defenseSetup({
    required GameState state,
    required MapData mapData,
    required GameUnit attacker,
    required GameUnit defender,
    required TileData defenderTile,
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    final defendedCity = state.cityAt(defender.col, defender.row);
    final defenderModifiers = CombatModifierCollector.forDefender(
      unit: defender,
      tile: defenderTile,
      defendedCity: defendedCity,
      research: state.research.forPlayer(defender.ownerPlayerId),
      ruleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    final defenderBase = UnitCombatStats.derive(
      defender,
      ruleset: combatRuleset,
    );
    final defenderEffective = defenderBase.applyAll(defenderModifiers);
    final retreatDestination = defenderEffective.attack > 0
        ? CombatRetreatResolver.destination(
            attacker: attacker,
            defender: defender,
            units: state.units,
            tileAt: mapData.tileAt,
          )
        : null;

    return (
      defendedCity: defendedCity,
      defenderModifiers: defenderModifiers,
      defenderBase: defenderBase,
      defenderEffective: defenderEffective,
      retreatDestination: retreatDestination,
    );
  }

  static _AttackerCombatSetup? _attackerCombatSetup(
    GameState state,
    AttackHexCommand command,
    MapData mapData, {
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
    required GameCommandContext context,
    required bool allowExistingTargetOverride,
  }) {
    final attacker = state.unitById(command.attackerUnitId);
    if (attacker == null || !_canUseAttacker(state, attacker, context)) {
      return null;
    }
    if (!_pendingAttackAllowsCommand(
      state: state,
      command: command,
      attacker: attacker,
      allowExistingTargetOverride: allowExistingTargetOverride,
    )) {
      return null;
    }

    final attackerTile = mapData.tileAt(attacker.col, attacker.row);
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
      attackerModifiers: attackerModifiers,
      attackerBase: attackerBase,
      attackerEffective: attackerEffective,
    );
  }

  static bool _canUseAttacker(
    GameState state,
    GameUnit attacker,
    GameCommandContext context,
  ) {
    return context.canControlUnit(state, attacker) &&
        !attacker.isWorking &&
        attacker.movementPoints > 0;
  }

  static bool _pendingAttackAllowsCommand({
    required GameState state,
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
    GameState state,
    GameUnit attacker,
    GameUnit defender,
  ) {
    return defender.id != attacker.id &&
        _canAttackTargetOwner(state, attacker, defender.ownerPlayerId);
  }

  static bool _canAttackTargetOwner(
    GameState state,
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
    GameState state,
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
    final distance = HexDistance.between(
      HexCoordinate(col: attacker.col, row: attacker.row),
      target,
    );
    return distance <= attackerEffective.range;
  }

  static bool _cityTargetHasOtherUnit(
    GameState state,
    AttackHexCommand command,
    GameUnit attacker,
  ) {
    final targetOccupant = state.unitAt(
      command.defenderCol,
      command.defenderRow,
    );
    return targetOccupant != null && targetOccupant.id != attacker.id;
  }

  static GameCity? _attackableCityAt(
    GameState state,
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
