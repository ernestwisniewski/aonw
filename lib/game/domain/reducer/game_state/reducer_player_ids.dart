import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

Set<String> knownPlayerIds(GameState state) => {
  ...state.playerColors.keys,
  ...state.playerCountries.keys,
  ...state.playerGold.keys,
  ...state.playerWarWeariness.keys,
  ...state.playerStabilityNet.keys,
  ...state.fogOfWar.playerIds,
  ...state.submittedPlayerIds,
  ...state.wonderRegistry.completedBy.values,
  ...state.dominationHoldTurnsByPlayerId.keys,
  ...state.culturalVictoryHoldTurnsByPlayerId.keys,
  if (state.activePlayerId.isNotEmpty) state.activePlayerId,
  for (final unit in state.units) unit.ownerPlayerId,
  for (final city in state.cities) city.ownerPlayerId,
  for (final city in state.cities) ?city.foundingOwnerPlayerId,
  for (final relation in state.diplomacy.relations.values) relation.playerAId,
  for (final relation in state.diplomacy.relations.values) relation.playerBId,
}..removeWhere((playerId) => playerId.isEmpty);

GameState withDiscoveredDiplomaticContacts(
  GameState state, {
  Iterable<String>? playerIds,
}) {
  final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
    diplomacy: state.diplomacy,
    fogOfWar: state.fogOfWar,
    units: state.units,
    cities: state.cities,
    playerIds: playerIds ?? knownPlayerIds(state),
  );
  if (identical(diplomacy, state.diplomacy) || diplomacy == state.diplomacy) {
    return state;
  }
  return state.copyWith(diplomacy: diplomacy);
}
