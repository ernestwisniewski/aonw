part of 'combat_reducer.dart';

abstract final class _CombatEventFactory {
  static List<GameEvent> unitCombatEvents({
    required GameUnit attacker,
    required GameUnit defender,
    required CombatOutcome outcome,
    required HexCoordinate? retreatDestination,
    required _CombatApplication application,
  }) {
    final updatedAttacker = application.updatedAttacker;
    final updatedDefender = application.updatedDefender;

    return [
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
      if (outcome.defenderRetreated && retreatDestination != null)
        UnitRetreatedEvent(
          unitId: defender.id,
          ownerPlayerId: defender.ownerPlayerId,
          fromCol: defender.col,
          fromRow: defender.row,
          toCol: retreatDestination.col,
          toRow: retreatDestination.row,
        ),
      if (updatedAttacker != null)
        ?_experienceEvent(
          before: attacker,
          after: updatedAttacker,
          amount: application.attackerExperience,
        ),
      if (updatedDefender != null)
        ?_experienceEvent(
          before: defender,
          after: updatedDefender,
          amount: application.defenderExperience,
        ),
      if (outcome.defenderKilled)
        UnitKilledEvent(
          unitId: defender.id,
          ownerPlayerId: defender.ownerPlayerId,
          attackerUnitId: attacker.id,
        ),
      if (outcome.attackerKilled)
        UnitKilledEvent(
          unitId: attacker.id,
          ownerPlayerId: attacker.ownerPlayerId,
          attackerUnitId: defender.id,
        ),
    ];
  }

  static List<GameEvent> cityCombatEvents({
    required GameUnit attacker,
    required GameCity city,
    required CombatOutcome outcome,
    required _CityCombatApplication application,
    Iterable<DiplomaticScoreEntry> warmongerEntries = const [],
  }) {
    final updatedAttacker = application.updatedAttacker;
    final capturedCity = application.capturedCity;
    final destroyedCity = application.destroyedCity;

    return [
      CombatResolvedEvent(
        attackerUnitId: attacker.id,
        defenderUnitId: city.id,
        outcome: outcome,
      ),
      if (updatedAttacker != null)
        ?_experienceEvent(
          before: attacker,
          after: updatedAttacker,
          amount: application.attackerExperience,
        ),
      if (outcome.attackerKilled)
        UnitKilledEvent(
          unitId: attacker.id,
          ownerPlayerId: attacker.ownerPlayerId,
          attackerUnitId: city.id,
        ),
      if (capturedCity != null)
        CityCapturedEvent(
          cityId: capturedCity.id,
          previousOwnerPlayerId: city.ownerPlayerId,
          newOwnerPlayerId: attacker.ownerPlayerId,
        ),
      if (destroyedCity != null)
        CityDestroyedEvent(
          cityId: destroyedCity.id,
          previousOwnerPlayerId: city.ownerPlayerId,
          attackerOwnerPlayerId: attacker.ownerPlayerId,
        ),
      ...DiplomaticWarEffects.warmongerScoreEvents(warmongerEntries),
    ];
  }

  static UnitGainedExperienceEvent? _experienceEvent({
    required GameUnit before,
    required GameUnit after,
    required int amount,
  }) {
    if (amount <= 0) return null;
    final beforeRank = UnitVeterancyRules.rankFor(before);
    final afterRank = UnitVeterancyRules.rankFor(after);
    return UnitGainedExperienceEvent(
      unitId: after.id,
      ownerPlayerId: after.ownerPlayerId,
      amount: amount,
      totalExperience: after.experiencePoints,
      rank: afterRank,
      promoted: beforeRank != afterRank,
    );
  }
}
