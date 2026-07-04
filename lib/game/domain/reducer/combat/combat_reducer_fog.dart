part of 'combat_reducer.dart';

abstract final class _CombatFogPolicy {
  static FogOfWarState recomputeAfterCombat({
    required FogOfWarState current,
    required MapData mapData,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    required FogOfWarService fogOfWarService,
    required String attackerOwnerPlayerId,
    required String defenderOwnerPlayerId,
  }) {
    return fogOfWarService.recompute(
      current: current,
      mapData: mapData,
      playerIds: {
        attackerOwnerPlayerId,
        defenderOwnerPlayerId,
      }.where((playerId) => playerId.isNotEmpty),
      units: units,
      cities: cities,
    );
  }
}
