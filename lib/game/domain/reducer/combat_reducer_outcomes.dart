part of 'combat_reducer.dart';

abstract final class _CombatOutcomeApplier {
  static _CombatApplication applyUnitCombat({
    required GameState state,
    required GameUnit attacker,
    required GameUnit defender,
    required CombatOutcome outcome,
    required CombatStats attackerEffective,
    required CombatStats defenderEffective,
    required HexCoordinate? retreatDestination,
  }) {
    var units = <GameUnit>[
      for (final unit in state.units)
        if (unit.id != attacker.id && unit.id != defender.id) unit,
    ];

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

    GameUnit? updatedAttacker;
    if (!outcome.attackerKilled) {
      final attackerWithCombatState = attacker.copyWith(
        movementPoints: 0,
        hitPoints: UnitCombatHealth.clampHp(
          outcome.attackerHpAfter,
          effectiveStats: attackerEffective,
        ),
      );
      updatedAttacker = UnitVeterancyRules.addExperience(
        attackerWithCombatState,
        attackerExperience,
      );
      units = CombatReducer._insertAtOriginalPosition(
        units,
        state.units,
        updatedAttacker,
      );
    }

    GameUnit? updatedDefender;
    if (!outcome.defenderKilled) {
      final defenderRetreatDestination = outcome.defenderRetreated
          ? retreatDestination
          : null;
      final defenderWithCombatState = defender.copyWith(
        col: defenderRetreatDestination?.col,
        row: defenderRetreatDestination?.row,
        movementPoints: defenderRetreatDestination == null ? null : 0,
        hitPoints: UnitCombatHealth.clampHp(
          outcome.defenderHpAfter,
          effectiveStats: defenderEffective,
        ),
      );
      updatedDefender = UnitVeterancyRules.addExperience(
        defenderWithCombatState,
        defenderExperience,
      );
      units = CombatReducer._insertAtOriginalPosition(
        units,
        state.units,
        updatedDefender,
      );
    }

    return (
      units: units,
      cities: state.cities,
      updatedAttacker: updatedAttacker,
      updatedDefender: updatedDefender,
      attackerExperience: attackerExperience,
      defenderExperience: defenderExperience,
    );
  }

  static _CityCombatApplication applyCityCombat({
    required GameState state,
    required GameUnit attacker,
    required GameCity city,
    required CombatOutcome outcome,
    required CombatStats attackerEffective,
    required CombatStats cityEffective,
    required CityConquestAction cityConquestAction,
  }) {
    var units = <GameUnit>[
      for (final unit in state.units)
        if (unit.id != attacker.id) unit,
    ];

    final attackerExperience = UnitVeterancyRules.experienceAwardForCombat(
      unit: attacker,
      survived: !outcome.attackerKilled,
      defeatedEnemy: outcome.defenderKilled,
    );

    GameUnit? updatedAttacker;
    if (!outcome.attackerKilled) {
      final attackerWithCombatState = attacker.copyWith(
        movementPoints: 0,
        hitPoints: UnitCombatHealth.clampHp(
          outcome.attackerHpAfter,
          effectiveStats: attackerEffective,
        ),
      );
      updatedAttacker = UnitVeterancyRules.addExperience(
        attackerWithCombatState,
        attackerExperience,
      );
      units = CombatReducer._insertAtOriginalPosition(
        units,
        state.units,
        updatedAttacker,
      );
    }

    GameCity? updatedCity;
    GameCity? capturedCity;
    GameCity? destroyedCity;
    final cities = <GameCity>[];
    for (final current in state.cities) {
      if (current.id != city.id) {
        cities.add(current);
        continue;
      }

      if (outcome.defenderKilled &&
          cityConquestAction == CityConquestAction.destroy) {
        destroyedCity = city;
        continue;
      }

      if (outcome.defenderKilled) {
        capturedCity = city.copyWith(
          ownerPlayerId: attacker.ownerPlayerId,
          hitPoints: CityCombatHealth.capturedHp(effectiveStats: cityEffective),
        );
        cities.add(capturedCity);
        continue;
      }

      updatedCity = city.copyWithHitPoints(
        CityCombatHealth.storedHp(
          outcome.defenderHpAfter,
          effectiveStats: cityEffective,
        ),
      );
      cities.add(updatedCity);
    }

    return (
      units: units,
      cities: cities,
      updatedAttacker: updatedAttacker,
      attackerExperience: attackerExperience,
      updatedCity: updatedCity,
      capturedCity: capturedCity,
      destroyedCity: destroyedCity,
    );
  }
}

abstract final class _CombatArtifactPolicy {
  static List<WorldArtifact> afterUnitCombat(
    List<WorldArtifact> artifacts, {
    required GameUnit attacker,
    required GameUnit defender,
    required CombatOutcome outcome,
  }) {
    var next = artifacts;
    if (outcome.attackerKilled) {
      next = _dropUnitArtifacts(next, attacker);
    }
    if (outcome.defenderKilled) {
      next = _dropUnitArtifacts(next, defender);
    }
    return next;
  }

  static List<WorldArtifact> afterCityCombat(
    List<WorldArtifact> artifacts, {
    required GameUnit attacker,
    required GameCity city,
    required CombatOutcome outcome,
    required CityConquestAction cityConquestAction,
  }) {
    var next = artifacts;
    if (outcome.attackerKilled) {
      next = _dropUnitArtifacts(next, attacker);
    }
    if (outcome.defenderKilled &&
        cityConquestAction == CityConquestAction.destroy) {
      next = _dropStoredArtifactsFromCity(next, city);
    }
    return next;
  }

  static List<WorldArtifact> _dropUnitArtifacts(
    List<WorldArtifact> artifacts,
    GameUnit unit,
  ) {
    final carriedId = unit.carriedArtifactId;
    final excavatingId = unit.excavatingArtifactId;
    if (carriedId == null && excavatingId == null) return artifacts;
    return [
      for (final artifact in artifacts)
        if (artifact.id == carriedId || artifact.id == excavatingId)
          artifact.copyWith(
            location: WorldArtifactLocation.map(col: unit.col, row: unit.row),
          )
        else
          artifact,
    ];
  }

  static List<WorldArtifact> _dropStoredArtifactsFromCity(
    List<WorldArtifact> artifacts,
    GameCity city,
  ) {
    return [
      for (final artifact in artifacts)
        if (artifact.location.isStored && artifact.location.cityId == city.id)
          artifact.copyWith(
            location: WorldArtifactLocation.map(
              col: city.center.col,
              row: city.center.row,
            ),
          )
        else
          artifact,
    ];
  }
}
