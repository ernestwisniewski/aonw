import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';

/// Recovers city hit points from persistence-free domain collections.
abstract final class CityHitPointRecoveryProcessor {
  static const int hitPointsPerTurn = 1;

  static List<GameCity> recoverForPlayer({
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameEvent> events,
    required CombatRuleset combatRuleset,
    required String playerId,
  }) {
    final cityList = List<GameCity>.unmodifiable(cities);
    final attackedCityIds = _attackedCityIdsFromEvents(
      events: events,
      cities: cityList,
    );
    return List<GameCity>.unmodifiable(
      _recover(
        cities: cityList,
        artifacts: artifacts,
        attackedCityIds: attackedCityIds,
        combatRuleset: combatRuleset,
        playerId: playerId,
      ),
    );
  }

  static Set<String> _attackedCityIdsFromEvents({
    required Iterable<GameEvent> events,
    required Iterable<GameCity> cities,
  }) {
    final cityIds = {for (final city in cities) city.id};
    return {
      for (final event in events.whereType<CombatResolvedEvent>())
        if (cityIds.contains(event.defenderUnitId)) event.defenderUnitId,
    };
  }

  static Iterable<GameCity> _recover({
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required Set<String> attackedCityIds,
    required CombatRuleset combatRuleset,
    required String playerId,
  }) sync* {
    for (final city in cities) {
      if (city.ownerPlayerId != playerId || attackedCityIds.contains(city.id)) {
        yield city;
        continue;
      }

      final effectiveStats = combatRuleset.cityBaseStats.add(
        WorldArtifactBonuses.cityCombatStatsFor(
          cityId: city.id,
          artifacts: artifacts,
        ),
      );
      final currentHp = CityCombatHealth.currentHp(
        city,
        effectiveStats: effectiveStats,
      );
      if (currentHp >= effectiveStats.hp) {
        yield city;
        continue;
      }

      final recoveredHp = currentHp + hitPointsPerTurn;
      yield city.copyWithHitPoints(
        CityCombatHealth.storedHp(recoveredHp, effectiveStats: effectiveStats),
      );
    }
  }
}
