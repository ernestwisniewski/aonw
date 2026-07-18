import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnEconomyPlayerCatalog {
  /// Matches the legacy persistent-state player catalog while also observing
  /// owners introduced by an earlier economy step in the same turn.
  static Set<String> knownPlayerIds({
    required TurnEconomyState state,
    required Iterable<String> basePlayerIds,
  }) {
    final playerIds = <String>{
      ...basePlayerIds,
      ...state.playerGold.keys,
      ...state.playerWarWeariness.keys,
      ...state.playerStabilityNet.keys,
      ...state.fogOfWar.playerIds,
      ...state.wonderRegistry.completedBy.values,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
      for (final city in state.cities) ?city.foundingOwnerPlayerId,
      for (final relation in state.diplomacy.relations.values)
        relation.playerAId,
      for (final relation in state.diplomacy.relations.values)
        relation.playerBId,
    }..removeWhere((playerId) => playerId.isEmpty);
    return playerIds;
  }
}
